//
//  MLFile.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLFile.h"

#import "MLShow.h"
#import "MLShowEpisode.h"
#import "MLMediaLibrary.h"
#import "MLThumbnailerQueue.h"

#import <Foundation/Foundation.h>

NSString *kMLFileTypeMovie = @"movie";
NSString *kMLFileTypeClip = @"clip";
NSString *kMLFileTypeTVShowEpisode = @"tvShowEpisode";

@implementation MLFile

+ (NSArray *)allFiles
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:moc];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES"]];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];

    NSArray *movies = [moc executeFetchRequest:request error:nil];
	[request release];

    return movies;
}

- (BOOL)isKindOfType:(NSString *)type
{
    return [self.type isEqualToString:type];
}
- (BOOL)isMovie
{
    return [self isKindOfType:kMLFileTypeTVShowEpisode];
}
- (BOOL)isClip
{
    return [self isKindOfType:kMLFileTypeTVShowEpisode];
}
- (BOOL)isShowEpisode
{
    return [self isKindOfType:kMLFileTypeTVShowEpisode];
}
- (NSString *)artworkURL
{
    if ([self isShowEpisode]) {
        return self.showEpisode.artworkURL;
    }
    return [self primitiveValueForKey:@"artworkURL"];
}

- (NSString *)title
{
    if ([self isShowEpisode]) {
        MLShowEpisode *episode = self.showEpisode;
        NSString *name = [NSString stringWithFormat:@"%@ - S%02dE%02d",
                          episode.show.name, [episode.seasonNumber intValue],
                          [episode.episodeNumber intValue]];
        return episode.name ? [name stringByAppendingFormat:@" - %@", episode.name]
                            : name;
    }
    [self willAccessValueForKey:@"title"];
    NSString *ret = [self primitiveValueForKey:@"title"];
    [self didAccessValueForKey:@"title"];
    return ret;
}

@dynamic seasonNumber;
@dynamic remainingTime;
@dynamic releaseYear;
@dynamic lastPosition;
@dynamic playCount;
@dynamic artworkURL;
@dynamic url;
@dynamic type;
@dynamic title;
@dynamic shortSummary;
@dynamic currentlyWatching;
@dynamic episodeNumber;
@dynamic unread;
@dynamic hasFetchedInfo;
@dynamic noOnlineMetaData;
@dynamic computedThumbnail;
@dynamic showEpisode;
@dynamic labels;
@dynamic tracks;
@dynamic isOnDisk;
@dynamic duration;

- (void)willDisplay
{
    [[MLThumbnailerQueue sharedThumbnailerQueue] setHighPriorityForFile:self];
}

- (void)didHide
{
    [[MLThumbnailerQueue sharedThumbnailerQueue] setDefaultPriorityForFile:self];
}

- (NSManagedObject *)videoTrack
{
    NSSet *tracks = [self tracks];
    if (!tracks)
        return nil;
    for (NSManagedObject *track in tracks) {
        if ([[[track entity] name] isEqualToString:@"VideoTrackInformation"])
            return track;
    }
    return nil;
}

- (size_t)fileSizeInBytes
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [manager fileAttributesAtPath:[[NSURL URLWithString:self.url] path] traverseLink:YES];
    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
    return [fileSize unsignedLongLongValue];
}

@end
