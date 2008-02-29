//
//  main.m
//  DeliciousMeal
//
//  Created by Christopher Bowns on 12/21/07.
//  Copyright Mechanical Pants Software 2007-2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    if(
		getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")
	) {
		NSLog(@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!");
	}
    return NSApplicationMain(argc,  (const char **) argv);
}
