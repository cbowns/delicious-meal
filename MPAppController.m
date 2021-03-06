//
//  MPAppController.m
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/23/07.
//  Copyright 2007-2008 Mechanical Pants Software. All rights reserved.
//

#import "MPAppController.h"

// comment out nslog_debug definition to turn off logging
// ifndef NSLOG_DEBUG
// define NSLOG_DEBUG
// endif

@implementation MPAppController

/*
TODO anything to do on awakeFromNib?
*/


- (id) init
{
	if(self = [super init])
	{
		// do we need to do anything here? It's unclear.
	}
	pages = [[NSMutableArray alloc] init];
	deliciousData = nil;
	connectionIsComplete = true;
	getAllIterations = false;
	return self;
}


- (IBAction)getAllIterations:(id)sender
{
	getAllIterations = true;
	[self getNextIteration:sender];
}

- (IBAction)stopIteration:(id)sender
{
	getAllIterations = false;
}

- (IBAction)getNextIteration:(id)sender
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	[progressSpinner startAnimation:self];
	
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
	
	// present an error if we need to? How can we tell?
}


- (void)bookmarkPage:(NSString *)url
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	
	#warning You need to provide a delicious username and password here.
	NSString *username = @"";
	NSString *password = @"";
	NSString *agent = @"(DeliciousMeal/0.01a1 (Mac OS X; http://cbowns.com/contact)";
	NSString *header = @"User-Agent";
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];

	NSNumber *count = [NSNumber numberWithInt:[pages count]];
	NSString *description = [NSString stringWithFormat:@"description=\"deliciouswilleatitself%@\"", count, nil];
	
	NSString *tags = @"tags=\"deliciousapp\"";

	NSString *request = @"posts/add?";
	request = [request stringByAppendingString:description];
	request = [request stringByAppendingString:[@"&" stringByAppendingString:tags]];
	request = [request stringByAppendingString:[@"&url=" stringByAppendingString:url]];
	request = [apiPath stringByAppendingString:request];
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s request: %@", _cmd, request);
	#endif
	request = [request stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding];
	#ifdef NSLOG_DEBUG
	NSLog(@"%s request after escaping: %@", _cmd, request);
	#endif
	
	#ifdef NSLOG_DEBUG
	NSURL *requestURL = [NSURL URLWithString:request/*[apiPath stringByAppendingString:request]*/];
	// NSURL *requestURL = [[NSURL alloc] initWithString:request];
	if(requestURL == nil)
	{
		NSLog(@"%s bad URL, is nil.", _cmd);
	}
	else
	{
		// NSLog(@"%s requestURL: %@", _cmd, requestURL);
	}
	#endif
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:request]];
	// NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request]];

	[URLRequest setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	[URLRequest setTimeoutInterval: 15.0];

	[URLRequest setValue:agent forHTTPHeaderField:header];
	
	#ifdef NSLOG_DEBUG
	// NSLog(@"%s %@", _cmd, URLRequest);
	#endif
	NSURLResponse *response;
	NSError *error;
	// this is a synchronous call.
	NSData *bookmarkData = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
	// NSURLConnection *connection = [NSURLConnection connectionWithRequest: URLRequest
	// delegate: self];
	#ifdef NSLOG_DEBUG
	NSLog(@"%s response: %@", _cmd, response);
	NSLog(@"%s error: %@", _cmd, error);
	#endif

	[bookmarkData retain];
	[URLRequest release];
	// NSLog(@"%s bookmarkData: %@", _cmd, bookmarkData);
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
		[progressSpinner stopAnimation:self];
	}
	NSArray *nodes = [deliciousResult nodesForXPath: @"/result" error: nil];
	if ([nodes count] != 1)
	{
		NSLog(@"Unable to get result code: invalid (outdated) XPath expression");
		[progressSpinner stopAnimation:self];
	}
	else
	{
		NSXMLElement *element = (NSXMLElement *)[nodes objectAtIndex:0];
		#ifdef NSLOG_DEBUG
		NSLog(@"%s %@", _cmd, element);
		#endif
		NSString *result = (NSString *)[[element attributeForName:@"code"] objectValue];
		if( ![result isEqualToString: @"done"])
		{
			NSLog(@"%s EPIC FAIL:", _cmd);
			NSLog(@"%s code: %@", _cmd, [[element attributeForName:@"code"] objectValue]);
			[progressSpinner stopAnimation:self];
		}
		else
		{
			// We now need to retrieve data from del.icio.us on the page we just bookmarked. # of bookmarking users, etc.
			// add those attributes to a deliciousPage object and return it.
			[self getDeliciousInfoForUrl:url];
			//We go asynchronous from here.
		}
	}
	
	// Release my objects.
	
	if (deliciousResult != nil) //It may be if things earlier didn't work out for us.
	{
		[deliciousResult release];
		deliciousResult = nil;
	}
	[bookmarkData release];
	bookmarkData = nil;
}

