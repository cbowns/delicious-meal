//
//  DeliciousPage.m
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/21/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
//

#import "DeliciousPage.h"


@implementation DeliciousPage

- (id) init
{
	if(self = [super init])
	{
		NSLog(@"%s", _cmd);
		// init the URL, set count to -1, and zero out the hash value
	}
	return self;
}

- (int)bookmarkCount
{
	return bookmarkCount;
}

- (void)setBookmarkCount:(int)aBookmarkCount
{
	bookmarkCount = aBookmarkCount;
}

- (NSURL *)pageUrl
{
	return pageUrl;
}

- (void)setPageUrl:(NSURL *)aPageUrl
{
/*
TODO There's no way this is the proper way to do the copy and retain counts. Fix it.
*/
	pageUrl = aPageUrl;
}

// - (void)setPageUrl:(NSString *)aPageUrl
// {
/*
TODO There's no way this is the proper way to do the copy and retain counts. Fix it.
*/
// 	pageUrl = aPageUrl;
// }

- (NSString *)hashValue
{
	return hashValue;
}

- (void)setHashValue:(NSString *)aHashValue
{
/*
TODO There's no way this is the proper way to do the copy and retain counts. Fix it.
*/
	hashValue = aHashValue;
}

@end
