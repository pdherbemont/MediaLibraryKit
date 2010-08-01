//
//  MLLabel.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MLFile;

@interface MLLabel :  NSManagedObject
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* files;

@end


@interface MLLabel (CoreDataGeneratedAccessors)
- (void)addFilesObject:(MLFile *)value;
- (void)removeFilesObject:(MLFile *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;

@end

