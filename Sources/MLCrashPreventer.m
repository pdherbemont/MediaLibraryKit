//
//  MLCrashPreventer.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 9/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLCrashPreventer.h"
#import "MLThumbnailerQueue.h"
#import "MLFileParserQueue.h"
#import "MLCrashPreventer.h"
#import "MLFile.h"
#import "MLMediaLibrary.h"


@implementation MLCrashPreventer
+ (id)sharedPreventer
{
    static MLCrashPreventer *crashPreventer;
    if (!crashPreventer)
        crashPreventer = [[MLCrashPreventer alloc] init];

    // Use the same queue for the two objects, because we wan't to track accurately
    // which operation causes a crash.
    [MLThumbnailerQueue sharedThumbnailerQueue].queue = [MLFileParserQueue sharedFileParserQueue].queue;

    return crashPreventer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _parsedFiles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    NSAssert([_parsedFiles count] == 0, @"You should call -cancelAllFileParse before releasing");
    [_parsedFiles release];
    [super dealloc];
}

- (void)cancelAllFileParse
{
    MLLog(@"Cancelling file parsing");
    for (MLFile *file in _parsedFiles)
        file.isBeingParsed = NO;
    [_parsedFiles removeAllObjects];
    [[MLMediaLibrary sharedMediaLibrary] save];
}

- (void)markCrasherFiles
{
    for (MLFile *file in [MLFile allFiles]) {
        if ([file isBeingParsed]) {
            file.isSafe = NO;
            file.isBeingParsed = NO;
        }
    }
}

- (BOOL)isFileSafe:(MLFile *)file
{
    return file.isSafe;
}

- (void)willParseFile:(MLFile *)file
{
    NSAssert([MLThumbnailerQueue sharedThumbnailerQueue].queue == [MLFileParserQueue sharedFileParserQueue].queue, @"");

    NSAssert([_parsedFiles count] < 1, @"Parsing multiple files at the same time. Crash preventer can't work accuratly.");
    file.isBeingParsed = YES;

    // Force to save the media library in case of crash.
    [[MLMediaLibrary sharedMediaLibrary] save];

    [_parsedFiles addObject:file];
}

- (void)didParseFile:(MLFile *)file
{
    file.isBeingParsed = NO;
    [_parsedFiles removeObject:file];
}

@end
