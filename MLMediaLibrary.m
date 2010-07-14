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
#import "File.h"
#import "Label.h"
#import "ShowEpisode.h"
#import "Show.h"


@interface MLMediaLibrary ()
- (NSManagedObjectContext *)managedObjectContext;
@end

@implementation MLMediaLibrary
+ (id)sharedMediaLibrary
{
    static id sharedMediaLibrary = nil;
    if (!sharedMediaLibrary) {
        sharedMediaLibrary = [[[self class] alloc] init];
        [sharedMediaLibrary startUpdateDB];
    }
    return sharedMediaLibrary;
}

- (NSFetchRequest *)fetchRequestForEntity:(NSString *)entity
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity inManagedObjectContext:moc];
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

- (NSURL *)databaseFolder
{
    // FIXME
    return  [NSURL fileURLWithPath:[@"~/Library" stringByExpandingTildeInPath]];
;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;

    NSString *databaseFolder = [[self databaseFolder] absoluteString];

    NSURL *url = [NSURL fileURLWithPath:[databaseFolder stringByAppendingPathComponent: @"MediaLibrary.sqlite"]];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSError *error;
    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
#if! TARGET_OS_IPHONE
        // FIXME: Deal with versioning
        NSInteger ret = NSRunAlertPanel(@"Error", @"The Media Library you have on your disk is not compatible with the one Lunettes can read. Do you want to create a new one?", @"No", @"Yes", nil);
        if (ret == NSOKButton)
            [NSApp terminate:nil];
        [fileManager removeItemAtURL:url error:nil];
        NSRunInformationalAlertPanel(@"Relaunch Lunettes now", @"We need to relaunch Lunettes to proceed", @"OK", nil, nil);
        [NSApp terminate:nil];
#else
        abort();
#endif
    }
    [coordinator release];
    [_managedObjectContext setUndoManager:nil];
    [_managedObjectContext addObserver:self forKeyPath:@"hasChanges" options:NSKeyValueObservingOptionInitial context:nil];
    return _managedObjectContext;
}

- (void)savePendingChanges
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
    [[self managedObjectContext] save:nil];

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

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
        [self performSelector:@selector(savePendingChanges) withObject:nil afterDelay:1.];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark Media Library: Path Watcher

- (void)addNewLabelWithName:(NSString *)name
{
    Label *label = [self createObjectForEntity:@"Label"];
    label.name = name;
}

/**
 * TV Show Episodes
 */
- (Show *)tvShowWithName:(NSString *)name
{
    NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name LIKE %@", name]];

    NSArray *dbResults = [[self managedObjectContext] executeFetchRequest:request error:nil];

    if ([dbResults count] <= 0)
        return nil;

    return [dbResults objectAtIndex:0];
}

- (ShowEpisode *)showEpisodeWithShow:(id)show episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber
{
    NSMutableSet *episodes = [show mutableSetValueForKey:@"episodes"];
    ShowEpisode *episode = nil;
    if (seasonNumber && episodeNumber) {
        for (ShowEpisode *episodeIter in episodes) {
            if ([episodeIter.seasonNumber intValue] == [seasonNumber intValue] &&
                [episodeIter.episodeNumber intValue] == [episodeNumber intValue]) {
                episode = episodeIter;
                break;
            }
        }
    }
    if (!episode) {
        episode = [self createObjectForEntity:@"ShowEpisode"];
        episode.episodeNumber = episodeNumber;
        episode.seasonNumber = seasonNumber;
        [episodes addObject:episode];
    }
    return episode;
}

- (ShowEpisode *)showEpisodeWithShowName:(NSString *)showName episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber wasInserted:(BOOL *)wasInserted show:(Show **)returnedShow
{
    Show *show = [self tvShowWithName:showName];
    *wasInserted = NO;
    if (!show) {
        *wasInserted = YES;
        show = [self createObjectForEntity:@"Show"];
        show.name = showName;
    }
    *returnedShow = show;
    return [self showEpisodeWithShow:show episodeNumber:episodeNumber seasonNumber:seasonNumber];
}

