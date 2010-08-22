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
#import "UIApplication+NetworkIndicator.h"
#import "JSON.h"


@interface BWHockeyController (private)
- (void)registerOnline;
@end

@implementation BWHockeyController

@synthesize betaCheckUrl = _betaCheckUrl;
@synthesize betaDictionary = _betaDictionary;

+ (BWHockeyController *)sharedHockeyController {
	static BWHockeyController *hockeyController = nil;
	
	if (hockeyController == nil) {
		hockeyController = [[BWHockeyController alloc] init];
	}
	
	return hockeyController;
}

- (id)init {
    self = [super init];
    
	if ( self != nil)
	{
        self.betaCheckUrl = nil;
        self.betaDictionary = nil;
    }
    return self;
}


- (void)setBetaURL:(NSString *)url {
    self.betaCheckUrl = url;
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForBetaUpdate)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidBecomeActiveNotification
												  object:nil];
    
    [self.betaCheckUrl release];
    [super dealloc];
}


#pragma mark -
#pragma mark BetaUpdateUI

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal {
    return [[[BWHockeyViewController alloc] init:self
                                               modal:modal]
             autorelease];
}


- (void)showBetaUpdateView {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[self hockeyViewController:YES]];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    // TODO: find a better way to present the modal sheet on top of the current viewcontroller
    [[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController] presentModalViewController:navController animated:YES];
}


- (void) showCheckForBetaAlert {
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update available", @"")
                                                         message:NSLocalizedString(@"Would you like to check out the new update? You can do this later on at any time in the In-App settings.", @"")
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"No", @"")
                                               otherButtonTitles:NSLocalizedString(@"Yes", @""), nil
                               ] autorelease];
    [alertView show];
}


#pragma mark -
#pragma mark RequestComments

- (void) checkForBetaUpdate {
    [self checkForBetaUpdate:nil];
}

- (void) checkForBetaUpdate:(BWHockeyViewController *)hockeyViewController {
    if ([BWGlobal majorOSVersion] < 4) return;  

    currentHockeyViewController = hockeyViewController;
    
    NSNumber *hockeyAutoUpdateSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting];
    NSString *dateOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDateOfLastHockeyCheck];
    
    if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_MANUAL && currentHockeyViewController == nil) {
        return;
    } else if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_DAILY && currentHockeyViewController == nil) {
        // now check if the last check wasn't done today
        if (dateOfLastHockeyCheck != nil &&
            [dateOfLastHockeyCheck compare:[[[NSDate date] description] substringToIndex:10]] == NSOrderedSame) {
            return;
        }

    }
    
    self.betaDictionary = nil;
    
    NSString *parameter = [NSString stringWithFormat:@"?bundleidentifier=%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
    NSString *url = [NSString stringWithFormat:@"%@%@", self.betaCheckUrl, parameter];

    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:10.0];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection)
        [self registerOnline];
}


#pragma mark -
#pragma mark UIAlertViewDelegate


// invoke the selected action from the actionsheet for a location element
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
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
    [[UIApplication sharedApplication] increaseNetworkUse];
	
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
    [[UIApplication sharedApplication] decreaseNetworkUse];
    
	// release the connection, and the data object
    [_receivedData release];
    _receivedData = nil;
    
    [connection release];
	connection = nil;	
    
    [self registerOnline];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_receivedData != nil && [_receivedData length] > 0) {
        NSString *responseString = [[[NSString alloc] initWithBytes:[_receivedData bytes]
                                                             length:[_receivedData length]
                                                           encoding: NSUTF8StringEncoding] autorelease];
        
        
        SBJSON *jsonParser = [[SBJSON new] autorelease];
        
        NSDictionary *feed = (NSDictionary *)[jsonParser objectWithString:responseString error:NULL];

        if (feed != nil && [feed count] > 0) {
            // get the array of "stream" from the feed and cast to NSArray
            NSString *result = (NSString *)[feed valueForKey:BETA_UPDATE_RESULT];
            
            if ([result compare:@"-1"] != NSOrderedSame && [result compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame) {
                NSString *profile = (NSString *)[feed valueForKey:BETA_UPDATE_PROFILE];
                
                NSString *title = (NSString *)[feed valueForKey:BETA_UPDATE_TITLE];

                NSString *subtitle = @"";
                if ([feed objectForKey:BETA_UPDATE_SUBTITLE] != nil)
                    subtitle = (NSString *)[feed valueForKey:BETA_UPDATE_SUBTITLE];

                NSString *notes = (NSString *)[feed valueForKey:BETA_UPDATE_NOTES];
                if (notes == nil) {
                    self.betaDictionary = [[NSDictionary dictionaryWithObjectsAndKeys: result, BETA_UPDATE_VERSION, 
                                            profile, BETA_UPDATE_PROFILE, 
                                            title,BETA_UPDATE_TITLE, 
                                            subtitle, BETA_UPDATE_SUBTITLE,
                                            nil] retain];
                } else {            
                    self.betaDictionary = [[NSDictionary dictionaryWithObjectsAndKeys: result, BETA_UPDATE_VERSION, 
                                            profile, BETA_UPDATE_PROFILE, 
                                            title, BETA_UPDATE_TITLE, 
                                            subtitle, BETA_UPDATE_SUBTITLE,
                                            notes, BETA_UPDATE_NOTES, 
                                            nil] retain];
                }
                
                NSDictionary *dictionaryOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryOfLastHockeyCheck];
                
                [[NSUserDefaults standardUserDefaults] setObject:self.betaDictionary forKey:kDictionaryOfLastHockeyCheck];
                
                if (
                    dictionaryOfLastHockeyCheck == nil || 
                    [result compare:[dictionaryOfLastHockeyCheck objectForKey:BETA_UPDATE_VERSION]] != NSOrderedSame
                    ) {
                    if (currentHockeyViewController == nil) {
                        [self showCheckForBetaAlert];
                    } else {
                        [[currentHockeyViewController tableView] reloadData];                        
                    }
                }
            }
        }        
	}
    
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSDate date] description] substringToIndex:10] forKey:kDateOfLastHockeyCheck];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[UIApplication sharedApplication] decreaseNetworkUse];
		
	// release the connection, and the data object
    [_receivedData release];
    _receivedData = nil;
    
    [connection release];
	connection = nil;	
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
