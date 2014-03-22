//
//  SJOManagedObjectController.h
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SJOManagedObjectController;

@protocol SJOManagedObjectControllerDelegate <NSObject>
@optional
-(void)controller:(SJOManagedObjectController*)controller
   fetchedObjects:(NSIndexSet*)fetchedObjectIndexes error:(NSError**)error;
-(void)controller:(SJOManagedObjectController*)controller
   updatedObjects:(NSIndexSet*)changedObjectIndexes;
-(void)controller:(SJOManagedObjectController*)controller
   deletedObjects:(NSIndexSet*)deletedObjectIndexes;
@end


@interface SJOManagedObjectController : NSObject
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readonly) NSArray *fetchedObjects;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) id<SJOManagedObjectControllerDelegate> delegate;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context;
- (BOOL)performFetch:(NSError**)error;
- (void)performFetchAsyncronously;
- (BOOL)deleteObjects:(NSError**)error;
- (void)deleteObjectsAsyncronously;

@end
