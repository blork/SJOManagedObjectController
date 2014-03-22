//
//  NSArray+SJOIndexSet.m
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 22/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import "NSArray+SJOIndexSet.h"

@implementation NSArray (SJOIndexSet)

-(NSIndexSet*) sjo_indexesOfObjects
{
    return [self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return YES;
    }];
}

@end
