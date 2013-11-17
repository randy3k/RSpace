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
unsigned long prompt;
BOOL terminating;
History* hist;
NSPipe* pipeHandle;
NSFileHandle* pipeReadHandle;

}

@synthesize consoleWindow;
@synthesize progressIndicator;
@synthesize consoleScrollView;
@synthesize consoleTextView;
@synthesize interrupt;

- (void) awakeFromNib{
    
    // make textview size practically infinite
    [[consoleTextView textContainer]
     setContainerSize:NSMakeSize([consoleTextView textContainer].containerSize.width, FLT_MAX)];
    
    // initialize variables
    cocoaCondition = [[NSCondition alloc] init];
    committedLength = prompt = 0;
    terminating = NO;
    hist = [[History alloc] init];
    
    
    pipeHandle = [NSPipe pipe] ;
    pipeReadHandle = [pipeHandle fileHandleForReading] ;

    dup2([[pipeHandle fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
#ifndef DEBUG
    dup2([[pipeHandle fileHandleForWriting] fileDescriptor], fileno(stderr)) ;
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePipe:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillClose:) name:NSWindowWillCloseNotification object:nil];

}

- (void) windowDidLoad{
    
    NSColor* color = [NSColor blackColor];

    NSFont *font=[NSFont fontWithName:@"Monaco" size:12.0f];

    [consoleTextView setTypingAttributes: [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, nil]];


   // Start R Engine
    [[Engine R] setWc: self];
    [[Engine R] activate];

    // do all NSEvents before running repl
    //NSEvent *event;
    //do{
    //    NSLog(@"do");
    //    event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.05] inMode:NSDefaultRunLoopMode dequeue:YES];
    //    [NSApp sendEvent: event];
    //}while(event!=nil);
    
   // start R engine in another thread with a larger stack size
    
    NSThread* thread=[[NSThread alloc]initWithTarget:[Engine R] selector:@selector(run_repl) object:nil];
    [thread setStackSize:16*1024*1024];
    [thread start];
}


- (void)handleWindowWillClose:(NSNotification*) aNotification
{
    NSWindow* w = [aNotification object];
    NSLog(@"windows class is %@", [(NSObject*)[w delegate] className]);
    
    // do not release the quartz window, as the instance will be released in main R code
    if (w && [[(NSObject*)[w delegate] className] isEqualToString:@"QuartzCocoaView"]){
        [w setReleasedWhenClosed:NO];
    }
    
}

- (void) handlePipe: notification{
    
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding] ;
    
    [self performSelectorOnMainThread:@selector(writeText:) withObject:str waitUntilDone:YES];
    
}

#pragma mark -

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

#pragma mark -

- (void) consoleInput: (NSString*) str{
    @synchronized(@"consoleInput"){
        if (commandQueue != nil)
            return;
        
        commandQueue = [[NSString alloc] initWithFormat:@"%@\n", str];
        
        [hist add: str];
        
        [cocoaCondition lock];
        [cocoaCondition signal];
        [cocoaCondition unlock];
    }
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


- (void) writeText: (NSString*) str{
    @synchronized(@"writeText"){
        BOOL scroll = (NSMaxY(consoleTextView.visibleRect) == NSMaxY(consoleTextView.bounds));
        
        [consoleTextView replaceCharactersInRange:NSMakeRange(prompt, 0) withString:str];
        
        prompt += [str length];
        committedLength = consoleTextView.string.length;
        
        if (scroll)
            [consoleTextView scrollRangeToVisible: NSMakeRange(committedLength, 0)];
    }
}

- (void) writeInput: str {
    @synchronized(@"writeText"){
        BOOL scroll = (NSMaxY(consoleTextView.visibleRect) == NSMaxY(consoleTextView.bounds));
        long textLength = [[consoleTextView textStorage] length];
        [consoleTextView setSelectedRange:NSMakeRange(committedLength, textLength-committedLength)];
        [consoleTextView delete: nil];
        
        [consoleTextView replaceCharactersInRange:NSMakeRange(committedLength, 0) withString:str];
        prompt = committedLength = consoleTextView.string.length;
        
        if (scroll)
            [consoleTextView scrollRangeToVisible: NSMakeRange(committedLength, 0)];
    }
}

- (void) writePrompt: str {
    @synchronized(@"writeText"){
        BOOL scroll = (NSMaxY(consoleTextView.visibleRect) == NSMaxY(consoleTextView.bounds));
        
        prompt = committedLength;
        [consoleTextView replaceCharactersInRange:NSMakeRange(committedLength, 0) withString:str];
        committedLength = consoleTextView.string.length;
        
        if (scroll)
            [consoleTextView scrollRangeToVisible: NSMakeRange(committedLength, 0)];
    }
}
    
#pragma mark -

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

       // [[consoleTextView undoManager] removeAllActions];

		return(YES);
    }

	// From R.app

    // ---- history browsing ----
	if (@selector(moveUp:) == commandSelector) {
        long textLength = [[textView textStorage] length];
        NSRange sr=[textView selectedRange];
        if (sr.location==committedLength || sr.location==textLength) {
            NSRange range=NSMakeRange(committedLength, textLength-committedLength);
            NSString *text = [[textView attributedSubstringFromRange:range] string];
            if([hist isDirty]){
                [hist updateDirt: text];
            }
            NSString *news = [hist prev];
            if (news!=nil) {
                sr.length=0;
                sr.location=committedLength;
                [textView setSelectedRange:sr];
                [textView replaceCharactersInRange:range withString:news];
                [textView insertText:@""];
            }
			return(YES);
        }
    }
    if (@selector(moveDown:) == commandSelector) {
        long textLength = [[textView textStorage] length];
        NSRange sr=[textView selectedRange];
        if ((sr.location==committedLength || sr.location==textLength) && ![hist isDirty] ) {
            NSRange range=NSMakeRange(committedLength, textLength-committedLength);
            NSString *news = [hist next];
            if (news==nil) news=@"";
            sr.length=0; sr.location=committedLength;
            [textView setSelectedRange:sr];
            [textView replaceCharactersInRange:range withString:news];
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
		NSRange sr = [textView selectedRange];
		if (sr.length)
			[textView insertText:@""];
		else {
			sr.length = sr.location - committedLength;
			sr.location = committedLength;
			if (sr.length > 0) {
				[textView setSelectedRange:sr];
				[textView insertText:@""];
			}
		}
		return(YES);
	}

	if ([textView selectedRange].location >= committedLength &&
        (@selector(moveToBeginningOfParagraphAndModifySelection:) == commandSelector||
         @selector(moveToLeftEndOfLineAndModifySelection:) == commandSelector ||
         @selector(moveToBeginningOfLineAndModifySelection:) == commandSelector)) {
            NSRange sr = [textView selectedRange];
            sr.length = sr.location + sr.length - committedLength;
            sr.location = committedLength;
            if((long)sr.length<0)
                sr.length=0;
            [textView setSelectedRange: sr];
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
