//
//  History.m
//  RSpace
//
//  Created by Randy Lai on 11/15/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#import "History.h"

@implementation History

- (id) init{
    self = [super init];
    history = [[NSMutableArray alloc] init];
    current = 0;
    return self;
}

- (BOOL) isDirty {
    return (current==[history count])?YES:NO;
}

- (void) updateDirt:(NSString *)str{
    dirt = [str copy];
}

- (void) add:(NSString *)str{
    if ([history count]==0 || ![[history lastObject] isEqualToString:str])
        if (str && [str length]>0)
            [history addObject:str];
    current = [history count];
}

- (NSString*) prev{
    long index = current - 1;
    if (index>=0){
        current = index;
        return [history objectAtIndex:index];
    }
    return nil;
}

- (NSString*) next{
    long index = current + 1;
    if (index<=[history count]){
        current = index;
    }
    if (index<[history count]){
        return [history objectAtIndex:index];
    }
    return dirt;
}


@end
