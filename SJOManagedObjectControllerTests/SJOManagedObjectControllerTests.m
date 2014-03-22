//
//  SJOManagedObjectControllerTests.m
//  SJOManagedObjectControllerTests
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AGAsyncTestHelper/AGAsyncTestHelper.h>
#import "AppDelegate.h"
#import "SJOManagedObjectController.h"
#import "Post.h"

@interface SJOManagedObjectControllerTests : XCTestCase <SJOManagedObjectControllerDelegate>
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Post *post;
@property (strong, nonatomic) SJOManagedObjectController *controller;

@property (assign) BOOL fetchDone;
@property (assign) BOOL updateDone;
@property (assign) BOOL deletionDone;
@end

@implementation SJOManagedObjectControllerTests

- (void)setUp
{
    [super setUp];
    self.fetchDone = NO;
    self.updateDone = NO;

    self.managedObjectContext = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    self.post = [NSEntityDescription insertNewObjectForEntityForName:@"Post"
                                               inManagedObjectContext:self.managedObjectContext];
    self.post.date = [NSDate date];
    self.post.title = @"Testing!";
    [self.managedObjectContext save:nil];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    self.controller = [[SJOManagedObjectController alloc] initWithFetchRequest:request
                                                                                 managedObjectContext:self.managedObjectContext];
    self.controller.delegate = self;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (NSManagedObject *object in fetchedObjects) {
        [self.managedObjectContext deleteObject:object];
    }
    [self.managedObjectContext save:nil];
    self.fetchDone = NO;
    self.updateDone = NO;
    
    self.controller.delegate = nil;
    self.controller = nil;
}

-(void)testFetching
{
    NSError *error = nil;
    [self.controller performFetch:&error];

    XCTAssertNil(error, @"");
    XCTAssertEqual([[self.controller fetchedObjects] count], 1, @"");
    XCTAssertEqual([[self.controller fetchedObjects] firstObject], self.post, @"");
}

- (void)testUpdating
{
    NSError *error = nil;
    [self.controller performFetch:&error];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        
        [privateContext performBlockAndWait:^{
            Post *post = (Post*)[privateContext objectWithID:self.post.objectID];
            post.title = @"Hello!";
            [privateContext save:nil];
        }];
    });

    AGWW_WAIT_WHILE(!self.updateDone, 2.0);
    
    XCTAssertEqual([[self.controller fetchedObjects] count], 1, @"");
    XCTAssertEqualObjects([[[self.controller fetchedObjects] firstObject] title], @"Hello!", @"");
}

-(void)testAsyncFetching
{
    [self.controller performFetchAsyncronously];
    
    XCTAssertNil([self.controller fetchedObjects], @"");
    AGWW_WAIT_WHILE(!self.fetchDone, 2.0);
    XCTAssertEqual([[self.controller fetchedObjects] count], 1, @"");
    
    Post *post = [[self.controller fetchedObjects] firstObject];
    XCTAssertEqual(post.managedObjectContext, self.managedObjectContext, @"");
}

-(void)testDeletion
{
    [self.controller performFetch:nil];

    XCTAssertEqual([[self.controller fetchedObjects] firstObject], self.post, @"");

    NSError *error = nil;
    [self.controller deleteObjects:&error];
    
    XCTAssertNil(error, @"");
    
    // On deletion the context is nilled out. isDeleted returns NO, though.
    XCTAssertNil(self.post.managedObjectContext, @"");
    XCTAssertTrue(self.post.isFault, @"");

    // Changing a deleted object causes Core Data to throw an exception:
    // "CoreData could not fulfill a fault"
    BOOL exceptionThrown = NO;
    @try {
        self.post.title = @"Deleted!";
        [self.managedObjectContext save:&error];
        XCTFail(@"Core Data should throw exception with error 'CoreData could not fulfill a fault'.");
    }
    @catch (NSException *exception) {
        exceptionThrown = YES;
    }
    
    XCTAssertTrue(exceptionThrown, @"");
    
    [self.managedObjectContext save:&error];
    XCTAssertNil(error, @"");
}


-(void)testAsyncDeletion
{
    [self.controller performFetch:nil];
    
    [self.controller deleteObjectsAsyncronously];

    AGWW_WAIT_WHILE(!self.deletionDone, 2.0);

    // On deletion the context is nilled out. isDeleted returns NO, though.
    XCTAssertNil(self.post.managedObjectContext, @"");
    XCTAssertTrue(self.post.isFault, @"");
    
    NSError *error = nil;
    // Changing a deleted object causes Core Data to throw an exception:
    // "CoreData could not fulfill a fault"
    BOOL exceptionThrown = NO;
    @try {
        self.post.title = @"Deleted!";
        [self.managedObjectContext save:&error];
        XCTFail(@"Core Data should throw exception with error 'CoreData could not fulfill a fault'.");
    }
    @catch (NSException *exception) {
        exceptionThrown = YES;
    }
    
    XCTAssertTrue(exceptionThrown, @"");
    
    [self.managedObjectContext save:&error];
    XCTAssertNil(error, @"");
}



#pragma mark - Deletion


-(void)controller:(SJOManagedObjectController *)controller fetchedObjects:(NSIndexSet *)fetchedObjectIndexes error:(NSError **)error
{
    XCTAssertTrue([NSThread isMainThread], @"");
    self.fetchDone = YES;
}

-(void)controller:(SJOManagedObjectController *)controller updatedObjects:(NSIndexSet *)changedObjectIndexes
{
    XCTAssertTrue([NSThread isMainThread], @"");
    self.updateDone = YES;
}

-(void)controller:(SJOManagedObjectController *)controller deletedObjects:(NSIndexSet *)deletedObjectIndexes
{
    XCTAssertTrue([NSThread isMainThread], @"");
    self.deletionDone = YES;
}

@end
