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
}

@property (readwrite, assign) id<MLTVShowInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;

- (void)lookUpForTitle:(NSString *)title;

#if HAVE_BLOCK
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)())block;
#endif

+ (void)fetchServerTimeAndExecuteBlock:(void (^)(NSNumber *))block;
+ (void)fetchUpdatesSinceServerTime:(NSNumber *)serverTime andExecuteBlock:(void (^)(NSArray *))block;
@end


@protocol MLTVShowInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowInfoGrabber:(MLTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)tvShowInfoGrabberDidFinishGrabbing:(MLTVShowInfoGrabber *)grabber;
@end
