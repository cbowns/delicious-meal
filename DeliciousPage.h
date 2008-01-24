//
//  DeliciousPage.h
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/21/07.
//  Copyright 2007 Jaded Bits Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DeliciousPage : NSObject {
	int bookmarkCount;
    NSURL *pageUrl;
    NSString *hashValue;
}

- (int)bookmarkCount;
- (void)setBookmarkCount:(int)aBookmarkCount;

- (NSURL *)pageUrl;
- (void)setPageUrl:(NSURL *)aPageUrl;
// - (void)setPageUrl:(NSString *)aPageUrl;


- (NSString *)hashValue;
- (void)setHashValue:(NSString *)aHashValue;

@end
