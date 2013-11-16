//
//  RSpace.m
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "AppDelegate.h"
#import "RSpaceWindowController.h"


@implementation AppDelegate{
     NSPipe* pipeHandle;
     NSFileHandle* pipeReadHandle;
     RSpaceWindowController*  wc;
}

-(id) init
{
    self = [super init];
    
    pipeHandle = [NSPipe pipe] ;
    pipeReadHandle = [pipeHandle fileHandleForReading] ;
    dup2([[pipeHandle fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
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


- (void) handlePipe: notification{
    
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding] ;
  
    [wc writeText: str];

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

