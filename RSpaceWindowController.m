//
//  WindowController.m
//  RSpace
//
//  Created by Randy Lai on 11/14/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "RSpaceWindowController.h"
#import "Engine.h"
#import "History.h"

@implementation RSpaceWindowController{

NSCondition* cocoaCondition;
NSString* commandQueue;
unsigned long committedLength;
BOOL terminating;
History* hist;
    
}

@synthesize consoleWindow;
@synthesize progressIndicator;
@synthesize consoleScrollView;
@synthesize consoleTextView;
@synthesize interrupt;

- (void) windowDidLoad{

//    make textview size practically infinite
    [[consoleTextView textContainer]
     setContainerSize:NSMakeSize([consoleTextView textContainer].containerSize.width, FLT_MAX)];
    
//    NSColor* color = [NSColor blackColor];
//    
//    NSFont *font=[NSFont fontWithName:@"Monaco" size:12.0f];
//
//    [consoleTextView setTypingAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
//                                           font, NSFontAttributeName, color, NSForegroundColorAttributeName, nil]];
    
//    initialize variables
    cocoaCondition = [[NSCondition alloc] init];
    committedLength = 0;
    terminating = NO;
    hist = [[History alloc] init];
    
    
//    Start R Engine
    [[Engine R] setConsole: self];
    [[Engine R] activate];
    
//    start R engine in another thread with a larger stack size
    NSThread* thread=[[NSThread alloc]initWithTarget:[Engine R] selector:@selector(run_repl) object:nil];
    [thread setStackSize:16*1024*1024];
    [thread start];
}



- (void) shouldCloseDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    
    if (returnCode==NSAlertFirstButtonReturn){
        terminating = YES;
        [consoleWindow close];
    }
}

- (BOOL) windowShouldClose:(id)sender{
    
    if (terminating) return YES;
    
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NLS(@"Close")];
    [alert addButtonWithTitle:NLS(@"Cancel")];
    
    [alert setInformativeText:NLS(@"All data will be lost!")];
    [alert setMessageText:NLS(@"Do you want to close RSpace?")];
    
    [alert beginSheetModalForWindow:consoleWindow
                      modalDelegate:self
                     didEndSelector:@selector(shouldCloseDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
    
    return NO;
    
}


- (void) consoleInput: (NSString*) str
{
    if (commandQueue != nil)
        return;
    
    commandQueue = [[NSString alloc] initWithFormat:@"%@\n", str];
    
    [hist add: str];
    
    [cocoaCondition lock];
    [cocoaCondition signal];
    [cocoaCondition unlock];
}

- (NSString*) readText{
    
    [cocoaCondition lock];
    
    while(commandQueue==nil){
        [progressIndicator stopAnimation:self];
        [interrupt setHidden: YES];
        [cocoaCondition wait];
    }
    
    [progressIndicator startAnimation:self];
    [interrupt setHidden:NO];
    [cocoaCondition unlock];
    
    NSString* commandBuffer = [NSString stringWithString:commandQueue];
    
    commandQueue = nil;
    
    return commandBuffer;
}

- (NSMutableAttributedString*) formatText:(NSString*) str oType: (int) oType{
    
    NSColor* color = [NSColor blackColor];
    
    NSFont *font=[NSFont fontWithName:@"Monaco" size:12.0f];
    
    NSMutableAttributedString* astr = [[NSMutableAttributedString alloc] initWithString : str];
    
    [astr setAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                          font, NSFontAttributeName,
                          color, NSForegroundColorAttributeName,
                          nil] range: NSMakeRange(0, [str length])];
    return astr;
}

- (void) writeText: (NSString*) str {
    
    
    NSMutableAttributedString* astr = [self formatText:str oType:0];
      // Smart Scrolling
    
    BOOL scroll = (NSMaxY(consoleTextView.visibleRect) == NSMaxY(consoleTextView.bounds));
    
    [[consoleTextView textStorage] appendAttributedString: astr];
    
    committedLength = consoleTextView.string.length;
    
    if (scroll)
        [consoleTextView scrollRangeToVisible: NSMakeRange(consoleTextView.string.length, 0)];
    
}


- (void) writeInput: str {
    long textLength = [[consoleTextView textStorage] length];
    [consoleTextView setSelectedRange:NSMakeRange(committedLength, textLength-committedLength)];
    [consoleTextView delete: nil];
    [self writeText: str];
}


