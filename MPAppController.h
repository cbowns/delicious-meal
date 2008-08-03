//
//  MPAppController.h
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/23/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DeliciousPage.h"

@interface MPAppController : NSObject {
	NSMutableArray *pages;
	IBOutlet NSButton *startButton;
	IBOutlet NSTableView *tableView;
	IBOutlet NSProgressIndicator *progressSpinner;
	bool connectionIsComplete;
	NSMutableData *deliciousData;
	bool getAllIterations;
}

- (IBAction)stopIteration:(id)sender;
- (IBAction)getAllIterations:(id)sender;
- (IBAction)getNextIteration:(id)sender;
- (void)bookmarkPage:(NSString *)url;
- (void)getDeliciousInfoForUrl:(NSString *)url;
- (void)processConnectionResult;


// #warning Implement table view methods as well: in place of NSArrayController or non?

#pragma mark -
#pragma mark Table View Data Methods


// Table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView*)aTableView
objectValueForTableColumn:(NSTableColumn*)aTableColumn
            row:(int)row;


@end
