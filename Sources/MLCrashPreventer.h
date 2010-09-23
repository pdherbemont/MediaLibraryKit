//
//  MLCrashPreventer.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 9/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLFile;

@interface MLCrashPreventer : NSObject {
    NSMutableArray *_parsedFiles;
}

+ (id)sharedPreventer;

- (void)cancelAllFileParse;

- (void)markCrasherFiles;

- (BOOL)isFileSafe:(MLFile *)file;

- (void)willParseFile:(MLFile *)file;
- (void)didParseFile:(MLFile *)file;
@end
