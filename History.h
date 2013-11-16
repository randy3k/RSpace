//
//  History.h
//  RSpace
//
//  Created by Randy Lai on 11/15/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface History : NSObject{
    NSMutableArray* history;
    long current;
    NSString* dirt;
}

- (BOOL) isDirty;

- (void) updateDirt: (NSString*) str;

- (void) add: (NSString*) str;

- (NSString*) next;

- (NSString*) prev;

@end
