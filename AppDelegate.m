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
     RSpaceWindowController*  wc;
}

-(id) init
{
    self = [super init];



    return self;
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

