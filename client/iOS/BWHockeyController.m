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
#import "JSONKit.h"
#import <sys/sysctl.h>
#import <Foundation/Foundation.h>

@interface BWHockeyController ()
- (void)registerOnline;
- (void)wentOnline:(NSNotification *)note;
- (NSString *)getDevicePlatform_;
- (void)connectionOpened_;
- (void)connectionClosed_;
@property (nonatomic, retain) NSMutableData *receivedData;
@end

@implementation BWHockeyController

@synthesize delegate;
@synthesize betaCheckUrl;
@synthesize betaDictionary;
@synthesize urlConnection;
@synthesize checkInProgress;
@synthesize receivedData = receivedData_;
@synthesize sendUserData = sendUserData_;
@synthesize showUpdateReminder = showUpdateReminder_;
@synthesize checkForUpdateOnLaunch = checkForUpdateOnLaunch_;
@synthesize compareVersionType = compareVersionType_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark static

+ (BWHockeyController *)sharedHockeyController {
	static BWHockeyController *hockeyController = nil;

	if (hockeyController == nil) {
		hockeyController = [[BWHockeyController alloc] init];
	}

	return hockeyController;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

static inline BOOL IsEmpty(id thing) {
	return thing == nil ||
  ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) ||
  ([thing respondsToSelector:@selector(count)]  && [(NSArray *)thing count] == 0);
}

- (NSString *)getDevicePlatform_ {
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *answer = malloc(size);
	sysctlbyname("hw.machine", answer, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
	free(answer);
	return platform;
}

- (void)connectionOpened_ {
  if ([self.delegate respondsToSelector:@selector(connectionOpened)])
		[(id)self.delegate connectionOpened];
}

- (void)connectionClosed_ {
  if ([self.delegate respondsToSelector:@selector(connectionClosed)])
		[(id)self.delegate connectionClosed];
}

- (void)loadDefaultHockeyDict_ {
  NSDictionary *savedHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryOfLastHockeyCheck];
  if (savedHockeyCheck) {
    betaDictionary = [[NSMutableDictionary alloc] initWithDictionary:savedHockeyCheck];
  }else {
    betaDictionary = [[NSMutableDictionary alloc] init];
  }

  // populate with default values
  if (![betaDictionary objectForKey:BETA_UPDATE_TITLE]) {
    [betaDictionary setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] forKey:BETA_UPDATE_TITLE];
  }

  if (![betaDictionary objectForKey:BETA_UPDATE_VERSION]) {
    [betaDictionary setObject:currentAppVersion_ forKey:BETA_UPDATE_VERSION];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init {
	if ((self = [super init])) {
    self.betaCheckUrl = nil;
    checkInProgress = NO;
    dataFound = NO;

    currentAppVersion_ = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

    // set defaults
    sendUserData_ = YES;
    showUpdateReminder_ = NO;
    checkForUpdateOnLaunch_ = YES;
    compareVersionType_ = HockeyComparisonResultDifferent;

    [self loadDefaultHockeyDict_];
  }

  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

	self.delegate = nil;

  [urlConnection cancel];
  self.urlConnection = nil;

	currentHockeyViewController = nil;
  [betaCheckUrl release];
	[betaDictionary release];
	[receivedData_ release];

  [super dealloc];
}

- (void)setBetaURL:(NSString *)url {
  [self setBetaURL:url delegate:nil];
}

- (void)setBetaURL:(NSString *)url delegate:(id <BWHockeyControllerDelegate>)object {
	self.delegate = object;
  
  // ensure url ends with a trailing slash
  if (![url hasSuffix:@"/"]) {
    url = [NSString stringWithFormat:@"%@/", url];
  }
  
	self.betaCheckUrl = url;

	if (self.isCheckForUpdateOnLaunch) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForBetaUpdate)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
	}
}


#pragma mark -
#pragma mark BetaUpdateUI

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal {
  return [[[BWHockeyViewController alloc] init:self modal:modal] autorelease];
}


- (void) unsetHockeyViewController {
  if (currentHockeyViewController != nil) {
    currentHockeyViewController = nil;
  }
}


