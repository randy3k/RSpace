//
//  WindowController.h
//  RSpace
//
//  Created by Randy Lai on 11/14/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

@interface RSpaceWindowController : NSWindowController<NSWindowDelegate>

@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSTextView *consoleTextView;
@property (strong) IBOutlet NSWindow *consoleWindow;



- (void) consoleInput : (NSString*) str;

- (void) writeText: (NSArray*) array;

- (void) writeInput: (NSArray*) array;

- (NSString*) readText;

- (BOOL)textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector;



@end