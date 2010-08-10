//
//  MLMediaLibrary.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLMediaLibrary.h"
#import "MLTitleDecrapifier.h"
#import "MLMovieInfoGrabber.h"
#import "MLTVShowInfoGrabber.h"
#import "MLTVShowEpisodesInfoGrabber.h"
#import "MLFile.h"
#import "MLLabel.h"
#import "MLShowEpisode.h"
#import "MLThumbnailerQueue.h"
#import "MLShow.h"
#import "MLFileParserQueue.h"

#define DEBUG 1

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define MLLog(...) NSLog(__VA_ARGS__)

// Pref key
static NSString *kLastTVDBUpdateServerTime = @"MLLastTVDBUpdateServerTime";

#if HAVE_BLOCK
@interface MLMediaLibrary ()
#else
@interface MLMediaLibrary () <MLMovieInfoGrabberDelegate, MLTVShowEpisodesInfoGrabberDelegate, MLTVShowInfoGrabberDelegate>
#endif
- (NSManagedObjectContext *)managedObjectContext;
- (void)startUpdateDB;
- (NSString *)databaseFolderPath;
@end

@implementation MLMediaLibrary
+ (id)sharedMediaLibrary
{
    static id sharedMediaLibrary = nil;
    if (!sharedMediaLibrary) {
        sharedMediaLibrary = [[[self class] alloc] init];
        NSLog(@"Initializing db in %@", [sharedMediaLibrary databaseFolderPath]);
        [sharedMediaLibrary startUpdateDB];
    }
    return sharedMediaLibrary;
}

- (NSFetchRequest *)fetchRequestForEntity:(NSString *)entity
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity inManagedObjectContext:moc];
    NSAssert(entityDescription, @"No entity");
    [request setEntity:entityDescription];
    return [request autorelease];
}

- (id)createObjectForEntity:(NSString *)entity
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    return [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:moc];
}

#pragma mark -
#pragma mark Media Library
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;
    _managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    return _managedObjectModel;
}

- (NSString *)databaseFolderPath
{
    int directory = NSLibraryDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths objectAtIndex:0];
    return directoryPath;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;

    NSString *databaseFolderPath = [self databaseFolderPath];

    NSString *path = [databaseFolderPath stringByAppendingPathComponent: @"MediaLibrary.sqlite"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSNumber *yes = [NSNumber numberWithBool:YES];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             yes, NSMigratePersistentStoresAutomaticallyOption,
                             yes, NSInferMappingModelAutomaticallyOption, nil];

    NSError *error;
    NSPersistentStore *persistentStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error];

    if (!persistentStore) {
#if! TARGET_OS_IPHONE
        // FIXME: Deal with versioning
        NSInteger ret = NSRunAlertPanel(@"Error", @"The Media Library you have on your disk is not compatible with the one Lunettes can read. Do you want to create a new one?", @"No", @"Yes", nil);
        if (ret == NSOKButton)
            [NSApp terminate:nil];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
#else
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
#endif
        persistentStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error];
        if (!persistentStore) {
#if! TARGET_OS_IPHONE
            NSRunInformationalAlertPanel(@"Corrupted Media Library", @"There is nothing we can apparently do about it...", @"OK", nil, nil);
#else
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Corrupted Media Library" message:@"There is nothing we can apparently do about it..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
#endif
            // Probably assert instead.
            return nil;
        }
    }

    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    [coordinator release];
    [_managedObjectContext setUndoManager:nil];
    [_managedObjectContext addObserver:self forKeyPath:@"hasChanges" options:NSKeyValueObservingOptionInitial context:nil];
    return _managedObjectContext;
}

- (void)savePendingChanges
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
    NSError *error = nil;
    BOOL success = [[self managedObjectContext] save:&error];
    NSAssert1(success, @"Can't save: %@", error);
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    NSProcessInfo *process = [NSProcessInfo processInfo];
    if ([process respondsToSelector:@selector(enableSuddenTermination)])
        [process enableSuddenTermination];
#endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"hasChanges"] && object == _managedObjectContext) {
#if !TARGET_OS_IPHONE && MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        NSProcessInfo *process = [NSProcessInfo processInfo];
        if ([process respondsToSelector:@selector(disableSuddenTermination)])
            [process disableSuddenTermination];
