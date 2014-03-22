//
//  SJOManagedObjectController.h
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SJOManagedObjectController;

extern NSString* const SJOManagedObjectControllerErrorDomain;

/**
 *  The delegate of a SJOManagedObjectController object must adopt the SJOManagedObjectControllerDeledate protocol. 
 *  Optional methods of the protocol allow the delegate to be informed of changes to the underlying managed objects.
 */
@protocol SJOManagedObjectControllerDelegate <NSObject>
@optional

/**
 *  Called when objects are fetched as a result of a call to performFetch: or performFetchAsyncronously.
 *  Always called on the main thread.
 *
 *  @param controller           The SJOManagedObjectController where the objects are fetched.
 *  @param fetchedObjectIndexes The indexes of the newly fetched objects. Will be all objects in the array.
 *  @param error                If the fetch is not successful, this will be an error object that describes the problem.
 */
-(void)controller:(SJOManagedObjectController*)controller
   fetchedObjects:(NSIndexSet*)fetchedObjectIndexes error:(NSError**)error;

/**
 *  Called when objects are updated after the main context is saved or changes are merged from a background thread.
 *
 *  @param controller           The SJOManagedObjectController where the changes occured.
 *  @param changedObjectIndexes The indexes of the updated objects.
 */
-(void)controller:(SJOManagedObjectController*)controller
   updatedObjects:(NSIndexSet*)changedObjectIndexes;

/**
 *  Called when objects are deleted after the main context is saved or changes are merged from a background thread.
 *
 *  @param controller           The SJOManagedObjectController where the deletions occured.
 *  @param changedObjectIndexes The indexes of the deleted objects.
 */
-(void)controller:(SJOManagedObjectController*)controller
   deletedObjects:(NSIndexSet*)deletedObjectIndexes;
@end

/**
 *  This class helps manage NSManagedObjects in a similar way to NSFetchedResultsController.
 *  Should be used from the main thread unless otherwise noted.
 */
@interface SJOManagedObjectController : NSObject
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readonly) NSArray *managedObjects;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) id<SJOManagedObjectControllerDelegate> delegate;

/**
 *  Returns a SJOManagedObjectController set up with the given fetch request and context.
 *  The fetch request is not executed until performFetch:/performFetchAsync is called.
 *
 *  @param fetchRequest A fetch request that specifies the search criteria for the fetch. Must not be nil.
 *  @param context      The managed object context to use. Must not be nil.
 *
 *  @return An initialised SJOManagedObjectController.
 */
- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context;

/**
 *  Returns a SJOManagedObjectController that manages the given array of NSManagedObjects.
 *  Used when you want to monitor changes on already-fetched objects.
 *  performFetch:/performFetchAsync are non-op for this controller.
 *
 *  @param managedObjects An array of NSManagedObjects. Must not be nil.
 *
 *  @return An initialised SJOManagedObjectController.
 */
- (instancetype)initWithWithManagedObjects:(NSArray *)managedObjects;

/**
 *  Returns a SJOManagedObjectController that manages the given NSManagedObject.
 *  Used when you want to monitor changes on an already-fetched object.
 *  performFetch:/performFetchAsync are non-op for this controller.
 *
 *  @param managedObjects A NSManagedObject. Must not be nil.
 *
 *  @return An initialised SJOManagedObjectController.
 */
- (instancetype)initWithWithManagedObject:(NSManagedObject *)managedObject;

/**
 *  Re-run the fetch request. Identical to calling performFetch:.
 *
 *  @param error If there is a problem executing the fetch, upon return contains an instance of NSError that describes the problem.
 *
 *  @return YES if the fetch succeeds, otherwise NO.
 */
- (BOOL)refreshObjects:(NSError**)error;

/**
 *  Execute the fetch request and store the results in self.managedObjects.
 *  Blocks the main thread.
 *
 *  @param error If there is a problem executing the fetch, upon return contains an instance of NSError that describes the problem.
 *
 *  @return YES if the fetch succeeds, otherwise NO.
 */
- (BOOL)performFetch:(NSError**)error;

/**
 *  Execute the fetch request in a background thread and store the results in self.managedObjects.
 */
- (void)performFetchAsyncronously;

/**
 *  Deleted the fetched objects from self.managedObjectContext and saves.
 *  self.managedObjects must contain objects.
 *
 *  @param error If there is a problem deleting, upon return contains an instance of NSError that describes the problem.
 *
 *  @return YES if the delete succeeds, otherwise NO.
 */
- (BOOL)deleteObjects:(NSError**)error;

/**
 *  Perform a deletion in a background thread.
 */
- (void)deleteObjectsAsyncronously;

@end
