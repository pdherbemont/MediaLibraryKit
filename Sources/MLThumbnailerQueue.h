//
//  MLThumbnailerQueue.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLFile;

@interface MLThumbnailerQueue : NSOperationQueue {
    NSDictionary *_fileDescriptionToOperation;
}
+ (MLThumbnailerQueue *)sharedThumbnailerQueue;
- (void)addFile:(MLFile *)file;
- (void)setHighPriorityForFile:(MLFile *)file;
- (void)setDefaultPriorityForFile:(MLFile *)file;

- (void)stop;
- (void)resume;
@end
