//
//  SJOManagedObjectController.m
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import "SJOManagedObjectController.h"
#import "NSArray+SJOIndexSet.h"

@interface SJOManagedObjectController ()
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSArray *fetchedObjects;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end


@implementation SJOManagedObjectController

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        _managedObjectContext = context;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
}

#pragma mark Fetching

- (BOOL)performFetch:(NSError**)error
{
    self.fetchedObjects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:error];
    if ([self.delegate respondsToSelector:@selector(controller:fetchedObjects:error:)]) {
        [self.delegate controller:self fetchedObjects:[self.fetchedObjects sjo_indexesOfObjects] error:error];
    }
    return error ? NO : YES;
}

- (void)performFetchAsyncronously
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
        
        __block NSArray *fetchedObjects;
        __block NSError *error = nil;
        [privateContext performBlockAndWait:^{
            fetchedObjects = [privateContext executeFetchRequest:self.fetchRequest error:&error];
        }];
        
        NSArray *managedObjectIds = [fetchedObjects valueForKey:@"objectID"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *objectsToReturn = [NSMutableArray array];
            for (NSManagedObjectID *objectID in managedObjectIds) {
                [objectsToReturn addObject:[self.managedObjectContext objectWithID:objectID]];
            }
            self.fetchedObjects = [NSArray arrayWithArray:objectsToReturn];
            if ([self.delegate respondsToSelector:@selector(controller:fetchedObjects:error:)]) {
                [self.delegate controller:self fetchedObjects:[self.fetchedObjects sjo_indexesOfObjects] error:&error];
            }
        });
        
    });
}

#pragma mark - Operations

- (BOOL)deleteObjects:(NSError**)error
{
    if (!self.fetchedObjects) {
        return NO;
    }
    for (NSManagedObject *object in self.fetchedObjects) {
        [self.managedObjectContext deleteObject:object];
    }
    [self.managedObjectContext save:error];
    
    return error ? NO : YES;
}

- (void)deleteObjectsAsyncronously
{
    NSArray *managedObjectIds = [self.fetchedObjects valueForKey:@"objectID"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
        for (NSManagedObjectID *objectID in managedObjectIds) {
            [privateContext deleteObject:[privateContext objectWithID:objectID]];
        }
        NSError *error = nil;
        [privateContext save:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.managedObjectContext save:nil];
        });
    });
}

#pragma mark - NSNotifications

- (void)contextDidSave:(NSNotification*)notification
{
    if (!self.fetchedObjects && self.delegate) {
        return;
    }
    
    NSArray *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSArray *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    if ([self.delegate respondsToSelector:@selector(controller:updatedObjects:)] && updatedObjects && updatedObjects.count > 0) {
        NSIndexSet *updatedIndexes = [self.fetchedObjects indexesOfObjectsPassingTest:^BOOL(NSManagedObject* existingObject, NSUInteger idx, BOOL *stop) {
            for (NSManagedObject *updatedObject in updatedObjects) {
                if ([updatedObject.objectID isEqual:existingObject.objectID]) {
                    return YES;
                }
            }
            return NO;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate controller:self updatedObjects:updatedIndexes];
        });
    }
    
    if ([self.delegate respondsToSelector:@selector(controller:deletedObjects:)] && deletedObjects && deletedObjects.count > 0) {
        NSIndexSet *deletedIndexes = [self.fetchedObjects indexesOfObjectsPassingTest:^BOOL(NSManagedObject* existingObject, NSUInteger idx, BOOL *stop) {
            for (NSManagedObject *deletedObject in deletedObjects) {
                if ([deletedObject.objectID isEqual:existingObject.objectID]) {
                    return YES;
                }
            }
            return NO;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate controller:self deletedObjects:deletedIndexes];
        });
    }
}

@end
