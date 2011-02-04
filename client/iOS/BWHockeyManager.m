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

#import "BWHockeyManager.h"
#import "JSONKit.h"
#import <sys/sysctl.h>
#import <Foundation/Foundation.h>

// API defines - do not change
#define BETA_DOWNLOAD_TYPE_PROFILE	@"profile"
#define BETA_DOWNLOAD_TYPE_APP		  @"app"
#define BETA_UPDATE_RESULT          @"result"
#define BETA_UPDATE_TITLE           @"title"
#define BETA_UPDATE_SUBTITLE        @"subtitle"
#define BETA_UPDATE_NOTES           @"notes"
#define BETA_UPDATE_VERSION         @"version"
#define BETA_UPDATE_TIMESTAMP       @"timestamp"
#define BETA_UPDATE_APPSIZE         @"appsize"

@interface BWHockeyManager ()
- (void)registerOnline;
- (void)wentOnline:(NSNotification *)note;
- (NSString *)getDevicePlatform_;
- (void)connectionOpened_;
- (void)connectionClosed_;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, copy) NSDate *lastCheck;
@property (nonatomic, retain) NSMutableArray *apps;
@end

@implementation BWHockeyManager

@synthesize delegate;
@synthesize updateUrl = updateUrl_;
@synthesize urlConnection;
@synthesize checkInProgress;
@synthesize receivedData = receivedData_;
@synthesize sendUserData = sendUserData_;
@synthesize alwaysShowUpdateReminder = showUpdateReminder_;
@synthesize checkForUpdateOnLaunch = checkForUpdateOnLaunch_;
@synthesize compareVersionType = compareVersionType_;
@synthesize lastCheck = lastCheck_;
@synthesize updateSetting = updateSetting_;
@synthesize apps = apps_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark static

+ (BWHockeyManager *)sharedHockeyController {
	static BWHockeyManager *hockeyController = nil;
  
	if (hockeyController == nil) {
		hockeyController = [[BWHockeyManager alloc] init];
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

- (void)clearAppCache_ {
  [self.apps removeAllObjects];
}

- (void)checkAndWriteDefaultAppCache_ {
  // populate with default values (if empty)
  if (IsEmpty(self.apps)) {
    BWApp *defaultApp = [[[BWApp alloc] init] autorelease];
    defaultApp.name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    defaultApp.version = currentAppVersion_;
    [self.apps addObject:defaultApp];
  }  
}

- (void)loadAppCache_ {
  NSData *savedHockeyData = [[NSUserDefaults standardUserDefaults] objectForKey:kArrayOfLastHockeyCheck];
  NSArray *savedHockeyCheck = [NSKeyedUnarchiver unarchiveObjectWithData:savedHockeyData];
  if (savedHockeyCheck) {
    self.apps = [NSMutableArray arrayWithArray:savedHockeyCheck];
  }else {
    self.apps = [NSMutableArray array];
  }
  [self checkAndWriteDefaultAppCache_];
}

- (void)saveAppCache_ {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.apps];
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:kArrayOfLastHockeyCheck]; 
}

