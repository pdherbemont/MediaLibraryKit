//
//  MLTVShowEpisodesInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@class MLURLConnection;

@protocol MLTVShowEpisodesInfoGrabberDelegate;

@interface MLTVShowEpisodesInfoGrabber : NSObject {
    MLURLConnection *_connection;
    NSDictionary *_results;
    NSArray *_episodesResults;
    id<MLTVShowEpisodesInfoGrabberDelegate> _delegate;
    void (^_block)();
#if !HAVE_BLOCK
    id _userData;
#endif
}

@property (readwrite, assign) id<MLTVShowEpisodesInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *episodesResults;
@property (readonly, retain) NSDictionary *results;
#if !HAVE_BLOCK
@property (readwrite, retain) id userData;
#endif

- (void)lookUpForShowID:(NSString *)id;

#if HAVE_BLOCK
- (void)lookUpForShowID:(NSString *)id andExecuteBlock:(void (^)())block;
#endif

@end

@protocol MLTVShowEpisodesInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowEpisodesInfoGrabber:(MLTVShowEpisodesInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)tvShowEpisodesInfoGrabberDidFinishGrabbing:(MLTVShowEpisodesInfoGrabber *)grabber;
@end
