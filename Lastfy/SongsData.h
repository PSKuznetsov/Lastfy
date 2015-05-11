//
//  SongsData.h
//  Lastfy
//
//  Created by Paul Kuznetsov on 11/05/15.
//  Copyright (c) 2015 Paul Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SongsData : NSManagedObject

@property (nonatomic, retain) NSString * albumTitle;
@property (nonatomic, retain) NSNumber * songPlayCount;
@property (nonatomic, retain) NSString * songTitle;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSNumber * duration;

@end