- (void)showBetaUpdateView {
  UIViewController *parentViewController = nil;

  if ([[self delegate] respondsToSelector:@selector(viewControllerForHockeyController:)]) {
    parentViewController = [[self delegate] viewControllerForHockeyController:self];
  }

  UIWindow *visibleWindow = nil;
	if (parentViewController == nil && [UIWindow instancesRespondToSelector:@selector(rootViewController)]) {
    // if the rootViewController property (available >= iOS 4.0) of the main window is set, we present the modal view controller on top of the rootViewController
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
      if (!window.hidden) {
        visibleWindow = window;
      }
      if ([window rootViewController]) {
        parentViewController = [window rootViewController];
        visibleWindow = window;
        BWLog(@"UIWindow with rootViewController found: %@", visibleWindow);
        break;
      }
    }
	}

  BWHockeyViewController *hockeyViewController = [self hockeyViewController:YES];
  UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:hockeyViewController] autorelease];

  if (parentViewController) {
    if ([navController respondsToSelector:@selector(setModalTransitionStyle:)]) {
      navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }

    [parentViewController presentModalViewController:navController animated:YES];
  } else {
		// if not, we add a subview to the window. A bit hacky but should work in most circumstances.
		// Also, we don't get a nice animation for free, but hey, this is for beta not production users ;)
    BWLog(@"No rootViewController found, using UIWindow-approach: %@", visibleWindow);
    [visibleWindow addSubview:navController.view];

		// we don't release the navController here, that'll be done when it's dismissed in [BWHockeyViewController -onAction:]
    [navController retain];
	}
}


- (void) showCheckForBetaAlert {
  UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:BWLocalize(@"HockeyUpdateAvailable")
                                                       message:BWLocalize(@"HockeyUpdateAlertText")
                                                      delegate:self
                                             cancelButtonTitle:BWLocalize(@"HockeyNo")
                                             otherButtonTitles:BWLocalize(@"HockeyYes"), nil
                             ] autorelease];
  [alertView show];
}


#pragma mark -
#pragma mark RequestComments

- (void)checkForBetaUpdate {
  [self checkForBetaUpdate:nil];
}

