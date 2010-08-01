//
//  CXMLNode_Additions.h
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@interface NSXMLNode (MLAdditions)
- (NSString *)stringValueForXPath:(NSString *)string;
- (NSNumber *)numberValueForXPath:(NSString *)string;
@end
