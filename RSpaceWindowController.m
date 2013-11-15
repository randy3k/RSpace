//
//  WindowController.m
//  RSpace
//
//  Created by Randy Lai on 11/14/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "RSpaceWindowController.h"
#import "Engine.h"

@implementation RSpaceWindowController

NSCondition* cocoaCondition;
NSString* commandQueue;
unsigned long committedLength=0;
BOOL terminating = NO;

@synthesize consoleWindow;
@synthesize progressIndicator;
@synthesize consoleTextView;
@synthesize interrupt;

- (void) windowDidLoad{
    
//    [consoleWindow setDocumentEdited: YES];

    cocoaCondition = [[NSCondition alloc] init];
    
    [[Engine R] setConsole: self];
    [[Engine R] activate];
    
    //    [NSThread detachNewThreadSelector:@selector(run_repl) toTarget:[Engine R] withObject:nil];
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


- (void) writeText: (NSArray*)array {
    
    NSString* str = [array objectAtIndex:0];
    NSColor* color = ([array count] == 2)? [array objectAtIndex:1]: nil;
    
    NSFont *font=[NSFont fontWithName:@"Monaco" size:12.0f];
    
    NSMutableAttributedString* astr = [[NSMutableAttributedString alloc] initWithString : str];
    
    [astr setAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                          font, NSFontAttributeName,
                          color, NSForegroundColorAttributeName,
                          nil] range: NSMakeRange(0, [str length])];
    
    // Smart Scrolling
    BOOL scroll = (NSMaxY(consoleTextView.visibleRect) == NSMaxY(consoleTextView.bounds));
    
    [[consoleTextView textStorage] appendAttributedString: astr];
    committedLength = consoleTextView.string.length;
    
    
    if (scroll)
        [consoleTextView scrollRangeToVisible: NSMakeRange(consoleTextView.string.length, 0)];
    
}

- (void) writeInput: (NSArray*)array{
    unsigned long textLength = [[consoleTextView textStorage] length];
    [consoleTextView setSelectedRange:NSMakeRange(committedLength, textLength-committedLength)];
    [consoleTextView delete: nil];
    [self writeText: array];
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
        
        unsigned long textLength = [[consoleTextView textStorage] length];
        NSRange range = NSMakeRange(committedLength, textLength-committedLength);
        NSString *command = [[consoleTextView string] substringWithRange:range];
        
        [self consoleInput:command];
        
        [[consoleTextView undoManager] removeAllActions];
        
		return(YES);
    }
    
	// From R.app
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