#endif

        if ([[self managedObjectContext] hasChanges]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
            [self performSelector:@selector(savePendingChanges) withObject:nil afterDelay:1.];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark No meta data fallbacks

- (void)computeThumbnailForFile:(MLFile *)file
{
    if (!file.computedThumbnail) {
        MLLog(@"Computing thumbnail for %@", file.title);
        [[MLThumbnailerQueue sharedThumbnailerQueue] addFile:file];
    }
}
- (void)errorWhenFetchingMetaDataForFile:(MLFile *)file
{
    MLLog(@"Error when fetching for '%@'", file.title);

    [self computeThumbnailForFile:file];
}

- (void)errorWhenFetchingMetaDataForShow:(MLShow *)show
{
    for (MLShowEpisode *episode in show.episodes) {
        for (MLFile *file in episode.files)
            [self errorWhenFetchingMetaDataForFile:file];
    }
}

- (void)noMetaDataInRemoteDBForFile:(MLFile *)file
{
    file.noOnlineMetaData = [NSNumber numberWithBool:YES];
    [self computeThumbnailForFile:file];
}

- (void)noMetaDataInRemoteDBForShow:(MLShow *)show
{
    for (MLShowEpisode *episode in show.episodes) {
        for (MLFile *file in episode.files)
            [self noMetaDataInRemoteDBForFile:file];
    }
}

#pragma mark -
#pragma mark Getter

- (void)addNewLabelWithName:(NSString *)name
{
    MLLabel *label = [self createObjectForEntity:@"Label"];
    label.name = name;
}

/**
 * TV MLShow Episodes
 */

#pragma mark -
#pragma mark Online meta data grabbing

#if !HAVE_BLOCK
- (void)tvShowEpisodesInfoGrabberDidFinishGrabbing:(MLTVShowEpisodesInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;

    NSArray *results = grabber.episodesResults;
    [show setValue:[grabber.results objectForKey:@"serieArtworkURL"] forKey:@"artworkURL"];
    for (id result in results) {
        if ([[result objectForKey:@"serie"] boolValue]) {
            continue;
        }
        MLShowEpisode *showEpisode = [MLShowEpisode episodeWithShow:show episodeNumber:[result objectForKey:@"episodeNumber"] seasonNumber:[result objectForKey:@"seasonNumber"] createIfNeeded:YES];
        showEpisode.name = [result objectForKey:@"title"];
        showEpisode.theTVDBID = [result objectForKey:@"id"];
        showEpisode.shortSummary = [result objectForKey:@"shortSummary"];
        showEpisode.artworkURL = [result objectForKey:@"artworkURL"];
        if (!showEpisode.artworkURL) {
            for (MLFile *file in showEpisode.files)
                [self computeThumbnailForFile:file];
        }

        showEpisode.lastSyncDate = [MLTVShowInfoGrabber serverTime];
    }
    show.lastSyncDate = [MLTVShowInfoGrabber serverTime];
}

- (void)save
{
    [[self managedObjectContext] save:nil];
}

- (void)tvShowEpisodesInfoGrabber:(MLTVShowEpisodesInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLShow *show = grabber.userData;
    [self errorWhenFetchingMetaDataForShow:show];
}

- (void)tvShowInfoGrabberDidFinishGrabbing:(MLTVShowInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;
    NSArray *results = grabber.results;
    if ([results count] > 0) {
        NSDictionary *result = [results objectAtIndex:0];
        NSString *showId = [result objectForKey:@"id"];

        show.theTVDBID = showId;
        show.name = [result objectForKey:@"title"];
        show.shortSummary = [result objectForKey:@"shortSummary"];
        show.releaseYear = [result objectForKey:@"releaseYear"];

        // Fetch episodes info
        MLTVShowEpisodesInfoGrabber *grabber = [[[MLTVShowEpisodesInfoGrabber alloc] init] autorelease];
        grabber.delegate = self;
        grabber.userData = show;
        [grabber lookUpForShowID:showId];
    }
    else {
        // Not found.
        [self noMetaDataInRemoteDBForShow:show];
        show.lastSyncDate = [MLTVShowInfoGrabber serverTime];
    }
}

- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLShow *show = grabber.userData;
    [self errorWhenFetchingMetaDataForShow:show];
}

