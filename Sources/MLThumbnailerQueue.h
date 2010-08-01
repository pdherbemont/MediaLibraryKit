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

}
+ (MLThumbnailerQueue *)sharedThumbnailerQueue;
- (void)addFile:(MLFile *)file;

- (void)stop;
- (void)resume;
@end
