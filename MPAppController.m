//
//  MPAppController.m
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/23/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
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
	// [self probePort:55000];
	[self getRootDeliciousLink];
	[progressSpinner startAnimation:self];
	/*
		TODO Here's the plan:
		1. retrieve the root level bookmark
		
		2. get the hash value
		3. bookmark the hash value
		4. get the number of bookmarked users
		
		5. add a new DeliciousPage object to the array with those values
		lather rinse repeat ad infinitum, stop when users = 1 (== me?)
	*/
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
		deliciousData = [[NSMutableData data] retain];
	else
	{
		NSLog(@"Unable to get port status: failed to initiate connection");
		// [self callBackWithStatus: PORT_STATUS_ERROR];
	}
}

- (void)getRootDeliciousLink
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	NSURLRequest *request;

	request = [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"https://api.del.icio.us/v1/posts/get?&url=http://del.icio.us/", 80]]
	                                    cachePolicy: NSURLRequestReloadIgnoringCacheData
	                                timeoutInterval: 15.0];

	NSURLConnection *connection = [NSURLConnection connectionWithRequest: request
                                                                delegate: self];

	if (connection)
		deliciousData = [[NSMutableData data] retain];
	else
	{
		NSLog(@"Unable to connect!");
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
	[deliciousData setLength: 0];
}

- (void)connection:(NSURLConnection*)connection
    didReceiveData:(NSData*)data
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[deliciousData appendData: data];
}

- (void)connection:(NSURLConnection*)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
	/*
		TODO at this point, log the entire response. what the hell are they asking for? 401 auth? 403 try again?
	*/
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	if ( [challenge previousFailureCount] > 1) // || [challenge proposedCredential] != nil )
	{
		#ifdef NSLOG_DEBUG
		NSLog(@"%s: cancelling authentication challenge:", _cmd);
		NSLog(@"%s: [challenge previousFailureCount] > 1 == %@", _cmd, [challenge previousFailureCount] > 1 ? @"YES" : @"NO");
		// NSLog(@"%s: [challenge proposedCredential] != nil == %@", _cmd, [challenge proposedCredential] != nil ? @"YES" : @"NO");
		#endif
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		// [progressSpinner stopAnimation:self];
		// [deliciousData release];
		return;
	}
	
	
	if ( [challenge proposedCredential] != nil )
	{
		#ifdef NSLOG_DEBUG
		NSLog(@"%s [challenge proposedCredential] != nil == %@", _cmd, [challenge proposedCredential] != nil ? @"YES" : @"NO");
		NSLog(@"%s credential: user: %s, pass: %s", _cmd, [[challenge proposedCredential] user], [[challenge proposedCredential] password]);
		#endif
	}
	
	/*
		TODO didReceiveAuthenticationChallenge: remove hardcoded password
	*/
	NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:@"cipherswarm"
	                                                              password:@"e2ca7b52"
	                                                           persistence:NSURLCredentialPersistenceForSession];
	
	[[challenge sender] useCredential:loginCredential
	       forAuthenticationChallenge:challenge];
	
}


- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	NSLog(@"Unable to retrieve tags: connection failed (%@)", [error localizedDescription]);
	#endif
	// [self callBackWithStatus: PORT_STATUS_ERROR];
	[progressSpinner stopAnimation:self];
	[deliciousData release];
}


- (void)connectionDidFinishLoading: (NSURLConnection *) connection
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[progressSpinner stopAnimation:self];
	/*
		TODO where else should we send a stop? on error condition, right?
	*/
	NSXMLDocument *deliciousResult;
	deliciousResult = [[NSXMLDocument alloc] initWithData: deliciousData options: NSXMLDocumentTidyHTML error: nil];

	if (deliciousResult == nil)
	{
		NSLog(@"Unable to open page: failed to create xml document");
		// [self callBackWithStatus: PORT_STATUS_ERROR];
	}
	NSArray *nodes = [deliciousResult nodesForXPath: @"/posts/post/tag/" error: nil];
	if ([nodes count] != 1)
	{
		NSLog(@"Unable to get tags: invalid (outdated) XPath expression");
			// [self callBackWithStatus: PORT_STATUS_ERROR];
	}
	// NSString *portStatus = [[[[nodes objectAtIndex: 0] stringValue] stringByTrimmingCharactersInSet:
	// [[NSCharacterSet letterCharacterSet] invertedSet]] lowercaseString];

	NSLog(@"%s: tags: %s", _cmd, [[nodes objectAtIndex: 0] stringValue]);

/*	if ([portStatus isEqualToString: @"open"])
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
		// [self callBackWithStatus: PORT_STATUS_ERROR];
		NSLog(@"Unable to get port status: unknown port state");
	}*/
	
	[deliciousData release];
}


@end