- (void)tvShowInfoGrabberDidFetchServerTime:(MLTVShowInfoGrabber *)grabber
{
    MLShow *show = grabber.userData;

    [[NSUserDefaults standardUserDefaults] setInteger:[[MLTVShowInfoGrabber serverTime] integerValue] forKey:kLastTVDBUpdateServerTime];

    // First fetch the MLShow ID
    MLTVShowInfoGrabber *showInfoGrabber = [[[MLTVShowInfoGrabber alloc] init] autorelease];
    showInfoGrabber.delegate = self;
    showInfoGrabber.userData = show;

    MLLog(@"Fetching show information on %@", show.name);

    [showInfoGrabber lookUpForTitle:show.name];
}
#endif

- (void)fetchMetaDataForShow:(MLShow *)show
{
    MLLog(@"Fetching show server time");

    // First fetch the serverTime, so that we can update each entry.
#if HAVE_BLOCK
    [MLTVShowInfoGrabber fetchServerTimeAndExecuteBlock:^(NSNumber *serverDate) {

        [[NSUserDefaults standardUserDefaults] setInteger:[serverDate integerValue] forKey:kLastTVDBUpdateServerTime];

        MLLog(@"Fetching show information on %@", show.name);

        // First fetch the MLShow ID
        MLTVShowInfoGrabber *grabber = [[[MLTVShowInfoGrabber alloc] init] autorelease];
        [grabber lookUpForTitle:show.name andExecuteBlock:^{
            NSArray *results = grabber.results;
            if ([results count] > 0) {
                NSDictionary *result = [results objectAtIndex:0];
                NSString *showId = [result objectForKey:@"id"];

                show.theTVDBID = showId;
                show.name = [result objectForKey:@"title"];
                show.shortSummary = [result objectForKey:@"shortSummary"];
                show.releaseYear = [result objectForKey:@"releaseYear"];

                MLLog(@"Fetching show episode information on %@", showId);

                // Fetch episode info
                MLTVShowEpisodesInfoGrabber *grabber = [[[MLTVShowEpisodesInfoGrabber alloc] init] autorelease];
                [grabber lookUpForShowID:showId andExecuteBlock:^{
                    NSArray *results = grabber.episodesResults;
                    [show setValue:[grabber.results objectForKey:@"serieArtworkURL"] forKey:@"artworkURL"];
                    for (id result in results) {
                        if ([[result objectForKey:@"serie"] boolValue]) {
                            continue;
                        }
                        MLShowEpisode *showEpisode = [self showEpisodeWithShow:show episodeNumber:[result objectForKey:@"episodeNumber"] seasonNumber:[result objectForKey:@"seasonNumber"]];
                        showEpisode.name = [result objectForKey:@"title"];
                        showEpisode.theTVDBID = [result objectForKey:@"id"];
                        showEpisode.shortSummary = [result objectForKey:@"shortSummary"];
                        showEpisode.artworkURL = [result objectForKey:@"artworkURL"];
                        showEpisode.lastSyncDate = serverDate;
                    }
                    show.lastSyncDate = serverDate;
                }];
            }
            else {
                // Not found.
                show.lastSyncDate = serverDate;
            }

        }];
    }];
#else
    MLTVShowInfoGrabber *grabber = [[[MLTVShowInfoGrabber alloc] init] autorelease];
    grabber.delegate = self;
    grabber.userData = show;
    [grabber fetchServerTime];
#endif
}

- (void)addTVShowEpisodeWithInfo:(NSDictionary *)tvShowEpisodeInfo andFile:(MLFile *)file
{
    file.type = kMLFileTypeTVShowEpisode;

    NSNumber *seasonNumber = [tvShowEpisodeInfo objectForKey:@"season"];
    NSNumber *episodeNumber = [tvShowEpisodeInfo objectForKey:@"episode"];
    NSString *tvShowName = [tvShowEpisodeInfo objectForKey:@"tvShowName"];
    BOOL hasNoTvShow = NO;
    if (!tvShowName) {
        tvShowName = @"Untitled TV MLShow";
        hasNoTvShow = YES;
    }
    BOOL wasInserted = NO;
    MLShow *show = nil;
    MLShowEpisode *episode = [MLShowEpisode episodeWithShowName:tvShowName episodeNumber:episodeNumber seasonNumber:seasonNumber createIfNeeded:YES wasCreated:&wasInserted];
    if (episode)
        show = episode.show;
    if (wasInserted && !hasNoTvShow) {
        show.name = tvShowName;
        [self fetchMetaDataForShow:show];
    }

    if (hasNoTvShow)
        episode.name = file.title;
    file.seasonNumber = seasonNumber;
    file.episodeNumber = episodeNumber;
    episode.shouldBeDisplayed = [NSNumber numberWithBool:YES];

    [episode addFilesObject:file];
    file.showEpisode = episode;

    // The rest of the meta data will be fetched using the MLShow
    file.hasFetchedInfo = [NSNumber numberWithBool:YES];
}