- (void)updateViewController_ {
  [currentHockeyViewController redrawTableView]; 
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init {
	if ((self = [super init])) {
    self.updateUrl = nil;
    checkInProgress = NO;
    dataFound = NO;
    
    currentAppVersion_ = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    // set defaults
    sendUserData_ = YES;
    showUpdateReminder_ = NO;
    checkForUpdateOnLaunch_ = YES;
    compareVersionType_ = HockeyComparisonResultDifferent;
    
    // load update setting from user defaults and check value
    self.updateSetting = [[NSUserDefaults standardUserDefaults] integerForKey:kHockeyAutoUpdateSetting];
    
    [self loadAppCache_];
  }
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  
	self.delegate = nil;
  
  [urlConnection cancel];
  self.urlConnection = nil;
  
	currentHockeyViewController = nil;
  [updateUrl_ release];
	[apps_ release];
	[receivedData_ release];
  [lastCheck_ release];
  
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark BetaUpdateUI

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal {
  return [[[BWHockeyViewController alloc] init:self modal:modal] autorelease];
}

- (void)unsetHockeyViewController {
  currentHockeyViewController = nil;
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


- (void)showCheckForBetaAlert_ {
  UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:BWLocalize(@"HockeyUpdateAvailable")
                                                       message:BWLocalize(@"HockeyUpdateAlertText")
                                                      delegate:self
                                             cancelButtonTitle:BWLocalize(@"HockeyNo")
                                             otherButtonTitles:BWLocalize(@"HockeyYes"), nil
                             ] autorelease];
  [alertView show];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark RequestComments

- (BOOL)shouldCheckForUpdates {
  BOOL checkForUpdate = NO;
  switch (self.updateSetting) {
    case HockeyUpdateCheckStartup:
      checkForUpdate = YES;
      break;
    case HockeyUpdateCheckDaily:
      checkForUpdate = [[[self.lastCheck description] substringToIndex:10] compare:[[[NSDate date] description] substringToIndex:10]] != NSOrderedSame;
      break;
    case HockeyUpdateCheckManually:
      checkForUpdate = NO;
      break;     
    default:
      break;
  }
  return checkForUpdate;
}

- (void)checkForUpdate {
  [self checkForUpdate:nil];
}

- (void)checkForUpdate:(BWHockeyViewController *)hockeyViewController {
  if (checkInProgress) return;
  
  checkInProgress = YES;
  currentHockeyViewController = hockeyViewController;
  
  // do we need to update?
  BOOL updatePending = self.alwaysShowUpdateReminder && [[self currentAppVersion] compare:[self app].version] != NSOrderedSame;  
  if (!updatePending && ![self shouldCheckForUpdates] && !currentHockeyViewController) {
    BWLog(@"update not needed right now");
    checkInProgress = NO;
    [currentHockeyViewController redrawTableView];
    return;
  }
  
  NSMutableString *parameter = [NSMutableString stringWithFormat:@"api/ios/status/%@",
                                [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // build request & send
  NSString *url = [NSString stringWithFormat:@"%@%@", self.updateUrl, parameter];
  BWLog(@"sending api request to %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:1 timeoutInterval:10.0];
  [request setHTTPMethod:@"POST"];
  // TODO: change to someting smaller
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
  
  [currentHockeyViewController redrawTableView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSURLRequest

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
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
  checkInProgress = NO;
  
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
    
    // remember that we just checked the server
    self.lastCheck = [NSDate date];
    
    // server returned empty response?
    if (IsEmpty(feedArray)) {
      BWLog(@"Warning: Server returned empty response");
      [self updateViewController_];
			return;
		}
    
    NSString *currentAppCacheVersion = [[[self app].version copy] autorelease];
    
    // clear cache and reload with new data
    [self clearAppCache_];
    for (NSDictionary *dict in feedArray) {
      BWApp *app = [BWApp appFromDict:dict];
      if ([app isValid]) {
        [apps_ addObject:app];
      }else {
        BWLog(@"Error: Invalid App data received from server!");
      }
    }
    [self checkAndWriteDefaultAppCache_];
    [self saveAppCache_];          
    
    BOOL newVersionAvailable = [[self app].version compare:[self currentAppVersion]] != NSOrderedSame;
    BOOL newVersionDiffersFromCachedVersion = [[self app].version compare:currentAppCacheVersion] != NSOrderedSame;
    
    if (newVersionAvailable && self.alwaysShowUpdateReminder || newVersionDiffersFromCachedVersion) {
      
      BOOL differentVersion = NO;
      if (self.compareVersionType == HockeyComparisonResultGreater) {
        differentVersion = ([self.app.version compare:self.currentAppVersion options:NSNumericSearch] == NSOrderedDescending);
      } else {
        differentVersion = ([self.app.version compare:self.currentAppVersion] != NSOrderedSame);
      }
      
      if (differentVersion && !currentHockeyViewController) {
        [self showCheckForBetaAlert_];
      }
      
      [self updateViewController_];
    }
  }
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
  [self checkForUpdate:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (void)setUpdateURL:(NSString *)url {
  [self setUpdateURL:url delegate:nil];
}

- (void)setUpdateURL:(NSString *)url delegate:(id <BWHockeyControllerDelegate>)object {
	self.delegate = object;
  
  // ensure url ends with a trailing slash
  if (![url hasSuffix:@"/"]) {
    url = [NSString stringWithFormat:@"%@/", url];
  }
  
	self.updateUrl = url;
  
	if (self.isCheckForUpdateOnLaunch) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForUpdate)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
	}
}

- (NSString *)currentAppVersion {
  return currentAppVersion_;
}

- (void)setUpdateSetting:(HockeyUpdateSetting)anUpdateSetting {
  if (anUpdateSetting < 0 || anUpdateSetting > HockeyUpdateCheckManually) {
    updateSetting_ = HockeyUpdateCheckStartup;
  }
  
  updateSetting_ = anUpdateSetting;
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:updateSetting_] forKey:kHockeyAutoUpdateSetting];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setLastCheck:(NSDate *)aLastCheck {
  if (lastCheck_ != aLastCheck) {
    [lastCheck_ release];
    lastCheck_ = [aLastCheck copy];
    
		[[NSUserDefaults standardUserDefaults] setObject:[[lastCheck_ description] substringToIndex:10] forKey:kDateOfLastHockeyCheck];
		[[NSUserDefaults standardUserDefaults] synchronize];  
  }
}

- (BWApp *)app {
  BWApp *app = [apps_ objectAtIndex:0];
  return app;
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
