//
//  DeliciousPage.h
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/21/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DeliciousPage : NSObject {
	int bookmarkCount;
    NSURL *pageUrl;
    NSString *hashValue;
}

/*
	TODO add an initWithBookmarkCount: andHashValue: and pageUrl: method for ease of life.
		should it take a string or an NSURL? do we even NEED an NSURL here? no idea.
*/
- (id)initWithBookmarkCount:(int)aBookmarkCount hashValue:(NSString *)aHashValue;
- (int)bookmarkCount;
- (void)setBookmarkCount:(int)aBookmarkCount;

- (NSString *)hashValue;
- (void)setHashValue:(NSString *)aHashValue;

- (NSURL *)pageUrl;
- (void)setPageUrl:(NSURL *)aPageUrl;
/*
	TODO object conversion needed?
*/
// - (void)setPageUrl:(NSString *)aPageUrl;



@end
