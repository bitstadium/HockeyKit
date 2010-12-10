//
//  BWHockeyController.m
//
//  Created by Andreas Linde on 8/17/10.
//  Copyright 2010 Andreas Linde. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "BWHockeyController.h"
#import "NSString+URLEncoding.h"
#import "JSON.h"
#import <sys/sysctl.h>

@interface BWHockeyController ()
- (void)registerOnline;
- (void)wentOnline:(NSNotification *)note;
- (NSString *)_getDevicePlatform;
@end

@implementation BWHockeyController

@synthesize delegate;
@synthesize betaCheckUrl;
@synthesize betaDictionary;
@synthesize urlConnection;
@synthesize checkInProgress;

+ (BWHockeyController *)sharedHockeyController {
	static BWHockeyController *hockeyController = nil;
	
	if (hockeyController == nil) {
		hockeyController = [[BWHockeyController alloc] init];
	}
	
	return hockeyController;
}

- (id)init {
    self = [super init];
	if (self != nil) {
        self.betaCheckUrl = nil;
        self.betaDictionary = nil;
        checkInProgress = NO;
        dataFound = NO;
    }
	
    return self;
}


- (void)setBetaURL:(NSString *)url {
    [self setBetaURL:url delegate:nil];
}

- (void)setBetaURL:(NSString *)url delegate:(id <BWHockeyControllerDelegate>)object {
	self.delegate = object;
	self.betaCheckUrl = url;
	
	BOOL shouldCheckForUpdateOnLaunch = YES;
	
	if ([delegate respondsToSelector:@selector(shouldCheckForUpdateOnLaunch)]) {
		shouldCheckForUpdateOnLaunch = [delegate shouldCheckForUpdateOnLaunch];
	}
	
	if (shouldCheckForUpdateOnLaunch) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(checkForBetaUpdate)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];
	}
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidBecomeActiveNotification
												  object:nil];
    
	self.delegate = nil;
    
    [urlConnection cancel];
    self.urlConnection = nil;
    
	currentHockeyViewController = nil;
    [betaCheckUrl release];
	[betaDictionary release];
	[_receivedData release];


    [super dealloc];
}


#pragma mark -
#pragma mark Private


- (NSString *)_getDevicePlatform
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *answer = malloc(size);
	sysctlbyname("hw.machine", answer, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
	free(answer);
	return platform;
}


#pragma mark -
#pragma mark BetaUpdateUI

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal {
    return [[[BWHockeyViewController alloc] init:self
                                           modal:modal]
            autorelease];
}


- (void)showBetaUpdateView {
    UIViewController *parentViewController = nil;
    
    if ([[self delegate] respondsToSelector:@selector(viewControllerForHockeyController:)]) {
        parentViewController = [[self delegate] viewControllerForHockeyController:self];
    }
    
	if (parentViewController == nil && [UIWindow instancesRespondToSelector:@selector(rootViewController)]) {
        // if the rootViewController property (available >= iOS 4.0) of the main window is set, we present the modal view controller on top of the rootViewController
        parentViewController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
	}
    
    BWHockeyViewController *hockeyViewController = [self hockeyViewController:(nil == parentViewController) ? NO : YES];
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:hockeyViewController] autorelease];

    if (parentViewController) {
        if ([navController respondsToSelector:@selector(setModalTransitionStyle:)]) {
            navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        }
        
        [parentViewController presentModalViewController:navController animated:YES];        
    } else {
		// if not, we add a subview to the window. A bit hacky but should work in most circumstances.
		// Also, we don't get a nice animation for free, but hey, this is for beta not production users ;)
		[[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:navController.view];
		
		// we don't release the navController here, that'll be done when it's dismissed in [BWHockeyViewController -onAction:]
        [navController retain];
	}
}


- (void) showCheckForBetaAlert {
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"HockeyUpdateAvailable", @"Hockey", @"Update available")
                                                         message:NSLocalizedStringFromTable(@"HockeyUpdateAlertText", @"Hockey", @"Would you like to check out the new update? You can do this later on at any time in the In-App settings.")
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedStringFromTable(@"HockeyNo", @"Hockey", @"No")
                                               otherButtonTitles:NSLocalizedStringFromTable(@"HockeyYes", @"Hockey", @"Yes"), nil
                               ] autorelease];
    [alertView show];
}


#pragma mark -
#pragma mark RequestComments

- (void) checkForBetaUpdate {
    [self checkForBetaUpdate:nil];
}

