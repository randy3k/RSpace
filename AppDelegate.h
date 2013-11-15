//
//  RSpace.h
//  RSpace
//
//  Created by Randy Lai on 11/7/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//


@interface AppDelegate : NSObject <NSApplicationDelegate>{
    NSPipe* pipe;
    NSFileHandle* pipeReadHandle;
}

@end
