//
//  Engine.h
//  RSpace
//
//  Created by Randy Lai on 11/8/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

@class RSpace;

@interface Engine : NSObject

@property (retain) RSpace* console;

+ (Engine*) R;

- (void) doEvents;

- (void) activate;

- (void) run_repl;



@end