- (void) checkForBetaUpdate:(BWHockeyViewController *)hockeyViewController {
    if (checkInProgress) return;
    
    checkInProgress = YES;
        
    currentHockeyViewController = hockeyViewController;
    
    NSNumber *hockeyAutoUpdateSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting];
    NSString *dateOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDateOfLastHockeyCheck];

    if (hockeyAutoUpdateSetting == nil) {
        hockeyAutoUpdateSetting = [NSNumber numberWithInt:BETA_UPDATE_CHECK_STARTUP];
        [[NSUserDefaults standardUserDefaults] setObject:hockeyAutoUpdateSetting forKey:kHockeyAutoUpdateSetting];            
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    BOOL showUpdateReminder = NO;
    if (self.delegate && [[self delegate] respondsToSelector:@selector(showUpdateReminder)]) {
        showUpdateReminder = [[self delegate] showUpdateReminder];
    }
    
    BOOL updatePending = NO;
    NSDictionary *dictionaryOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryOfLastHockeyCheck];
    if (showUpdateReminder && 
        dictionaryOfLastHockeyCheck && 
        [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] compare:[dictionaryOfLastHockeyCheck objectForKey:BETA_UPDATE_VERSION]] != NSOrderedSame) {
        updatePending = YES;
    }
    
    if (updatePending) {
        // we need to show an alert view any way, but in the meantime there could have been a new check, so whatever the user set
        // do another check, otherwise the update screen would show details of an already outdated version
    } else if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_MANUAL && currentHockeyViewController == nil) {
        self.betaDictionary = [dictionaryOfLastHockeyCheck mutableCopy];
        checkInProgress = NO;
        if (currentHockeyViewController != nil) {
            [currentHockeyViewController redrawTableView];
        }
        return;
    } else if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_DAILY && currentHockeyViewController == nil) {
        // is there an update available but not installed yet? shall we remind?
        
        // now check if the last check wasn't done today
        if (dateOfLastHockeyCheck != nil &&
            [dateOfLastHockeyCheck compare:[[[NSDate date] description] substringToIndex:10]] == NSOrderedSame) {

            self.betaDictionary = [dictionaryOfLastHockeyCheck mutableCopy];
            checkInProgress = NO;
            if (currentHockeyViewController != nil) {
                [currentHockeyViewController redrawTableView];
            }            
            return;
        }

    }
    
    self.betaDictionary = nil;
    
    NSString *parameter = nil;
    BOOL sendCurrentData = YES;
    
    if (self.delegate && [[self delegate] respondsToSelector:@selector(sendCurrentData)]) {
        sendCurrentData = [[self delegate] sendCurrentData];
    }
    
    if (sendCurrentData) {
        parameter = [NSString stringWithFormat:@"?bundleidentifier=%@&version=%@&ios=%@&platform=%@&udid=%@", 
                     [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     [[UIDevice currentDevice] systemVersion],
                     [self _getDevicePlatform],
                     [[UIDevice currentDevice] uniqueIdentifier]
                     ];
    } else {
        parameter = [NSString stringWithFormat:@"?bundleidentifier=%@", 
                     [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]
                     ];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@", self.betaCheckUrl, parameter];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:10.0];
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];

    if (!urlConnection) {
        checkInProgress = NO;
        [self registerOnline];
    }

    if (currentHockeyViewController != nil) {
        [currentHockeyViewController redrawTableView];
    }
}


#pragma mark -
#pragma mark UIAlertViewDelegate


// invoke the selected action from the actionsheet for a location element
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
      // YES button has been clicked
      [self showBetaUpdateView];
    }
}


