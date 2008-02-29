//
//  MPAppController.m
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/23/07.
//  Copyright 2007 Jaded Bits Software. All rights reserved.
//

#import "MPAppController.h"

// comment out nslog_debug definition to turn off logging
#ifndef NSLOG_DEBUG
#define NSLOG_DEBUG
#endif

@implementation MPAppController

/*
TODO anything on awakeFromNib?
*/

- (id) init
{
	if(self = [super init])
	{
		
	}
	return self;
}

- (IBAction)startDownload:(id)sender
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[self probePort:55000];
	[progressSpinner startAnimation:self];
}



- (void) probePort: (int) portNumber
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	NSURLRequest *portProbeRequest;

	portProbeRequest = [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"https://www.grc.com/x/portprobe=%d", portNumber]]
	                                    cachePolicy: NSURLRequestReloadIgnoringCacheData
	                                timeoutInterval: 15.0];

	NSURLConnection *portProbeConnection = [NSURLConnection connectionWithRequest: portProbeRequest
	                                                                     delegate: self];

	if (portProbeConnection)
		portProbeData = [[NSMutableData data] retain];
	else
	{
		NSLog(@"Unable to get port status: failed to initiate connection");
		// [self callBackWithStatus: PORT_STATUS_ERROR];
	}
}


#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSURLResponse*)response
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[portProbeData setLength: 0];
}

- (void)connection:(NSURLConnection*)connection
    didReceiveData:(NSData*)data
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[portProbeData appendData: data];
}

- (void)connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	NSLog(@"Unable to get port status: connection failed (%@)", [error localizedDescription]);
	// [self callBackWithStatus: PORT_STATUS_ERROR];
	[portProbeData release];
}

- (void)connectionDidFinishLoading: (NSURLConnection *) connection
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[progressSpinner stopAnimation:self];
	NSXMLDocument *shieldsUpProbe;
	shieldsUpProbe = [[NSXMLDocument alloc] initWithData: portProbeData options: NSXMLDocumentTidyHTML error: nil];

	if (shieldsUpProbe == nil)
	{
		NSLog(@"Unable to get port status: failed to create xml document");
		// [self callBackWithStatus: PORT_STATUS_ERROR];
	}
	else
	{
		NSArray *nodes = [shieldsUpProbe nodesForXPath: @"/html/body/center/table[3]/tr/td[2]" error: nil];
		if ([nodes count] != 1)
		{
			NSLog(@"Unable to get port status: invalid (outdated) XPath expression");
			// [self callBackWithStatus: PORT_STATUS_ERROR];
		}
		else
		{
			NSString *portStatus = [[[[nodes objectAtIndex: 0] stringValue] stringByTrimmingCharactersInSet:
			[[NSCharacterSet letterCharacterSet] invertedSet]] lowercaseString];

			if ([portStatus isEqualToString: @"open"])
			{
				// [self callBackWithStatus: PORT_STATUS_OPEN];
				NSLog(@"%s, Port is open.", _cmd);
			}
			else if ([portStatus isEqualToString: @"stealth"])
			{
				// [self callBackWithStatus: PORT_STATUS_STEALTH];
				NSLog(@"%s, Port is stealthed", _cmd);
			}	
			else if ([portStatus isEqualToString: @"closed"])
			{
				// [self callBackWithStatus: PORT_STATUS_CLOSED];
				NSLog(@"%s, Port is closed.", _cmd);
			}
			else {
				NSLog(@"Unable to get port status: unknown port state");
				// [self callBackWithStatus: PORT_STATUS_ERROR];
			}
		}
	}

	[portProbeData release];
}


@end
