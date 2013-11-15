//
//  RSpace.m
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "AppDelegate.h"
#import "RSpaceWindowController.h"


@implementation AppDelegate

RSpaceWindowController*  wc;
-(id) init
{
    self = [super init];
    
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePipe:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQuartzWillClose:) name:NSWindowWillCloseNotification object:nil];
    
    return self;
}

// do not release the quartz window, as the instance will be released in main R code
- (void)handleQuartzWillClose:(NSNotification*) aNotification
{
    NSWindow* w = [aNotification object];
    NSLog(@"windows class is %@", [(NSObject*)[w delegate] className]);
    
    if (w && [[(NSObject*)[w delegate] className] isEqualToString:@"QuartzCocoaView"]){
        [w setReleasedWhenClosed:NO];
    }
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *) app {
    
	if ([wc windowShouldClose: self]) {
		return NSTerminateNow;
	}
    return NSTerminateCancel;
}

- (void) handlePipe: notification{
    
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding] ;
    
//    [RSpaceWindowController.consoleTextView setString: str];
    
    [wc writeText: @[str]];
    
    [pipeReadHandle readInBackgroundAndNotify] ;
}

-(void)awakeFromNib
{
    NSLog(@"awakeFromNib");
   
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    wc = [[RSpaceWindowController alloc] initWithWindowNibName:@"RSpaceWindow"];
    [wc showWindow:nil];
    [wc.window makeKeyAndOrderFront:self];

    
}

@end

