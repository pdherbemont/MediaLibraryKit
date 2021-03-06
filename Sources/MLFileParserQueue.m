//
//  MLFileParserQueue.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 8/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <MobileVLCKit/MobileVLCKit.h>
#import "MLFileParserQueue.h"
#import "MLFile.h"
#import "MLMediaLibrary.h"
#import "MLCrashPreventer.h"

@interface MLParsingOperation : NSOperation
{
    MLFile *_file;
    VLCMedia *_media;
}
@property (retain,readwrite) MLFile *file;
@end

@interface MLFileParserQueue ()
- (void)didFinishOperation:(MLParsingOperation *)op;
@end

@implementation MLParsingOperation
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
    [_media release];
    [_file release];
    [super dealloc];
}

- (void)parse
{
    NSAssert(!_media, @"We are already parsing");

    MLLog(@"Starting parsing %@", self.file);
    [[MLCrashPreventer sharedPreventer] willParseFile:self.file];

    _media = [[VLCMedia mediaWithURL:[NSURL URLWithString:self.file.url]] retain];
    _media.delegate = self;
    [_media parse];
    MLFileParserQueue *parserQueue = [MLFileParserQueue sharedFileParserQueue];
    [parserQueue.queue setSuspended:YES]; // Balanced in -mediaDidFinishParsing
    [self retain]; // Balanced in -mediaDidFinishParsing:
}

- (void)main
{
    [self performSelectorOnMainThread:@selector(parse) withObject:nil waitUntilDone:YES];
}

- (void)mediaDidFinishParsing:(VLCMedia *)media
{
    MLLog(@"Parsed %@ - %d tracks", media, [[_media tracksInformation] count]);

    if (_media.delegate != self)
        return;

    _media.delegate = nil;
    NSArray *tracks = [_media tracksInformation];
    NSMutableSet *tracksSet = [NSMutableSet setWithCapacity:[tracks count]];
    for (NSDictionary *track in tracks) {
        NSString *type = [track objectForKey:VLCMediaTracksInformationType];
        NSManagedObject *trackInfo = nil;
        if ([type isEqualToString:VLCMediaTracksInformationTypeVideo]) {
            trackInfo = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"VideoTrackInformation"];
            [trackInfo setValue:[track objectForKey:VLCMediaTracksInformationVideoWidth] forKey:@"width"];
            [trackInfo setValue:[track objectForKey:VLCMediaTracksInformationVideoHeight] forKey:@"height"];
        } else if ([type isEqualToString:VLCMediaTracksInformationTypeAudio]) {
            trackInfo = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"AudioTrackInformation"];
            [trackInfo setValue:[track objectForKey:VLCMediaTracksInformationAudioRate] forKey:@"bitrate"];
            [trackInfo setValue:[track objectForKey:VLCMediaTracksInformationAudioChannelsNumber] forKey:@"channelsNumber"];
        }
        if (trackInfo)
            [tracksSet addObject:trackInfo];
    }
    // NSAssert([[self.file tracks] count] == 0, @"Reparsing a file with existing tracks"); // Don't assert here as we may want to re-parse, after all
    [self.file setTracks:tracksSet];
    [self.file setDuration:[[_media length] numberValue]];
    MLFileParserQueue *parserQueue = [MLFileParserQueue sharedFileParserQueue];
    [[MLCrashPreventer sharedPreventer] didParseFile:self.file];
    [parserQueue.queue setSuspended:NO];
    [parserQueue didFinishOperation:self];
    [_media autorelease];
    _media = nil;

    [self release];
}
@end

@implementation MLFileParserQueue
@synthesize queue=_queue;
+ (MLFileParserQueue *)sharedFileParserQueue
{
    static MLFileParserQueue *shared = nil;
    if (!shared) {
        shared = [[MLFileParserQueue alloc] init];
    }
    return shared;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _fileDescriptionToOperation = [[NSMutableDictionary alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)dealloc
{
    [_queue release];
    [_fileDescriptionToOperation release];
    [super dealloc];
}


static inline NSString *hashFromFile(MLFile *file)
{
    return [NSString stringWithFormat:@"%p", [[file objectID] URIRepresentation]];
}

- (void)didFinishOperation:(MLParsingOperation *)op
{
    [_fileDescriptionToOperation setValue:nil forKey:hashFromFile(op.file)];
}

- (void)addFile:(MLFile *)file
{
    if ([_fileDescriptionToOperation objectForKey:hashFromFile(file)])
        return;
    if (![[MLCrashPreventer sharedPreventer] isFileSafe:file]) {
        MLLog(@"%@ is unsafe and will crash, ignoring", file);
        return;
    }
    MLParsingOperation *op = [[MLParsingOperation alloc] initWithFile:file];
    [_fileDescriptionToOperation setValue:op forKey:hashFromFile(file)];
    [self.queue addOperation:op];
}

- (void)stop
{
    [_queue setMaxConcurrentOperationCount:0];
}

- (void)resume
{
    [_queue setMaxConcurrentOperationCount:1];
}

- (void)setHighPriorityForFile:(MLFile *)file
{
    MLParsingOperation *op = [_fileDescriptionToOperation objectForKey:hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityHigh];
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
    MLParsingOperation *op = [_fileDescriptionToOperation objectForKey:hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityNormal];
}

@end
