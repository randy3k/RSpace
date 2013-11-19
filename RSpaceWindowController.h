//
//  WindowController.h
//  RSpace
//
//  Created by Randy Lai on 11/14/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

@interface RSpaceWindowController : NSWindowController<NSWindowDelegate>


@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSButton *interrupt;
@property (strong) IBOutlet NSTextView *consoleTextView;
@property (strong) IBOutlet NSWindow *consoleWindow;
@property (strong) IBOutlet NSScrollView* consoleScrollView;

+ (RSpaceWindowController*) wc;

- (void) consoleInput : (NSString*) str;

- (void) writeText: (NSString*) str;

- (void) writeInput: str;

- (void) writePrompt: str;

- (NSString*) readText;

- (IBAction)interrupt:(id)sender;

@end