#pragma mark -
#pragma mark NSURLRequest

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
	NSURLRequest *newRequest=request;
	if (redirectResponse) {
		newRequest = nil;
	}
	return newRequest;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectionOpened)])
		[(id)self.delegate connectionOpened];
	
	if (_receivedData != nil)
	{
		[_receivedData release];
        _receivedData = nil;
	}
    
	_receivedData = [[NSMutableData data] retain];
	[_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectionClosed)])
		[(id)self.delegate connectionClosed];
    
	// release the connection, and the data object
    [_receivedData release];
    _receivedData = nil;
    
    self.urlConnection = nil;
    
    checkInProgress = NO;

    if (currentHockeyViewController != nil) {
        [currentHockeyViewController redrawTableView];
    }
    
    [self registerOnline];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_receivedData != nil && [_receivedData length] > 0) {
        NSString *responseString = [[[NSString alloc] initWithBytes:[_receivedData bytes]
                                                             length:[_receivedData length]
                                                           encoding: NSUTF8StringEncoding] autorelease];
        
        
        SBJSON *jsonParser = [[[SBJSON alloc] init] autorelease];
        
        NSDictionary *feed = (NSDictionary *)[jsonParser objectWithString:responseString error:NULL];

		[[NSUserDefaults standardUserDefaults] setObject:[[[NSDate date] description] substringToIndex:10] forKey:kDateOfLastHockeyCheck];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
        BOOL showUpdateReminder = NO;
        if (self.delegate && [[self delegate] respondsToSelector:@selector(showUpdateReminder)]) {
            showUpdateReminder = [[self delegate] showUpdateReminder];
        }
        
		if (self.delegate && [self.delegate respondsToSelector:@selector(connectionClosed)])
			[(id)self.delegate connectionClosed];
		
		// release the connection, and the data object
		[_receivedData release];
		_receivedData = nil;
		
		self.urlConnection = nil;
        checkInProgress = NO;
		
        if (feed == nil || [feed count] == 0) {
            if (currentHockeyViewController != nil) {
				[currentHockeyViewController redrawTableView];
            }
			return;
		}
		
		// get the array of "stream" from the feed and cast to NSArray
		id resultValue = [feed valueForKey:BETA_UPDATE_RESULT];
        
        dataFound = YES;
        
        NSDictionary *dictionaryOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryOfLastHockeyCheck];
        
        NSString *result = nil;
        
        if (![resultValue isKindOfClass:[NSString class]]) {
            result = [NSString stringWithFormat:@"%i", [resultValue intValue]];
        } else {
            result = resultValue;
        }
        
        if ([result compare:@"-1"] == NSOrderedSame)
            dataFound = NO;

        if (dataFound) {
            self.betaDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
            
            NSString *title = NSLocalizedStringFromTable(@"HockeyUnknownApp", @"Hockey", @"Unknown application");
            if ([feed objectForKey:BETA_UPDATE_TITLE] != nil)
                title = (NSString *)[feed valueForKey:BETA_UPDATE_TITLE];
            [self.betaDictionary setObject:title
                                    forKey:BETA_UPDATE_TITLE];
            
            if ([feed objectForKey:BETA_UPDATE_SUBTITLE] != nil) {
                [self.betaDictionary setObject:(NSString *)[feed valueForKey:BETA_UPDATE_SUBTITLE]
                                        forKey:BETA_UPDATE_SUBTITLE];
            }
            
            if ([feed objectForKey:BETA_UPDATE_NOTES] != nil) {
                [self.betaDictionary setObject:(NSString *)[feed valueForKey:BETA_UPDATE_NOTES]
                                        forKey:BETA_UPDATE_NOTES];
            }
                        
            [self.betaDictionary setObject:result
                                    forKey:BETA_UPDATE_VERSION];
            
            NSMutableDictionary *betaDictionaryMutableCopy = [self.betaDictionary mutableCopy];
            for (NSString *key in self.betaDictionary) {
                if ([self.betaDictionary objectForKey:key] == [NSNull null])
                    [betaDictionaryMutableCopy removeObjectForKey:key];
            }
            [[NSUserDefaults standardUserDefaults] setObject:betaDictionaryMutableCopy forKey:kDictionaryOfLastHockeyCheck];
            [betaDictionaryMutableCopy release];
        }
        
        
		if (!dataFound ||
            (!showUpdateReminder &&
             dictionaryOfLastHockeyCheck &&
             [result compare:[dictionaryOfLastHockeyCheck objectForKey:BETA_UPDATE_VERSION]] == NSOrderedSame) ||
            (!showUpdateReminder &&
             [result compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] == NSOrderedSame)
            ) {
            if (currentHockeyViewController != nil) {
				[currentHockeyViewController redrawTableView];
            }
			return;
		}
        
        BOOL differentVersion = NO;
        HockeyComparisonResult versionComparator = HockeyComparisonResultDifferent;
        
		if (self.delegate && [self.delegate respondsToSelector:@selector(compareVersionType)])
			versionComparator = [(id)self.delegate compareVersionType];
        
		if (versionComparator == HockeyComparisonResultGreater) { 
            differentVersion = ([result compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] options:NSNumericSearch] == NSOrderedDescending);
		} else {
            differentVersion = ([result compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame);
        }
        
		if (differentVersion && currentHockeyViewController == nil) {
            [self showCheckForBetaAlert];
		}
        
        if (currentHockeyViewController != nil) {
            [currentHockeyViewController redrawTableView];
        }
	}
    checkInProgress = NO;
}


#pragma mark -
#pragma mark RegisterOnline

- (void)registerOnline {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(wentOnline:)
												 name:@"kNetworkReachabilityChangedNotification"
											   object:nil];            
}


- (void)unregisterOnline {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"kNetworkReachabilityChangedNotification"
												  object:nil];
}


- (void)wentOnline:(NSNotification *)note {
	[self unregisterOnline];
	[self checkForBetaUpdate:NO];
}


@end
