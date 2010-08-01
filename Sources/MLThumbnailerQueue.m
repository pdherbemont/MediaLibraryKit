//
//  MLThumbnailerQueue.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLThumbnailerQueue.h"
#import "VLCMediaThumbnailer.h"
#import "VLCMedia.h"
#import "MLFile.h"
#import <UIKit/UIKit.h>

@interface ThumbnailOperation : NSOperation <VLCMediaThumbnailerDelegate>
{
    MLFile *_file;
}
@property (retain,readwrite) MLFile *file;
@end

@implementation ThumbnailOperation
@synthesize file=_file;
- (id)initWithFile:(MLFile *)file;
{
    if (!(self = [super init]))
        return nil;
    self.file = file;
    return self;
}

- (void)dealloc
{
    [_file release];
    [super dealloc];
}

- (void)fetchThumbnail
{
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:self.file.url]];
    VLCMediaThumbnailer *thumbnailer = [VLCMediaThumbnailer thumbnailerWithMedia:media andDelegate:self];
    [thumbnailer fetchThumbnail];
    [[MLThumbnailerQueue sharedThumbnailerQueue] setSuspended:YES]; // Balanced in -mediaThumbnailer:didFinishThumbnail
    [self retain]; // Balanced in -mediaThumbnailer:didFinishThumbnail:
}
- (void)main
{
    [self performSelectorOnMainThread:@selector(fetchThumbnail) withObject:nil waitUntilDone:YES];
}

- (void)mediaThumbnailer:(VLCMediaThumbnailer *)mediaThumbnailer didFinishThumbnail:(CGImageRef)thumbnail
{
    mediaThumbnailer.delegate = nil;
    NSLog(@"Finished thumbnail for %@", self.file.title);
    self.file.computedThumbnail = UIImagePNGRepresentation([UIImage imageWithCGImage:thumbnail]);
    [[MLThumbnailerQueue sharedThumbnailerQueue] setSuspended:NO];
    [self release];
}
@end

@implementation MLThumbnailerQueue
+ (MLThumbnailerQueue *)sharedThumbnailerQueue
{
    static MLThumbnailerQueue *shared = nil;
    if (!shared) {
        shared = [[MLThumbnailerQueue alloc] init];
        [shared setMaxConcurrentOperationCount:1];
    }
    return shared;
}

- (void)addFile:(MLFile *)file
{
    [self addOperation:[[[ThumbnailOperation alloc] initWithFile:file] autorelease]];
}

- (void)stop
{
    [self setMaxConcurrentOperationCount:0];
}

- (void)resume
{
    [self setMaxConcurrentOperationCount:1];
}
@end
