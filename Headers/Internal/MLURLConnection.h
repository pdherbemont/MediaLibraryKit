//
//  MLURLConnection.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MLURLConnectionDelegate;
@class MLURLConnection;
@interface MLURLConnection : NSObject {
    NSMutableData *_data;
    NSURLConnection *_connection;
    id<MLURLConnectionDelegate> _delegate;
    id _userObject;
#if HAVE_BLOCK
    void (^_block)(MLURLConnection *connection, NSError *error);
#endif
}

@property (readonly, retain) NSData *data;
@property (readwrite, retain) id userObject;
@property (readwrite, retain) id<MLURLConnectionDelegate> delegate;

#if HAVE_BLOCK
+ (id)runConnectionWithURL:(NSURL *)url andBlock:(void (^)(MLURLConnection *connection, NSError *error))block;
- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(MLURLConnection *connection, NSError *error))block;
#else
+ (id)runConnectionWithURL:(NSURL *)url delegate:(id<MLURLConnectionDelegate>)delegate userObject:(id)userObject;
- (void)loadURL:(NSURL *)url;
#endif
- (void)cancel;

@end


@protocol MLURLConnectionDelegate <NSObject>
- (void)urlConnection:(MLURLConnection *)connection didFinishWithError:(NSError *)error;
@end