- (void)checkForBetaUpdate:(BWHockeyViewController *)hockeyViewController {
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

  BOOL updatePending = NO;
  NSDictionary *dictionaryOfLastHockeyCheck = [[NSUserDefaults standardUserDefaults] objectForKey:kDictionaryOfLastHockeyCheck];
  if (self.isShowUpdateReminder &&
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

  NSMutableString *parameter = [NSMutableString stringWithFormat:@"api/ios/status/%@",
                                [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

  // build request & send
  NSString *url = [NSString stringWithFormat:@"%@%@", self.betaCheckUrl, parameter];
  BWLog(@"sending api request to %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:1 timeoutInterval:10.0];
  [request setHTTPMethod:@"POST"];
  // TODO: needed?w
  [request setValue:@"/Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.05 Mobile/8A293 Safari/6531.22.7" forHTTPHeaderField:@"User-Agent"];
  
  // add additional statistics if user didn't disable flag
  if (self.isSendUserData) {
    NSString *postDataString = [NSString stringWithFormat:@"version=%@&ios=%@&platform=%@&udid=%@&lang=%@",
     [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
     [[UIDevice currentDevice] systemVersion],
     [self getDevicePlatform_],
     [[UIDevice currentDevice] uniqueIdentifier],
     [[NSLocale preferredLanguages] objectAtIndex:0]
     ];
    BWLog(@"posting additional data: %@", postDataString);
    NSData *requestData = [NSData dataWithBytes:[postDataString UTF8String] length:[postDataString length]];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postDataString length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody:requestData];
  }
  
  self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

  if (!urlConnection) {
    checkInProgress = NO;
    [self registerOnline];
  }

  if (currentHockeyViewController != nil) {
    [currentHockeyViewController redrawTableView];
  }
}

#pragma mark -
#pragma mark NSURLRequest

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse {
	NSURLRequest *newRequest = request;
	if (redirectResponse) {
		newRequest = nil;
	}
	return newRequest;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  [self connectionOpened_];
	self.receivedData = [NSMutableData data];
	[receivedData_ setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [receivedData_ appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [self connectionClosed_];
	self.receivedData = nil;
  self.urlConnection = nil;
  checkInProgress = NO;

  [currentHockeyViewController redrawTableView];

  [self registerOnline];
}

// api call returned, parsing
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [self connectionClosed_];
	if ([self.receivedData length]) {
    NSString *responseString = [[[NSString alloc] initWithBytes:[receivedData_ bytes] length:[receivedData_ length] encoding: NSUTF8StringEncoding] autorelease];
    BWLog(@"Received API response: %@", responseString);

    NSError *error = nil;
    NSArray *feedArray = [responseString objectFromJSONStringWithParseOptions:JKParseOptionNone error:&error];
    if (error) {
      BWLog(@"Error while parsing response feed: %@", [error localizedDescription]);
      // TODO: report error
    }

    self.receivedData = nil;
		self.urlConnection = nil;
    checkInProgress = NO;

    // remember that we just checked the server
		[[NSUserDefaults standardUserDefaults] setObject:[[[NSDate date] description] substringToIndex:10] forKey:kDateOfLastHockeyCheck];
		[[NSUserDefaults standardUserDefaults] synchronize];

    if (IsEmpty(feedArray)) {
      [currentHockeyViewController redrawTableView];
			return;
		}

    // version property is critical
    NSDictionary *feed = [feedArray objectAtIndex:0];
    NSString *version = [feed valueForKey:BETA_UPDATE_VERSION];
    if (!IsEmpty(version)) {
      // copy only certain items from the returning array
      NSArray *propertiesToCopy = [NSArray arrayWithObjects:BETA_UPDATE_VERSION, BETA_UPDATE_TITLE, BETA_UPDATE_SUBTITLE, BETA_UPDATE_TIMESTAMP, BETA_UPDATE_APPSIZE, BETA_UPDATE_NOTES, nil];
      for(NSString *propertyKey in propertiesToCopy) {
        if ([feed objectForKey:propertyKey] != nil) {
          NSString *propertyValue = (NSString *)[feed valueForKey:propertyKey];
          [self.betaDictionary setObject:propertyValue forKey:propertyKey];
        }
        // don't allow NSNull
        if ([feed objectForKey:propertyKey] == [NSNull null]) {
          [self.betaDictionary removeObjectForKey:propertyKey];
        }
      }

      // save data in user defaults
      [[NSUserDefaults standardUserDefaults] setObject:self.betaDictionary forKey:kDictionaryOfLastHockeyCheck];
    }

		if (!dataFound || (!self.isShowUpdateReminder && [version compare:[self.betaDictionary objectForKey:BETA_UPDATE_VERSION]] == NSOrderedSame)) {
      [currentHockeyViewController redrawTableView];
      return;
    }

    BOOL differentVersion = NO;
    if (self.compareVersionType == HockeyComparisonResultGreater) {
      differentVersion = ([version compare:self.currentAppVersion options:NSNumericSearch] == NSOrderedDescending);
    } else {
      differentVersion = ([version compare:self.currentAppVersion] != NSOrderedSame);
    }

    if (differentVersion && !currentHockeyViewController) {
      [self showCheckForBetaAlert];
    }

    [currentHockeyViewController redrawTableView];
  }
  checkInProgress = NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
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

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (NSString *)appName {
  return [self.betaDictionary objectForKey:BETA_UPDATE_TITLE];
}

- (NSString *)appVersion {
  return [self.betaDictionary objectForKey:BETA_UPDATE_VERSION];
}

- (NSString *)currentAppVersion {
  return currentAppVersion_;
}

- (NSDate *)appDate {
  NSTimeInterval timestamp = (NSTimeInterval)[[self.betaDictionary objectForKey:BETA_UPDATE_TIMESTAMP] doubleValue];
  NSDate *appDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
  return appDate;
}

- (NSNumber *)appSize {
  return [self.betaDictionary objectForKey:BETA_UPDATE_APPSIZE];
}

- (NSString *)appSizeInMB {
  if ([[self appSize] doubleValue]) {
    double appSizeInMB = [[self appSize] doubleValue]/(1024*1024);
    NSString *appSizeString = [NSString stringWithFormat:@"%.1f MB", appSizeInMB];
    return appSizeString;
  }

  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIAlertViewDelegate

// invoke the selected action from the actionsheet for a location element
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == [alertView firstOtherButtonIndex]) {
    // YES button has been clicked
    [self showBetaUpdateView];
  }
}

@end
