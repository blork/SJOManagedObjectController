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

@interface SJOManagedObjectControllerTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Post *post;
@end

@implementation SJOManagedObjectControllerTests

- (void)setUp
{
    [super setUp];
    self.managedObjectContext = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    self.post = [NSEntityDescription insertNewObjectForEntityForName:@"Post"
                                               inManagedObjectContext:self.managedObjectContext];
    self.post.date = [NSDate date];
    self.post.title = @"Testing!";
    [self.managedObjectContext save:nil];
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
}



- (void)testDemoTheProblem
{
    __block BOOL jobDone = NO;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    XCTAssertEqual([fetchedObjects firstObject], self.post, @"");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        [privateContext performBlockAndWait:^{
            Post *post = (Post*)[privateContext existingObjectWithID:self.post.objectID error:nil];
            post.title = @"Hello!";
            [privateContext save:nil];
            jobDone = YES;
        }];
    });
    
    AGWW_WAIT_WHILE(!jobDone, 2.0);
    
    // If we do it this way, orphaned object is not updated.
    XCTAssertEqualObjects([[fetchedObjects firstObject] title], @"Testing!", @"");
}

- (void)testRefreshing
{
    NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];

    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    
    SJOManagedObjectController *controller = [[SJOManagedObjectController alloc] initWithFetchRequest:request
                                                                                 managedObjectContext:self.managedObjectContext];
    
    NSError *error = nil;
    [controller performFetch:&error];
    
    XCTAssertEqual([[controller fetchedObjects] firstObject], self.post, @"");

    [privateContext performBlockAndWait:^{
        Post *post = (Post*)[privateContext existingObjectWithID:self.post.objectID error:nil];
        post.title = @"Hello!";
        [privateContext save:nil];
    }];
    
    // 'Managed' managedObject is refreshed...
    XCTAssertEqualObjects([[[controller fetchedObjects] firstObject] title], @"Hello!", @"");
}


- (void)testDeletion
{
    __block BOOL jobDone = NO;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    SJOManagedObjectController *controller = [[SJOManagedObjectController alloc] initWithFetchRequest:request
                                                                                 managedObjectContext:self.managedObjectContext];
    
    NSError *error = nil;
    [controller performFetch:&error];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        [privateContext performBlockAndWait:^{
            Post *post = (Post*)[privateContext existingObjectWithID:self.post.objectID error:nil];
            [privateContext deleteObject:post];
            [privateContext save:nil];
            jobDone = YES;
        }];
    });

    AGWW_WAIT_WHILE(!jobDone, 2.0);

    XCTAssertEqualObjects([controller fetchedObjects], @[], @"");
}

- (void)testDemoTheDeletionProblem
{
    __block BOOL jobDone = NO;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    XCTAssertEqual([fetchedObjects firstObject], self.post, @"");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        [privateContext performBlockAndWait:^{
            Post *post = (Post*)[privateContext existingObjectWithID:self.post.objectID error:nil];
            [privateContext deleteObject:post];
            [privateContext save:nil];
            jobDone = YES;
        }];

    });
    
    AGWW_WAIT_WHILE(!jobDone, 2.0);

    XCTAssertTrue([[fetchedObjects firstObject] isDeleted], @"");
}


@end
