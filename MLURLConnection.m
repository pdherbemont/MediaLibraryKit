//
//  MLURLConnection.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MLURLConnection.h"

#if HAVE_BLOCK
@interface MLURLConnection ()

- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(VLCURLConnection *connection, NSError *error))block;

@end
#endif

@implementation MLURLConnection
@synthesize data=_data;
@synthesize delegate=_delegate;
@synthesize userObject=_userObject;

#if HAVE_BLOCK
+ (id)runConnectionWithURL:(NSURL *)url andBlock:(void (^)(VLCURLConnection *connection, NSError *error))block
{
    id obj = [[[[self class] alloc] init] autorelease];
    [obj loadURL:url andPerformBlock:block];
    return obj;
}
#else
+ (id)runConnectionWithURL:(NSURL *)url delegate:(id<MLURLConnectionDelegate>)delegate userObject:(id)userObject
{
    MLURLConnection *obj = [[[[self class] alloc] init] autorelease];
    obj.delegate = delegate;
    obj.userObject = userObject;
    [obj loadURL:url];
    return obj;
}
#endif
- (void)dealloc
{
#if HAVE_BLOCK
    if (_block)
        Block_release(_block);
#endif
    [_userObject release];
    [_connection release];
    [_data release];
    [super dealloc];
}

- (void)loadURL:(NSURL *)url
{
    [_data release];
    _data = [[NSMutableData alloc] init];

    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15] autorelease];
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];

    // Make sure we are around during the request
    [self retain];
}

#if HAVE_BLOCK
- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(MLURLConnection *connection, NSError *error))block
{
    if (_block)
        Block_release(_block);
    _block = block ? Block_copy(block) : NULL;

    [self loadURL:url];
}
#endif


- (void)cancel
{
    [_connection cancel];
    [_connection release];
    _connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#if HAVE_BLOCK
    // Call the call back with the error.
    _block(self, error);

    // Release the eventual block. This prevents ref cycle.
    if (_block) {
        Block_release(_block);
        _block = NULL;
    }
#endif
    [_delegate urlConnection:self didFinishWithError:error];

    // This balances the -retain in -load
    [self autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#if HAVE_BLOCK
    // Call the call back with the data.
    _block(self, nil);

    // Release the eventual block. This prevents ref cycle.
    if (_block) {
        Block_release(_block);
        _block = NULL;
    }
#endif

    [_delegate urlConnection:self didFinishWithError:nil];

    // This balances the -retain in -load
    [self autorelease];
}

@end