// Allow changes only for uncommitted text - From R.app
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	if (replacementString && affectedCharRange.location < committedLength) {
		[textView setSelectedRange:NSMakeRange([[textView textStorage] length],0)];
		[textView insertText:replacementString];
		return NO;
	}
	return YES;
}


// NSResponder
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector{
    NSLog(@"doCommandBySelector: %@\n", NSStringFromSelector(commandSelector));
    
    if(textView != consoleTextView) return NO;
    
	if (@selector(insertNewline:) == commandSelector) {
        
        long textLength = [[consoleTextView textStorage] length];
        NSRange range = NSMakeRange(committedLength, textLength-committedLength);
        NSString *command = [[consoleTextView string] substringWithRange:range];
        
        [self consoleInput:command];
        
//        [[consoleTextView undoManager] removeAllActions];
        
		return(YES);
    }

	// From R.app
    
	// ---- history browsing ----
	if (@selector(moveUp:) == commandSelector) {
        long textLength = [[textView textStorage] length];
        NSRange sr=[textView selectedRange];
        if (sr.location==committedLength || sr.location==textLength) {
            NSRange rr=NSMakeRange(committedLength, textLength-committedLength);
            NSString *text = [[textView attributedSubstringFromRange:rr] string];
            if([hist isDirty]){
                [hist updateDirt: text];
            }
            NSString *news = [hist prev];
            if (news!=nil) {
                sr.length=0;
                sr.location=committedLength;
                [textView setSelectedRange:sr];
                [textView replaceCharactersInRange:rr withString:news];
                [textView insertText:@""];
            }
			return(YES);
        }
    }
    if (@selector(moveDown:) == commandSelector) {
        long textLength = [[textView textStorage] length];
        NSRange sr=[textView selectedRange];
        if ((sr.location==committedLength || sr.location==textLength) && ![hist isDirty] ) {
            NSRange rr=NSMakeRange(committedLength, textLength-committedLength);
            NSString *news = [hist next];
            if (news==nil) news=@"";
            sr.length=0; sr.location=committedLength;
            [textView setSelectedRange:sr];
            [textView replaceCharactersInRange:rr withString:news];
            [textView insertText:@""];
			return(YES);
        }
    }
    
    
	if ([textView selectedRange].location >= committedLength &&
        (@selector(moveToBeginningOfParagraph:) == commandSelector ||
         @selector(moveToBeginningOfLine:) == commandSelector ||
         @selector(moveToLeftEndOfLine:) == commandSelector)) {
            
            [textView setSelectedRange: NSMakeRange(committedLength,0)];
            return(YES);
        }
	
	if (@selector(deleteToBeginningOfLine:) == commandSelector || @selector(deleteToBeginningOfParagraph:) == commandSelector) {
		NSRange r = [textView selectedRange];
		if (r.length)
			[textView insertText:@""];
		else {
			r.length = r.location - committedLength;
			r.location = committedLength;
			if (r.length > 0) {
				[textView setSelectedRange:r];
				[textView insertText:@""];
			}
		}
		return(YES);
	}
    
	if ([textView selectedRange].location >= committedLength &&
        (@selector(moveToBeginningOfParagraphAndModifySelection:) == commandSelector||
         @selector(moveToLeftEndOfLineAndModifySelection:) == commandSelector ||
         @selector(moveToBeginningOfLineAndModifySelection:) == commandSelector)) {
            NSRange r = [textView selectedRange];
            r.length = r.location + r.length - committedLength;
            r.location = committedLength;
            if((long)r.length<0)
                r.length=0;
            [textView setSelectedRange: r];
            return(YES);
        }
	
	if (@selector(moveWordLeft:) == commandSelector || @selector(moveLeft:) == commandSelector) {
		NSRange sr = [textView selectedRange];
		if (sr.location == committedLength) {
			if (sr.length) [textView setSelectedRange:NSMakeRange(sr.location, 0)];
			return YES;
		}
	}
	if (@selector(moveWordLeftAndModifySelection:) == commandSelector ||
        @selector(moveLeftAndModifySelection:) == commandSelector) {
		NSRange sr = [textView selectedRange];
		if (sr.location == committedLength)
            return YES;
	}
    
    return NO;
}



@end
