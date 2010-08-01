//
//  MLTitleDecrapifier.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@interface MLTitleDecrapifier : NSObject
{
}
+ (NSString *)decrapify:(NSString *)string;
+ (BOOL)isTVShowEpisodeTitle:(NSString *)string;

+ (NSDictionary *)tvShowEpisodeInfoFromString:(NSString *)string;
@end
