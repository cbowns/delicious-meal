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
	}
}

- (void)getRootDeliciousLink
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	
	
	// NSString *request = @"tags/get";
	NSString *request = @"posts/get?&url=http://del.icio.us/";
	
	NSString *username = @"cipherswarm";
	NSString *password = @"e2ca7b52";
	NSString *agent = @"(DeliciousMeal/0.01 (Mac OS X; http://cbowns.com/contact)";
	NSString *header = @"User-Agent";
	
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];
	
	NSURL *requestURL = [NSURL URLWithString:[apiPath stringByAppendingString:request]];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL: requestURL];

	[URLRequest setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	[URLRequest setTimeoutInterval: 15.0];
	
	[URLRequest setValue:agent forHTTPHeaderField:header];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest: URLRequest
	                                                            delegate: self];
	
	
	if (connection)
	{
		deliciousData = [[NSMutableData data] retain];
	}
	else
	{
		NSLog(@"Unable to connect!");
	}
}


#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSURLResponse*)response
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	[deliciousData setLength: 0];

	// if you want to view the headers, uncomment here:
	// NSDictionary *allHeaderFields = [httpResponse allHeaderFields];
	// NSEnumerator *enumerator = [allHeaderFields keyEnumerator];
	// id key;
	// while ((key = [enumerator nextObject])) {
		// NSLog(@"%@ : %@", key, [allHeaderFields objectForKey:key]);
	// }
	
	NSLog(@"%s statusCode: %i", _cmd, [httpResponse statusCode]);
	if ([httpResponse statusCode] == 401) {
		NSLog(@"%s 401", _cmd);
	/*
		TODO What to do now? Auth challenge, and whatever we handed them failed...
	*/
	}
	if ([httpResponse statusCode] == 503) {
	// we've been throttled
		NSLog(@"%s 503", _cmd);
/*
		TODO back off, try again in a few seconds...?
*/
	}
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
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	if ( [challenge previousFailureCount] > 1) // || [challenge proposedCredential] != nil )
	{
		#ifdef NSLOG_DEBUG
		NSLog(@"%s: cancelling authentication challenge:", _cmd);
		NSLog(@"%s: [challenge previousFailureCount] > 1 == %@", _cmd, [challenge previousFailureCount] > 1 ? @"YES" : @"NO");
		#endif
		[[challenge sender] cancelAuthenticationChallenge:challenge];
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
		TODO didReceiveAuthenticationChallenge: remove hardcoded password: prompt for username and pass instead
	*/
	NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:@"cipherswarm"
	                                                              password:@"e2ca7b52"
	                                                           persistence:NSURLCredentialPersistencePermanent];
	
	[[challenge sender] useCredential:loginCredential
	       forAuthenticationChallenge:challenge];
	
}


- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	NSLog(@"Unable to retrieve data: connection failed (%@)", [error localizedDescription]);
	#endif
	[progressSpinner stopAnimation:self];
	[deliciousData release];
}


- (void)connectionDidFinishLoading: (NSURLConnection *) connection
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[progressSpinner stopAnimation:self];

	NSXMLDocument *deliciousResult;
	deliciousResult = [[NSXMLDocument alloc] initWithData: deliciousData options: NSXMLDocumentTidyHTML error: nil];
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s %@", _cmd, deliciousResult);
	#endif
	
	if (deliciousResult == nil)
	{
		NSLog(@"Unable to open page: failed to create xml document");
	}
	NSArray *nodes = [deliciousResult nodesForXPath: @"/posts/post" error: nil];
	if ([nodes count] != 1)
	{
		NSLog(@"Unable to get tags: invalid (outdated) XPath expression");
	}
	else
	{
		NSXMLElement *element = [nodes objectAtIndex:0];
		NSLog(@"%s %@", _cmd, element);
		NSLog(@"%s bookmarked by %@ other people", _cmd, [[element attributeForName:@"others"] objectValue]);
		
		NSLog(@"%s hash: %@", _cmd, [[element attributeForName:@"hash"] objectValue]);
		
		// debug code.
		// unsigned int objectCount = [nodes count], index;
		// for(index = 0; index < objectCount; index++ )
		// {
			// id	object         = [nodes objectAtIndex:index];
			// NSLog(@"%s %@", _cmd, object);
		// }
	}
	
	
	[deliciousData release];
}


@end
