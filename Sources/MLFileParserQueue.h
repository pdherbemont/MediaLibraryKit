//
//  MLFileParserQueue.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 8/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLFile;

@interface MLFileParserQueue : NSObject {
    NSDictionary *_fileDescriptionToOperation;
    NSOperationQueue *_queue;
}
+ (MLFileParserQueue *)sharedFileParserQueue;
- (void)addFile:(MLFile *)file;
- (void)setHighPriorityForFile:(MLFile *)file;
- (void)setDefaultPriorityForFile:(MLFile *)file;

- (void)stop;
- (void)resume;

@property (nonatomic, retain) NSOperationQueue *queue;
@end
