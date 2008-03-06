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
TODO anything to do on awakeFromNib?
*/


- (id) init
{
	if(self = [super init])
	{
		
	}
	connectionIsComplete = false;
	return self;
}


- (IBAction)getNextIteration:(id)sender
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[progressSpinner startAnimation:self];
	connectionIsComplete = false;
	
	// look in our pages array: if there's no value, we're bookmarking http://del.icio.us
	// else, we're bookmarking http://del.icio.us/url/<hash value>
	
	NSString *pageToBookmark;
	
	if ([pages count] == 0)
	{
		pageToBookmark = @"http://del.icio.us/";
	}
	else
	{
		DeliciousPage *lastPage = [pages lastObject];
		pageToBookmark = [@"http://del.icio.us/url/" stringByAppendingString:[lastPage hashValue]];
	}
	
	[self bookmarkPage:pageToBookmark];
	
	// now get some info on the page
	[self getDeliciousInfoForUrl:pageToBookmark];
	int i;
	while (!connectionIsComplete) { i = 0; } //  busy wait for this to finish.
	/*
		TODO don't busy wait here. go synchronous on the call?
	*/
	
	[self processConnectionResult]; // this puts the new data into the pages array.
	
	// [self getDeliciousLinkForHashValue:@""];
	
	
	[progressSpinner stopAnimation:self];
	
}


- (void)bookmarkPage:(NSString *)url
{
	NSString *username = @"cipherswarm";
	NSString *password = @"e2ca7b52";
	NSString *agent = @"(DeliciousMeal/0.01 (Mac OS X; http://cbowns.com/contact)";
	NSString *header = @"User-Agent";
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];
	
	int count = [pages count];
	NSString *description = [[@"description=\"deliciouswilleatitself: number" stringByAppendingString:count] stringByAppendingString:@"\""];
	NSString *tags = @"tags=\"deliciousapp\"";
	
	NSString *request = @"posts/add?";
	request = [request stringByAppendingString:description];
	request = [request stringByAppendingString:[@"&" stringByAppendingString:tags]];
	request = [request stringByAppendingString:[@"&url=" stringByAppendingString:url]];
	
	
	NSURL *requestURL = [NSURL URLWithString:[apiPath stringByAppendingString:request]];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL: requestURL];

	[URLRequest setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	[URLRequest setTimeoutInterval: 15.0];
	
	[URLRequest setValue:agent forHTTPHeaderField:header];

	NSURLResponse *response;
	NSError *error;
	// this is a synchronous call.
	NSData bookmarkData = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:*response error:*error];
	// NSURLConnection *connection = [NSURLConnection connectionWithRequest: URLRequest
	                                                            // delegate: self];
	
	[bookmarkData retain];
	// we now have data.
	
	// make sure it's a valid response.
	
	NSXMLDocument *deliciousResult;
	deliciousResult = [[NSXMLDocument alloc] initWithData: bookmarkData options: NSXMLDocumentTidyHTML error: nil];
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s %@", _cmd, deliciousResult);
	#endif
	
	if (deliciousResult == nil)
	{
		NSLog(@"Unable to open page: failed to create xml document");
	}
	NSArray *nodes = [deliciousResult nodesForXPath: @"/result" error: nil];
	if ([nodes count] != 1)
	{
		NSLog(@"Unable to get result code: invalid (outdated) XPath expression");
	}
	else
	{
		NSXMLElement *element = [nodes objectAtIndex:0];
		#ifdef NSLOG_DEBUG
		NSLog(@"%s %@", _cmd, element);
		#endif
		if([[element attributeForName:@"code"] objectValue] != "done")
		{
			NSLog(@"%s EPIC FAIL:", _cmd);
			NSLog(@"%s code: %@", _cmd, [[element attributeForName:@"code"] objectValue]);
		}
		else
		{
			//assuming success. cooool.
		}
	}
	[deliciousResult release];
	[bookmarkData release];
	}


- (void)getDeliciousInfoForUrl(NSString *)url
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
		request = @"posts/get?&url=";
	
	
	NSString *username = @"cipherswarm";
	NSString *password = @"e2ca7b52";
	NSString *agent = @"(DeliciousMeal/0.01 (Mac OS X; http://cbowns.com/contact)";
	NSString *header = @"User-Agent";
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];
		
	NSString *request = @"posts/get";
	request = [request stringByAppendingString:[@"url=" stringByAppendingString:url]];
		
	NSURL *requestURL = [NSURL URLWithString:[apiPath stringByAppendingString:request]];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL: requestURL];

	[URLRequest setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	[URLRequest setTimeoutInterval: 15.0];
	
	[URLRequest setValue:agent forHTTPHeaderField:header];

	NSURLResponse *response;
	NSError *error;
	// this is an asynchronous call.
	NSURLConnection *connection = [NSURLConnection connectionWithRequest: URLRequest
	                                                            delegate: self];
	
	
	if (connection)
	{
		deliciousData = [[NSMutableData data] retain];
	}
	else
	{
		NSLog(@"%s Unable to connect!", _cmd);
	}
}



- (void)processConnectionResult
{
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
		#ifdef NSLOG_DEBUG
		NSLog(@"%s %@", _cmd, element);
		NSLog(@"%s bookmarked by %@ other people", _cmd, [[element attributeForName:@"others"] objectValue]);
		NSLog(@"%s hash: %@", _cmd, [[element attributeForName:@"hash"] objectValue]);
		#endif
		
		DeliciousPage *page = [[DeliciousPage alloc] init];
		[page setHashValue: [[element attributeForName:@"hash"] objectValue]];
		[page setBookmarkCount: [[element attributeForName:@"others"] objectValue]];
		
		// add the page to the pages array?
		[pages insertObject: page atIndex:[pages count]]; // this sends a retain, so release the page.
		[page release];
		
		// debug code.
		// unsigned int objectCount = [nodes count], index;
		// for(index = 0; index < objectCount; index++ )
		// {
			// id	object         = [nodes objectAtIndex:index];
			// NSLog(@"%s %@", _cmd, object);
		// }
	}
	[deliciousResult release];
	[deliciousData release];
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
	NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:@"cswarm1"
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
	// [progressSpinner stopAnimation:self];
	connectionIsComplete = true;
	// [deliciousData release];
}


- (void)connectionDidFinishLoading: (NSURLConnection *) connection
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	// [progressSpinner stopAnimation:self];
	
	/*
		TODO call back to a processResults method here
	*/
	connectionIsComplete = true;
	// [self processConnectionData];
}


@end
