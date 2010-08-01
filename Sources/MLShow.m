//
//  MLShow.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLShow.h"
#import "MLMediaLibrary.h"


@implementation MLShow

+ (NSArray *)allShows
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];

    NSArray *shows = [moc executeFetchRequest:request error:nil];
	[request release];

    return shows;
}

+ (MLShow *)showWithName:(NSString *)name
{
    NSFetchRequest *request = [[MLMediaLibrary sharedMediaLibrary] fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];

    NSArray *dbResults = [[[MLMediaLibrary sharedMediaLibrary] managedObjectContext] executeFetchRequest:request error:nil];
    NSAssert(dbResults, @"Can't execute fetch request");

    if ([dbResults count] <= 0)
        return nil;

    return [dbResults objectAtIndex:0];
}


@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic artworkURL;
@dynamic name;
@dynamic lastSyncDate;
@dynamic releaseYear;
@dynamic episodes;
@dynamic unreadEpisodes;

//- (NSSet *)unreadEpisodes
//{
//    NSSet *episodes = [self episodes];
//    NSMutableSet *set = [NSMutableSet set];
//    for(id episode in set) {
//        NSSet *files = [episode valueForKey:@"files"];
//        for(id file in files) {
//            if ([[file valueForKey:@"unread"] boolValue]) {
//                [set addObject:episode];
//                break;
//            }
//        }
//    }
//    return set;
//}
@end
