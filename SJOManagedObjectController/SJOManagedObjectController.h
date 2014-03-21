//
//  SJOManagedObjectController.h
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJOManagedObjectController : NSObject
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readonly) NSArray *fetchedObjects;
@property (nonatomic, strong, readonly) NSManagedObjectContext *context;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context;
- (BOOL)performFetch:(NSError**)error;

@end
