//
//  Engine.h
//  RSpace
//
//  Created by Randy Lai on 11/8/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

@class RSpaceWindowController;

@interface Engine : NSObject{
    
}
@property (retain) RSpaceWindowController* console;

+ (Engine*) R;

- (void) activate;

- (void) run_repl;



@end
