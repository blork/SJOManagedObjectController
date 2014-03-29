//
//  Post.h
//  SJOManagedObjectController
//
//  Created by Sam Oakley on 20/03/2014.
//  Copyright (c) 2014 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Post : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * title;

@end
