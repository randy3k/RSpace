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
@property (retain) RSpaceWindowController* wc;

+ (Engine*) R;

- (void) writePipe: (NSString*) str;

- (void) activate;

- (void) run_repl;

- (void) interrupt;

@end
