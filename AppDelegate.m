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
    
    return self;
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *) app {
    
	if ([wc windowShouldClose: [wc window]]) {
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
//    [consoleWindow setDocumentEdited: YES];
    
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    //    change close button to dotted button
    wc = [[RSpaceWindowController alloc] initWithWindowNibName:@"RSpaceWindow"];
    [wc showWindow:nil];
    [wc.window makeKeyAndOrderFront:self];
//    [[wc consoleTextView]setString:@"test"];
//    NSLog(@"String=%@", [[wc consoleTextView]string] );
    
}

@end

