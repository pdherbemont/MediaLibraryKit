//
//  MLShowEpisode.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLMediaLibrary.h"
#import "MLShowEpisode.h"

#import "MLShow.h"

@interface MLShowEpisode ()
@property (nonatomic, retain) NSNumber *primitiveUnread;
@property (nonatomic, retain) NSString *primitiveArtworkURL;
@end

@implementation MLShowEpisode

+ (NSArray *)allEpisodes
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShowEpisode" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"files.@count > 0"]];

    NSArray *episodes = [moc executeFetchRequest:request error:nil];
	[request release];

    return episodes;
}

+ (MLShowEpisode *)episodeWithShow:(id)show episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber createIfNeeded:(BOOL)createIfNeeded
{
    NSMutableSet *episodes = [show mutableSetValueForKey:@"episodes"];
    MLShowEpisode *episode = nil;
    if (seasonNumber && episodeNumber) {
        for (MLShowEpisode *episodeIter in episodes) {
            if ([episodeIter.seasonNumber intValue] == [seasonNumber intValue] &&
                [episodeIter.episodeNumber intValue] == [episodeNumber intValue]) {
                episode = episodeIter;
                break;
            }
        }
    }
    if (!episode && createIfNeeded) {
        episode = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"ShowEpisode"];
        episode.episodeNumber = episodeNumber;
        episode.seasonNumber = seasonNumber;
        [episodes addObject:episode];
    }
    return episode;
}

+ (MLShowEpisode *)episodeWithShowName:(NSString *)showName episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber
                        createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated
{
    MLShow *show = [MLShow showWithName:showName];
    *wasCreated = NO;
    if (!show && createIfNeeded) {
        *wasCreated = YES;
        show = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Show"];
        show.name = showName;
    } else if (!show && !createIfNeeded)
        return nil;

    return [MLShowEpisode episodeWithShow:show episodeNumber:episodeNumber seasonNumber:seasonNumber createIfNeeded:createIfNeeded];
}

@dynamic primitiveUnread;

@dynamic unread;


- (void)setUnread:(NSNumber *)unread
{
    [self willChangeValueForKey:@"unread"];
    [self setPrimitiveUnread:unread];
    [self didChangeValueForKey:@"unread"];
    [[[MLMediaLibrary sharedMediaLibrary] managedObjectContext] refreshObject:[self show] mergeChanges:YES];
    [[[MLMediaLibrary sharedMediaLibrary] managedObjectContext] refreshObject:self mergeChanges:YES];
}

@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic shouldBeDisplayed;
@dynamic episodeNumber;
@dynamic seasonNumber;
@dynamic lastSyncDate;
@dynamic artworkURL;

@dynamic primitiveArtworkURL;

- (void)setArtworkURL:(NSString *)artworkURL
{
    [self willChangeValueForKey:@"artworkURL"];
    NSSet *files = self.files;
    for (id file in files)
        [file willChangeValueForKey:@"artworkURL"];
    [self setPrimitiveArtworkURL:artworkURL];
    for (id file in files)
        [file didChangeValueForKey:@"artworkURL"];
    [self didChangeValueForKey:@"artworkURL"];
}
@dynamic name;
@dynamic show;
@dynamic files;
@end
