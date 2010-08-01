//
//  MLFile.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MLShowEpisode;

extern NSString *kMLFileTypeMovie;
extern NSString *kMLFileTypeClip;
extern NSString *kMLFileTypeTVShowEpisode;

@interface MLFile :  NSManagedObject
{
}

+ (NSArray *)allFiles;

- (BOOL)isKindOfType:(NSString *)type;
- (BOOL)isMovie;
- (BOOL)isClip;
- (BOOL)isShowEpisode;

@property (nonatomic, retain) NSNumber * seasonNumber;
@property (nonatomic, retain) NSNumber * remainingTime;
@property (nonatomic, retain) NSString * releaseYear;
@property (nonatomic, retain) NSNumber * lastPosition;
@property (nonatomic, retain) NSNumber * playCount;
@property (nonatomic, retain) NSString * artworkURL;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * shortSummary;
@property (nonatomic, retain) NSNumber * currentlyWatching;
@property (nonatomic, retain) NSNumber * episodeNumber;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) NSNumber * hasFetchedInfo;
@property (nonatomic, retain) NSNumber * noOnlineMetaData;
@property (nonatomic, retain) NSData * computedThumbnail;
@property (nonatomic, retain) MLShowEpisode * showEpisode;
@property (nonatomic, retain) NSSet* labels;
@property (nonatomic, retain) NSNumber* isOnDisk;

@end


@interface MLFile (CoreDataGeneratedAccessors)
- (void)addLabelsObject:(NSManagedObject *)value;
- (void)removeLabelsObject:(NSManagedObject *)value;
- (void)addLabels:(NSSet *)value;
- (void)removeLabels:(NSSet *)value;

@end

