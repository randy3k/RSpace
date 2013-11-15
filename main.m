//
//  main.m
//  Rconsole
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "Engine.h"

int main(int argc, const char * argv[])
{
    setenv("R_GUI_APP_VERSION", [(NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] UTF8String], 1);
    setenv("R_GUI_APP_REVERSION", [(NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String], 1);

    setenv("R_HOME","/Library/Frameworks/R.framework/Resources",1);
    setenv("DYLD_LIBRARY_PATH","/Library/Frameworks/R.framework/Resources/lib",1);
    
    NSApplicationMain(argc, argv);
    return 0;

}
