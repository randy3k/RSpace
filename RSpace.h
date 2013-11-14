//
//  RSpace.h
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//


@interface RSpace : NSObject <NSApplicationDelegate>{
    NSPipe* pipe;
    NSFileHandle* pipeReadHandle;
}


@property (retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (retain) IBOutlet NSWindow *consoleWindow;
@property (retain) IBOutlet NSScrollView *consoleScrollView;
@property (retain) IBOutlet NSTextView *consoleTextView;

- (void) consoleInput : (NSString*) str;

- (void) writeText: (NSArray*) array;

- (void) writeInput: (NSArray*) array;

- (NSString*) readText;

- (BOOL)textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector;

@end