- (void)getDeliciousInfoForUrl:(NSString *)url
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	
	#warning You need to provide a delicious username and password here.
	NSString *username = @"";
	NSString *password = @"";
	NSString *agent = @"(DeliciousMeal/0.01 (Mac OS X; http://cbowns.com/contact)";
	NSString *header = @"User-Agent";
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];
		
	NSString *request = @"posts/get?";
	request = [request stringByAppendingString:[@"url=" stringByAppendingString:url]];
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s request: %@", _cmd, request);
	#endif
	
	NSURL *requestURL = [NSURL URLWithString:[apiPath stringByAppendingString:request]];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL: requestURL];

	[URLRequest setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	[URLRequest setTimeoutInterval: 15.0];
	
	[URLRequest setValue:agent forHTTPHeaderField:header];

	// this is an asynchronous call.
	NSURLConnection *connection = [NSURLConnection connectionWithRequest: URLRequest
	                                                            delegate: self];
	
	connectionIsComplete = false;
	
	if (connection)
	{
		deliciousData = [[NSMutableData data] retain];
	}
	else
	{
		NSLog(@"%s Unable to connect!", _cmd);
		/*
			TODO see the error object for more information?
		*/
		[progressSpinner stopAnimation:self];
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
		
		NSString *hashString = [[element attributeForName:@"hash"] stringValue];
		NSLog(@"%s hashString: \"%@\" retain count: %i", _cmd, hashString, [hashString retainCount]);
		
		
		DeliciousPage *page = [[DeliciousPage alloc] initWithBookmarkCount:[[[element attributeForName:@"others"] stringValue] intValue]
		                                                         hashValue:hashString];
		
		NSLog(@"%s page's hashValue: %@; bookmarkCount: %i", _cmd, [page hashValue], [page bookmarkCount]);
		
		[pages addObject:page]; // this sends a retain, so release the page.
		[page release];
		page = nil;
		
		// Reload the tableView…?
		[tableView reloadData];
		
		
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
	#warning You need to provide a delicious username and password here.
	NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:@""
	                                                              password:@""
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
	connectionIsComplete = true;
	// [deliciousData release];
}


- (void)connectionDidFinishLoading: (NSURLConnection *) connection
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif
	
	connectionIsComplete = true;
	[self processConnectionResult];
	
	if ( getAllIterations )
	{
		// set a timer to fire in 5 seconds on getNextIteration
		NSDate *sleepDate = [[NSDate alloc] initWithTimeIntervalSinceNow:3.0];
		[NSThread sleepUntilDate:sleepDate];
		[sleepDate release];
		[self getNextIteration:nil];
	}
	
	[progressSpinner stopAnimation:self];
}

#pragma mark -
#pragma mark Table View Source Methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [pages count];
}


- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)row
{
	#ifdef NSLOG_DEBUG
	NSLog(@"%s tableRow: %i, column id: %@", _cmd, row, [aTableColumn identifier]);
	#endif	
	if ( [[aTableColumn identifier] isEqualToString:@"hashValue"])
	{
		#ifdef NSLOG_DEBUG
		NSLog(@"%s getting hashValue", _cmd);
		#endif
		return [[pages objectAtIndex:row] hashValue];
	}
	else if ( [[aTableColumn identifier] isEqualToString:@"bookmarkCount"])
	{
		#ifdef NSLOG_DEBUG
		NSLog(@"%s getting bookmarkCount", _cmd);
		#endif
		return [NSNumber numberWithInt:[[pages objectAtIndex:row] bookmarkCount]];
	}
	return nil;
}


@end
