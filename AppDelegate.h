//
//  RSpace.h
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//


@interface NSApplication (ScriptingSupport)
- (id)handleDCMDCommand:(NSScriptCommand*)command;
@end


@interface AppDelegate : NSObject <NSApplicationDelegate>

@end
