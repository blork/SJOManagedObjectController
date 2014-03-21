//
//  SJOManagedObjectController.m
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import "SJOManagedObjectController.h"

@interface SJOManagedObjectController ()
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSArray *fetchedObjects;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end


@implementation SJOManagedObjectController

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        _context = context;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
}

#pragma mark Fetching

- (BOOL)performFetch:(NSError**)error
{
    self.fetchedObjects = [self.context executeFetchRequest:self.fetchRequest error:error];
    return error ? NO : YES;
}

#pragma mark - NSNotifications

- (void)contextDidSave:(NSNotification*)notification
{
    if (!self.fetchedObjects && self.delegate) {
        return;
    }
    
    NSArray *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSArray *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];

    if ([self.delegate respondsToSelector:@selector(controller:updatedObjects:)]) {
        NSIndexSet *updatedIndexes = [self.fetchedObjects indexesOfObjectsPassingTest:^BOOL(NSManagedObject* existingObject, NSUInteger idx, BOOL *stop) {
            for (NSManagedObject *updatedObject in updatedObjects) {
                if ([updatedObject.objectID isEqual:existingObject.objectID]) {
                    return YES;
                }
            }
            return NO;
        }];
        
        [self.delegate controller:self updatedObjects:updatedIndexes];
    }
    
    if ([self.delegate respondsToSelector:@selector(controller:deletedObjects:)]) {
        NSIndexSet *deletedIndexes = [self.fetchedObjects indexesOfObjectsPassingTest:^BOOL(NSManagedObject* existingObject, NSUInteger idx, BOOL *stop) {
            return [deletedObjects containsObject:existingObject];
        }];
        
        [self.delegate controller:self updatedObjects:deletedIndexes];
    }
    


}

@end
