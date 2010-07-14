//
//  MLMovieInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol MLMovieInfoGrabberDelegate;

@interface MLMovieInfoGrabber : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_results;
    id<MLMovieInfoGrabberDelegate> _delegate;
#if HAVE_BLOCK
    void (^_block)(NSError *);
#endif
}

@property (readwrite, assign) id<MLMovieInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;

- (void)lookUpForTitle:(NSString *)title;
#if HAVE_BLOCK
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)(NSError *))block;
#endif

@end

@protocol MLMovieInfoGrabberDelegate <NSObject>
@optional
- (void)movieInfoGrabber:(MLMovieInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)movieInfoGrabberDidFinishGrabbing:(MLMovieInfoGrabber *)grabber;
@end
