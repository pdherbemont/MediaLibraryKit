//
//  MLFileParserQueue.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 8/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLFile;

@interface MLFileParserQueue : NSOperationQueue {
    NSDictionary *_fileDescriptionToOperation;
}
+ (MLFileParserQueue *)sharedFileParserQueue;
- (void)addFile:(MLFile *)file;
- (void)setHighPriorityForFile:(MLFile *)file;
- (void)setDefaultPriorityForFile:(MLFile *)file;

- (void)stop;
- (void)resume;
@end
