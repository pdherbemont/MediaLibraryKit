//
//  MLMediaLibrary.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface MLMediaLibrary : NSObject {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel   *_managedObjectModel;

    BOOL _allowNetworkAccess;
}

+ (id)sharedMediaLibrary;

- (void)addFilePaths:(NSArray *)filepaths;
- (void)updateDatabase; // Removes missing files

// May be internal
- (NSFetchRequest *)fetchRequestForEntity:(NSString *)entity;
- (id)createObjectForEntity:(NSString *)entity;

- (void)save;
- (void)libraryDidDisappear;
- (void)libraryDidAppear;
@end