- (void)fetchMetaDataForShow:(Show *)show
{
    // First fetch the serverTime, so that we can update each entry.
#if HAVE_BLOCK
    [MLTVShowInfoGrabber fetchServerTimeAndExecuteBlock:^(NSNumber *serverDate) {

        [[NSUserDefaults standardUserDefaults] setInteger:[serverDate integerValue] forKey:kLastTVDBUpdateServerTime];

        // First fetch the Show ID
        VLCTVShowInfoGrabber *grabber = [[[VLCTVShowInfoGrabber alloc] init] autorelease];
        [grabber lookUpForTitle:show.name andExecuteBlock:^{
            NSArray *results = grabber.results;
            if ([results count] > 0) {
                NSDictionary *result = [results objectAtIndex:0];
                NSString *showId = [result objectForKey:@"id"];

                show.theTVDBID = showId;
                show.name = [result objectForKey:@"title"];
                show.shortSummary = [result objectForKey:@"shortSummary"];
                show.releaseYear = [result objectForKey:@"releaseYear"];

                // Fetch episode info
                VLCTVShowEpisodesInfoGrabber *grabber = [[[VLCTVShowEpisodesInfoGrabber alloc] init] autorelease];
                [grabber lookUpForShowID:showId andExecuteBlock:^{
                    NSArray *results = grabber.episodesResults;
                    [show setValue:[grabber.results objectForKey:@"serieArtworkURL"] forKey:@"artworkURL"];
                    for (id result in results) {
                        if ([[result objectForKey:@"serie"] boolValue]) {
                            continue;
                        }
                        ShowEpisode *showEpisode = [self showEpisodeWithShow:show episodeNumber:[result objectForKey:@"episodeNumber"] seasonNumber:[result objectForKey:@"seasonNumber"]];
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
    abort();
#endif
}

- (void)addTVShowEpisodeWithInfo:(NSDictionary *)tvShowEpisodeInfo andFile:(File *)file
{
    file.type = @"tvShowEpisode";

    NSNumber *seasonNumber = [tvShowEpisodeInfo objectForKey:@"season"];
    NSNumber *episodeNumber = [tvShowEpisodeInfo objectForKey:@"episode"];
    NSString *tvShowName = [tvShowEpisodeInfo objectForKey:@"tvShowName"];
    BOOL hasNoTvShow = NO;
    if (!tvShowName) {
        tvShowName = @"Untitled TV Show";
        hasNoTvShow = YES;
    }
    BOOL wasInserted = NO;
    Show *show = nil;
    ShowEpisode *episode = [self showEpisodeWithShowName:tvShowName episodeNumber:episodeNumber seasonNumber:seasonNumber wasInserted:&wasInserted show:&show];

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
}


/**
 * File auto detection
 */

- (void)fetchMetaDataForFile:(File *)file
{
    NSNumber *yes = [NSNumber numberWithBool:YES];

    NSDictionary *tvShowEpisodeInfo = [MLTitleDecrapifier tvShowEpisodeInfoFromString:file.title];
    if (tvShowEpisodeInfo) {
        [self addTVShowEpisodeWithInfo:tvShowEpisodeInfo andFile:file];
        file.hasFetchedInfo = yes;
        return;
    }

    // Go online and fetch info.
    MLMovieInfoGrabber *grabber = [[[MLMovieInfoGrabber alloc] init] autorelease];
#if HAVE_BLOCK
    [grabber lookUpForTitle:file.title andExecuteBlock:^(NSError *err){
        if (err)
            return;

        NSArray *results = grabber.results;
        if ([results count] > 0) {
            NSDictionary *result = [results objectAtIndex:0];
            file.artworkURL = [result objectForKey:@"artworkURL"];
            file.title = [result objectForKey:@"title"];
            file.shortSummary = [result objectForKey:@"shortSummary"];
            file.releaseYear = [result objectForKey:@"releaseYear"];
        }
        file.hasFetchedInfo = yes;
    }];
#else
    abort();
#endif
}

- (void)addFilePath:(NSString *)filePath
{
    NSString *url = [NSURL fileURLWithPath:filePath];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSString *title = [filePath lastPathComponent];
    NSDate *openedDate = nil; // FIXME kMDItemLastUsedDate
    NSDate *modifiedDate = nil; // FIXME [result valueForAttribute:@"kMDItemFSContentChangeDate"];
    NSNumber *size = [attributes objectForKey:NSFileSize]; // FIXME [result valueForAttribute:@"kMDItemFSSize"];

    File *file = [self createObjectForEntity:@"File"];
    file.url = [url description];

    // Yes, this is a negative number. VLCTime nicely display negative time
    // with "XX minutes remaining". And we are using this facility.

    NSNumber *no = [NSNumber numberWithBool:NO];
    NSNumber *yes = [NSNumber numberWithBool:YES];

    file.currentlyWatching = no;
    file.lastPosition = [NSNumber numberWithDouble:0];
    file.remainingTime = [NSNumber numberWithDouble:0];
    file.unread = yes;

    if ([openedDate isGreaterThan:modifiedDate]) {
        file.playCount = [NSNumber numberWithDouble:1];
        file.unread = no;
    }
    file.title = [MLTitleDecrapifier decrapify:[title stringByDeletingPathExtension]];

    if ([size longLongValue] < 150000000) /* 150 MB */
        file.type = @"clip";
    else
        file.type = @"movie";

    [self fetchMetaDataForFile:file];
}

- (void)addFilePaths:(NSArray *)filepaths
{
    NSUInteger count = [filepaths count];
    NSMutableArray *fetchPredicates = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *urlToObject = [NSMutableDictionary dictionaryWithCapacity:count];
    NSMutableArray *filePathsToAdd = [NSMutableArray arrayWithCapacity:count];

    // Prepare a fetch request for all items
    for (NSString *path in filepaths) {
        NSURL *url = [NSURL fileURLWithPath:path];
        NSString *urlDescription = [url description];
        [filePathsToAdd addObject:urlDescription];
        [fetchPredicates addObject:[NSPredicate predicateWithFormat:@"url == %@", urlDescription]];
        [urlToObject setObject:url forKey:urlDescription];
    }

    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];

    [request setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:fetchPredicates]];

    NSLog(@"Fetching");
    NSArray *dbResults = [[self managedObjectContext] executeFetchRequest:request error:nil];
    NSLog(@"Done");


    // Remove objects that are already in db.
    for (NSManagedObjectContext *dbResult in dbResults) {
        NSString *url = [dbResult valueForKey:@"url"];
        [filePathsToAdd removeObject:url];
    }

    // Add only the newly added items
    for (NSString* path in filePathsToAdd)
        [self addFilePath:path];
}

- (void)startUpdateDB
{
    // FIXME
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"hasFetchedInfo == 0"]];
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];

    for (File *file in results)
        [self fetchMetaDataForFile:file];

    request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"lastSyncDate == 0"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];

    for (Show *show in results)
        [self fetchMetaDataForShow:show];

#if HAVE_BLOCK
    NSInteger lastServerTime = [[NSUserDefaults standardUserDefaults] integerForKey:kLastTVDBUpdateServerTime];
    [MLTVShowInfoGrabber fetchUpdatesSinceServerTime:[NSNumber numberWithInteger:lastServerTime] andExecuteBlock:^(NSArray *updates){
        NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
        [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
        NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
        for (Show *show in results)
            [self fetchMetaDataForShow:show];
    }];
#endif
    /* Update every hour - FIXME: Preferences key */
    [self performSelector:@selector(startUpdateDB) withObject:nil afterDelay:60 * 60];
}
@end
