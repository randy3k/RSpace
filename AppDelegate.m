//
//  RSpace.m
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "AppDelegate.h"
#import "RSpaceWindowController.h"

@implementation NSApplication (ScriptingSupport)
- (id)handleDCMDCommand:(NSScriptCommand*)command
{
    NSDictionary *args = [command evaluatedArguments];
    NSString *cmd = [args objectForKey:@""];
    if (!cmd || [cmd isEqualToString:@""])
        return [NSNumber numberWithBool:NO];
	[[RSpaceWindowController wc] consoleInput: cmd];
    [[RSpaceWindowController wc] showWindow:nil];
    [[RSpaceWindowController wc].window makeKeyAndOrderFront:self];
	return [NSNumber numberWithBool:YES];
}
@end

@implementation AppDelegate{
     RSpaceWindowController*  wc;
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

