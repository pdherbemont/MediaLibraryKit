//
//  CXMLNode_Additions.m
//  MobileMediaLibraryKit
//
//  Created by Pierre d'Herbemont on 7/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSXMLNode_Additions.h"


@implementation NSXMLNode (MLAdditions)

- (NSString *)stringValueForXPath:(NSString *)string
{
    NSArray *nodes = [self nodesForXPath:string error:nil];
    if ([nodes count] == 0)
        return nil;
    return [[nodes objectAtIndex:0] stringValue];
}

- (NSNumber *)numberValueForXPath:(NSString *)string
{
    NSArray *nodes = [self nodesForXPath:string error:nil];
    if ([nodes count] == 0)
        return nil;
    NSScanner *scanner = [NSScanner scannerWithString:[[nodes objectAtIndex:0] stringValue]];
    NSInteger i;
    if ([scanner scanInteger:&i])
        return [NSNumber numberWithInteger:i];
    return nil;
}

@end
