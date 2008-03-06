//
//  MPAppController.h
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/23/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPAppController : NSObject {
	NSMutableArray *pages;
	IBOutlet NSButton *startButton;
	IBOutlet NSTableView *tableView;
	IBOutlet NSProgressIndicator *progressSpinner;
	bool connectionIsComplete;
	NSMutableData *deliciousData;
	// NSData *deliciousData;
}

- (IBAction)getNextIteration:(id)sender;

// - (void)getRootDeliciousLink;

// #warning Implement the following methods:
// #warning spinner progress as private method to call for turning on and off

// #warning Implement table view methods as well: in place of NSArrayController or non?
// Table view data source methods
// - (int)numberOfRowsInTableView:(NSTableView *)aTableView;
// - (id)tableView:(NSTableView*)aTableView
// objectValueForTableColumn:(NSTableColumn*)aTableColumn
//             row:(int)row;


@end