/**
 * MLFile auto detection
 */


#if !HAVE_BLOCK
- (void)movieInfoGrabber:(MLMovieInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    MLFile *file = grabber.userData;
    [self errorWhenFetchingMetaDataForFile:file];
}

- (void)movieInfoGrabberDidFinishGrabbing:(MLMovieInfoGrabber *)grabber
{
    NSNumber *yes = [NSNumber numberWithBool:YES];

    NSArray *results = grabber.results;
    MLFile *file = grabber.userData;
    if ([results count] > 0) {
        NSDictionary *result = [results objectAtIndex:0];
        file.artworkURL = [result objectForKey:@"artworkURL"];
        file.title = [result objectForKey:@"title"];
        file.shortSummary = [result objectForKey:@"shortSummary"];
        file.releaseYear = [result objectForKey:@"releaseYear"];
    }
    else {
        [self noMetaDataInRemoteDBForFile:file];
    }

    file.hasFetchedInfo = yes;
}
#endif

- (void)fetchMetaDataForFile:(MLFile *)file
{
    MLLog(@"Fetching meta data for %@", file.title);

    if (!file.tracks)
        [[MLFileParserQueue sharedFileParserQueue] addFile:file];

    NSDictionary *tvShowEpisodeInfo = [MLTitleDecrapifier tvShowEpisodeInfoFromString:file.title];
    if (tvShowEpisodeInfo) {
        [self addTVShowEpisodeWithInfo:tvShowEpisodeInfo andFile:file];
        return;
    }

    // Go online and fetch info.

    // We don't care about keeping a reference to track the item during its life span
    // because we are a singleton
    MLMovieInfoGrabber *grabber = [[[MLMovieInfoGrabber alloc] init] autorelease];

    MLLog(@"Looking up for Movie '%@'", file.title);

#if HAVE_BLOCK
    [grabber lookUpForTitle:file.title andExecuteBlock:^(NSError *err){
        if (err) {
            [self errorWhenFetchingMetaDataForFile:file];
            return;
        }

        NSArray *results = grabber.results;
        if ([results count] > 0) {
            NSDictionary *result = [results objectAtIndex:0];
            file.artworkURL = [result objectForKey:@"artworkURL"];
            if (!file.artworkURL)
                [self computeThumbnailForFile:file];
            file.title = [result objectForKey:@"title"];
            file.shortSummary = [result objectForKey:@"shortSummary"];
            file.releaseYear = [result objectForKey:@"releaseYear"];
        } else
            [self noMetaDataInRemoteDBForFile:file];
        file.hasFetchedInfo = [NSNumber numberWithBool:YES];
    }];
#else
    grabber.userData = file;
    grabber.delegate = self;
    [grabber lookUpForTitle:file.title];
#endif
}

#pragma mark -
#pragma mark Adding file to the DB

- (void)addFilePath:(NSString *)filePath
{
    MLLog(@"Adding Path %@", filePath);

    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSString *title = [filePath lastPathComponent];
#if !TARGET_OS_IPHONE
    NSDate *openedDate = nil; // FIXME kMDItemLastUsedDate
    NSDate *modifiedDate = nil; // FIXME [result valueForAttribute:@"kMDItemFSContentChangeDate"];
#endif
    NSNumber *size = [attributes objectForKey:NSFileSize]; // FIXME [result valueForAttribute:@"kMDItemFSSize"];

    MLFile *file = [self createObjectForEntity:@"File"];
    file.url = [url absoluteString];

    // Yes, this is a negative number. VLCTime nicely display negative time
    // with "XX minutes remaining". And we are using this facility.

    NSNumber *no = [NSNumber numberWithBool:NO];
    NSNumber *yes = [NSNumber numberWithBool:YES];

    file.currentlyWatching = no;
    file.lastPosition = [NSNumber numberWithDouble:0];
    file.remainingTime = [NSNumber numberWithDouble:0];
    file.unread = yes;

#if !TARGET_OS_IPHONE
    if ([openedDate isGreaterThan:modifiedDate]) {
        file.playCount = [NSNumber numberWithDouble:1];
        file.unread = no;
    }
#endif

    file.title = [MLTitleDecrapifier decrapify:[title stringByDeletingPathExtension]];

    if ([size longLongValue] < 150000000) /* 150 MB */
        file.type = kMLFileTypeClip;
    else
        file.type = kMLFileTypeMovie;

    [self fetchMetaDataForFile:file];
}

