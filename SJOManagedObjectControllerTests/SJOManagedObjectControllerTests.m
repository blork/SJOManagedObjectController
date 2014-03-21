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

@property (strong, nonatomic) NSArray *changedObjects;

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




- (void)testUpdating
{
    NSManagedObjectContext* privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.persistentStoreCoordinator = [(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];

    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    
    SJOManagedObjectController *controller = [[SJOManagedObjectController alloc] initWithFetchRequest:request
                                                                                 managedObjectContext:self.managedObjectContext];
    controller.delegate = self;
    
    NSError *error = nil;
    [controller performFetch:&error];
    
    XCTAssertEqual([[controller fetchedObjects] firstObject], self.post, @"");

    [privateContext performBlockAndWait:^{
        Post *post = (Post*)[privateContext existingObjectWithID:self.post.objectID error:nil];
        post.title = @"Hello!";
        [privateContext save:nil];
    }];

    AGWW_WAIT_WHILE(!self.changedObjects, 2.0);
    
    XCTAssertEqual(self.changedObjects.count, 1, @"");
    XCTAssertEqualObjects([[self.changedObjects firstObject] title], @"Hello!", @"");

}

-(void)controller:(SJOManagedObjectController *)controller updatedObjects:(NSIndexSet *)changedObjectIndexes
{
    self.changedObjects = [[controller fetchedObjects] objectsAtIndexes:changedObjectIndexes];
}


@end
