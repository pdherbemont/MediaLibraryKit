//
//  MLTVShowInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol MLTVShowInfoGrabberDelegate;

@interface MLTVShowInfoGrabber : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_results;
    void (^_block)();
    id<MLTVShowInfoGrabberDelegate> _delegate;
#if !HAVE_BLOCK
    id _userData;
#endif
}

@property (readwrite, assign) id<MLTVShowInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;
#if !HAVE_BLOCK
@property (readwrite, retain) id userData;
#endif

- (void)lookUpForTitle:(NSString *)title;

#if HAVE_BLOCK
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)())block;
#endif


#if HAVE_BLOCK
+ (void)fetchServerTimeAndExecuteBlock:(void (^)(NSNumber *))block;
+ (void)fetchUpdatesSinceServerTime:(NSNumber *)serverTime andExecuteBlock:(void (^)(NSArray *))block;
#else
- (void)fetchUpdatesSinceServerTime:(NSNumber *)serverTime;
- (void)fetchServerTime;
+ (NSNumber *)serverTime;
#endif
@end


@protocol MLTVShowInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error;
@required
- (void)tvShowInfoGrabberDidFinishGrabbing:(MLTVShowInfoGrabber *)grabber;
- (void)tvShowInfoGrabberDidFetchServerTime:(MLTVShowInfoGrabber *)grabber;
- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFetchUpdates:(NSArray *)updates;
@end