- (void)addFilePaths:(NSArray *)filepaths
{
    NSUInteger count = [filepaths count];
    NSMutableArray *fetchPredicates = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *urlToObject = [NSMutableDictionary dictionaryWithCapacity:count];

    // Prepare a fetch request for all items
    for (NSString *path in filepaths) {
        NSURL *url = [NSURL fileURLWithPath:path];
        NSString *urlString = [url absoluteString];
        [fetchPredicates addObject:[NSPredicate predicateWithFormat:@"url == %@", urlString]];
        [urlToObject setObject:path forKey:urlString];

    }

    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];

    [request setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:fetchPredicates]];

    MLLog(@"Fetching");
    NSArray *dbResults = [[self managedObjectContext] executeFetchRequest:request error:nil];
    MLLog(@"Done");

    NSMutableArray *filePathsToAdd = [NSMutableArray arrayWithArray:filepaths];


    // Remove objects that are already in db.
    for (MLFile *dbResult in dbResults) {
        NSString *urlString = dbResult.url;
        [filePathsToAdd removeObject:[urlToObject objectForKey:urlString]];
    }

    // Add only the newly added items
    for (NSString* path in filePathsToAdd)
        [self addFilePath:path];
}


#pragma mark -
#pragma mark DB Updates

#if !HAVE_BLOCK
- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFetchUpdates:(NSArray *)updates
{
    NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLShow *show in results)
        [self fetchMetaDataForShow:show];
}
#endif

- (void)startUpdateDB
{
    // Remove no more present files
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (MLFile *file in results) {
        NSString *urlString = [file url];
        NSURL *fileURL = [NSURL URLWithString:urlString];
        BOOL exists = [fileManager fileExistsAtPath:[fileURL path]];
        if (!exists)
            NSLog(@"Marking - %@", [fileURL absoluteString]);
        file.isOnDisk = [NSNumber numberWithBool:exists];
    }

    // Get the file to parse
    request = [self fetchRequestForEntity:@"File"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && tracks.@count == 0"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLFile *file in results)
        [[MLFileParserQueue sharedFileParserQueue] addFile:file];

    // Get the thumbnails to compute
    request = [self fetchRequestForEntity:@"File"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && hasFetchedInfo == 1 && artworkURL == nil && computedThumbnail == nil"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLFile *file in results)
        [self computeThumbnailForFile:file];

    // Get to fetch meta data
    request = [self fetchRequestForEntity:@"File"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isOnDisk == YES && hasFetchedInfo == 0"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLFile *file in results)
        [self fetchMetaDataForFile:file];

    // Get to fetch show info
    request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"lastSyncDate == 0"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    for (MLShow *show in results)
        [self fetchMetaDataForShow:show];

    // Get updated TV Shows
    NSNumber *lastServerTime = [NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:kLastTVDBUpdateServerTime]];
#if HAVE_BLOCK
    [MLTVShowInfoGrabber fetchUpdatesSinceServerTime:lastServerTime andExecuteBlock:^(NSArray *updates){
        NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
        [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
        NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
        for (MLShow *show in results)
            [self fetchMetaDataForShow:show];
    }];
#else
    MLTVShowInfoGrabber *grabber = [[[MLTVShowInfoGrabber alloc] init] autorelease];
    grabber.delegate = self;
    [grabber fetchUpdatesSinceServerTime:lastServerTime];
#endif
    /* Update every hour - FIXME: Preferences key */
    [self performSelector:@selector(startUpdateDB) withObject:nil afterDelay:60 * 60];
}

- (void)libraryDidDisappear
{
    // Stop expansive work
    [[MLThumbnailerQueue sharedThumbnailerQueue] stop];
}

- (void)libraryDidAppear
{
    // Resume our work
    [[MLThumbnailerQueue sharedThumbnailerQueue] resume];
}
@end
