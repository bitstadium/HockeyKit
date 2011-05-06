//
//  BWHockeyManager.m
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
#import "NSString+HockeyAdditions.h"
#import "UIImage+HockeyAdditions.h"
#import <sys/sysctl.h>
#import <Foundation/Foundation.h>

// API defines - do not change
#define BETA_DOWNLOAD_TYPE_PROFILE	@"profile"
#define BETA_UPDATE_RESULT          @"result"
#define BETA_UPDATE_TITLE           @"title"
#define BETA_UPDATE_SUBTITLE        @"subtitle"
#define BETA_UPDATE_NOTES           @"notes"
#define BETA_UPDATE_VERSION         @"version"
#define BETA_UPDATE_TIMESTAMP       @"timestamp"
#define BETA_UPDATE_APPSIZE         @"appsize"

@interface BWHockeyManager ()
- (NSString *)getDevicePlatform_;
- (id)parseJSONResultString:(NSString *)jsonString;
- (void)connectionOpened_;
- (void)connectionClosed_;
- (BOOL)shouldCheckForUpdates;
- (void)startUsage;
- (void)stopUsage;
- (void)startManager;
- (void)wentOnline;
- (void)showAuthorizationScreen:(NSString *)message image:(NSString *)image;
- (NSString *)currentUsageString;
- (NSString *)installationDateString;
- (NSString *)authenticationToken;
- (HockeyAuthorizationState)authorizationState;

@property (nonatomic, assign, getter=isUpdateAvailable) BOOL updateAvailable;
@property (nonatomic, assign, getter=isCheckInProgress) BOOL checkInProgress;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, copy) NSDate *lastCheck;
@property (nonatomic, copy) NSArray *apps;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, copy) NSDate *usageStartTimestamp;
@end

// hockey api error domain
typedef enum {
    HockeyErrorUnknown,
    HockeyAPIServerReturnedInvalidStatus,
    HockeyAPIServerReturnedInvalidData,
    HockeyAPIServerReturnedEmptyResponse,
    HockeyAPIClientAuthorizationMissingSecret,
    HockeyAPIClientCannotCreateConnection
} HockeyErrorReason;
static NSString *kHockeyErrorDomain = @"HockeyErrorDomain";

@implementation BWHockeyManager

@synthesize delegate = delegate_;
@synthesize updateURL = updateURL_;
@synthesize appIdentifier = appIdentifier_;
@synthesize urlConnection = urlConnection_;
@synthesize checkInProgress = checkInProgress_;
@synthesize receivedData = receivedData_;
@synthesize sendUserData = sendUserData_;
@synthesize sendUsageTime = sendUsageTime_;
@synthesize allowUserToDisableSendData = allowUserToDisableSendData_;
@synthesize userAllowsSendUserData = userAllowsSendUserData_;
@synthesize userAllowsSendUsageTime = userAllowsSendUsageTime_;
@synthesize alwaysShowUpdateReminder = showUpdateReminder_;
@synthesize checkForUpdateOnLaunch = checkForUpdateOnLaunch_;
@synthesize compareVersionType = compareVersionType_;
@synthesize lastCheck = lastCheck_;
@synthesize showUserSettings = showUserSettings_;
@synthesize updateSetting = updateSetting_;
@synthesize apps = apps_;
@synthesize updateAvailable = updateAvailable_;
@synthesize usageStartTimestamp = usageStartTimestamp_;
@synthesize currentHockeyViewController = currentHockeyViewController_;
@synthesize showDirectInstallOption = showDirectInstallOption_;
@synthesize requireAuthorization = requireAuthorization_;
@synthesize authenticationSecret = authenticationSecret_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark static

+ (BWHockeyManager *)sharedHockeyManager {
	static BWHockeyManager *hockeyManager = nil;
    
	if (hockeyManager == nil) {
		hockeyManager = [[BWHockeyManager alloc] init];
	}
    
	return hockeyManager;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)reportError_:(NSError *)error {
    BWHockeyLog(@"Error: %@", [error localizedDescription]);
    lastCheckFailed_ = YES;
    
    // only show error if we enable that
    if (showFeedback_) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BWHockeyLocalize(@"HockeyError")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:BWHockeyLocalize(@"OK") otherButtonTitles:nil];
        [alert show];
        [alert release];
        showFeedback_ = NO;
    }
}

- (NSString *)encodedAppIdentifier_ {
  return (self.appIdentifier ? [self.appIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
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

- (void)startUsage {
    self.usageStartTimestamp = [NSDate date];
    BOOL newVersion = NO;
    
    if (![[NSUserDefaults standardUserDefaults] valueForKey:kUsageTimeForVersionString]) {
        newVersion = YES;
    } else {
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:kUsageTimeForVersionString] compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame) {
            newVersion = YES;
        }
    }
    
    if (newVersion) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]] forKey:kDateOfVersionInstallation];
        [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:kUsageTimeForVersionString];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:0] forKey:kUsageTimeOfCurrentVersion];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }    
}

- (void)stopUsage {
    double timeDifference = [[NSDate date] timeIntervalSinceReferenceDate] - [usageStartTimestamp_ timeIntervalSinceReferenceDate];
    double previousTimeDifference = [(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:kUsageTimeOfCurrentVersion] doubleValue];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:previousTimeDifference + timeDifference] forKey:kUsageTimeOfCurrentVersion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)currentUsageString {
    double currentUsageTime = [(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:kUsageTimeOfCurrentVersion] doubleValue];
    
    if (currentUsageTime > 0) {
        // round (up) to 1 minute
        return [NSString stringWithFormat:@"%.0f", ceil(currentUsageTime / 60.0)*60];
    } else {
        return @"0";
    }
}

- (NSString *)installationDateString {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:kDateOfVersionInstallation] doubleValue]]];
}

- (NSString *)authenticationToken {
    return [BWmd5([NSString stringWithFormat:@"%@%@%@%@", 
                   authenticationSecret_, 
                   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"],
                   [[UIDevice currentDevice] uniqueIdentifier]
                   ]
                  ) lowercaseString];
}

- (HockeyAuthorizationState)authorizationState {
    NSString *version = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAuthorizedVersion];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAuthorizedToken];
    
    if (version != nil && token != nil) {
        if ([version compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] == NSOrderedSame) {
            // if it is denied, block the screen permanently
            if ([token compare:[self authenticationToken]] != NSOrderedSame) {
                return HockeyAuthorizationDenied;
            } else {
                return HockeyAuthorizationAllowed;
            }
        }
    }
    return HockeyAuthorizationPending;
}

- (void)checkUpdateAvailable_ {
    // check if there is an update available
    if (self.compareVersionType == HockeyComparisonResultGreater) {
        self.updateAvailable = ([self.app.version compare:self.currentAppVersion options:NSNumericSearch] == NSOrderedDescending);
    } else {
        self.updateAvailable = ([self.app.version compare:self.currentAppVersion] != NSOrderedSame);
    }
}

- (void)loadAppCache_ {
    NSData *savedHockeyData = [[NSUserDefaults standardUserDefaults] objectForKey:kArrayOfLastHockeyCheck];
    NSArray *savedHockeyCheck = nil;
    if (savedHockeyData) {
        savedHockeyCheck = [NSKeyedUnarchiver unarchiveObjectWithData:savedHockeyData];
    }
    if (savedHockeyCheck) {
        self.apps = [NSArray arrayWithArray:savedHockeyCheck];
        [self checkUpdateAvailable_];
    } else {
        self.apps = nil;
    }
}

- (void)saveAppCache_ {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.apps];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kArrayOfLastHockeyCheck];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (UIWindow *)findVisibleWindow {
    UIWindow *visibleWindow = nil;
    
    // if the rootViewController property (available >= iOS 4.0) of the main window is set, we present the modal view controller on top of the rootViewController
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (!window.hidden && !visibleWindow) {
            visibleWindow = window;
        }
        if ([UIWindow instancesRespondToSelector:@selector(rootViewController)]) {
            if ([window rootViewController]) {
                visibleWindow = window;
                BWHockeyLog(@"UIWindow with rootViewController found: %@", visibleWindow);
                break;
            }
        }
	}
        
    return visibleWindow;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init {
	if ((self = [super init])) {
        updateURL_ = nil;
        appIdentifier_ = nil;
        checkInProgress_ = NO;
        dataFound = NO;
        updateAvailable_ = NO;
        lastCheckFailed_ = NO;
        currentAppVersion_ = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        navController_ = nil;
        authorizeView_ = nil;
        requireAuthorization_ = NO;
        authenticationSecret_= nil;
        
        // set defaults
        self.showDirectInstallOption = NO;
        self.requireAuthorization = NO;
        self.sendUserData = YES;
        self.sendUsageTime = YES;
        self.allowUserToDisableSendData = YES;
        self.alwaysShowUpdateReminder = NO;
        self.checkForUpdateOnLaunch = YES;
        self.showUserSettings = YES;
        self.compareVersionType = HockeyComparisonResultDifferent;
        
        // load update setting from user defaults and check value
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting]) {
            self.updateSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kHockeyAutoUpdateSetting];
        } else {
            self.updateSetting = HockeyUpdateCheckStartup;
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAllowUserSetting]) {
            self.userAllowsSendUserData = [[NSUserDefaults standardUserDefaults] boolForKey:kHockeyAllowUserSetting];
        } else {
            self.userAllowsSendUserData = YES;
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAllowUsageSetting]) {
            self.userAllowsSendUsageTime = [[NSUserDefaults standardUserDefaults] boolForKey:kHockeyAllowUsageSetting];
        } else {
            self.userAllowsSendUsageTime = YES;
        }
        
        [self loadAppCache_];
        
        [self startUsage];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startManager)
                                                     name:BWHockeyNetworkBecomeReachable
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopUsage)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BWHockeyNetworkBecomeReachable object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
    IF_IOS4_OR_GREATER(
                       [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                       [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
                       )
    self.delegate = nil;
    
    [urlConnection_ cancel];
    self.urlConnection = nil;
    
    [navController_ release];
    [authorizeView_ release];
    [currentHockeyViewController_ release];
    [updateURL_ release];
    [apps_ release];
    [receivedData_ release];
    [lastCheck_ release];
    [usageStartTimestamp_ release];
    [authenticationSecret_ release];
    
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark BetaUpdateUI

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal {
    return [[[BWHockeyViewController alloc] init:self modal:modal] autorelease];
}

- (void)showUpdateView {
    if (currentHockeyViewController_) {
        BWHockeyLog(@"update view already visible, aborting");
        return;
    }
    
    UIViewController *parentViewController = nil;
    
    if ([[self delegate] respondsToSelector:@selector(viewControllerForHockeyController:)]) {
        parentViewController = [[self delegate] viewControllerForHockeyController:self];
    }
    
    UIWindow *visibleWindow = [self findVisibleWindow];
        
    if (parentViewController == nil && [UIWindow instancesRespondToSelector:@selector(rootViewController)]) {
        parentViewController = [visibleWindow rootViewController];
    }
    
    // use topmost modal view
    while (parentViewController.modalViewController) {
        parentViewController = parentViewController.modalViewController;
    }
    
    // special addition to get rootViewController from three20 which has it's own controller handling
    if (NSClassFromString(@"TTNavigator")) {
        parentViewController = [[NSClassFromString(@"TTNavigator") performSelector:(NSSelectorFromString(@"navigator"))] visibleViewController];
    }
    
    if (navController_ != nil) [navController_ release];
    
    BWHockeyViewController *hockeyViewController = [self hockeyViewController:YES];    
    navController_ = [[UINavigationController alloc] initWithRootViewController:hockeyViewController];
    
    if (parentViewController) {
        if ([navController_ respondsToSelector:@selector(setModalTransitionStyle:)]) {
            navController_.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        }
        
        // page sheet for the iPad
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [navController_ respondsToSelector:@selector(setModalPresentationStyle:)]) {
            navController_.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [parentViewController presentModalViewController:navController_ animated:YES];
    } else {
		// if not, we add a subview to the window. A bit hacky but should work in most circumstances.
		// Also, we don't get a nice animation for free, but hey, this is for beta not production users ;)
        BWHockeyLog(@"No rootViewController found, using UIWindow-approach: %@", visibleWindow);
        [visibleWindow addSubview:navController_.view];
	}
}


- (void)showCheckForUpdateAlert_ {
    if (!updateAlertShowing_) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:BWHockeyLocalize(@"HockeyUpdateAvailable")
                                                             message:[NSString stringWithFormat:BWHockeyLocalize(@"HockeyUpdateAlertTextWithAppVersion"), [self.app nameAndVersionString]]
                                                            delegate:self
                                                   cancelButtonTitle:BWHockeyLocalize(@"HockeyIgnore")
                                                   otherButtonTitles:BWHockeyLocalize(@"HockeyShowUpdate"), nil
                                   ] autorelease];
        IF_IOS4_OR_GREATER(
                           if (self.ishowingDirectInstallOption) {
                               [alertView addButtonWithTitle:BWHockeyLocalize(@"HockeyInstallUpdate")];
                           }
                           )
        [alertView setTag:0];
        [alertView show];
        updateAlertShowing_ = YES;
    }
}


// nag the user with neverending alerts if we cannot find out the window for presenting the covering sheet
- (void)alertFallback:(NSString *)message {
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil
                               ] autorelease];
    [alertView setTag:1];
    [alertView show];    
}


// open an authorization screen
- (void)showAuthorizationScreen:(NSString *)message image:(NSString *)image {
    if (authorizeView_ != nil) {
        [authorizeView_ removeFromSuperview];
    }
    
    UIWindow *visibleWindow = [self findVisibleWindow];
    
    if (visibleWindow == nil) {
        [self alertFallback:message];
        return;
    }
    
    CGRect frame = [visibleWindow frame];
    
    authorizeView_ = [[[UIView alloc] initWithFrame:frame] autorelease];
    UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:[UIImage bw_imageNamed:@"bg.png" bundle:kHockeyBundleName]] autorelease];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundView.frame = frame;
    [authorizeView_ addSubview:backgroundView];
    
    if (image != nil) {
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage bw_imageNamed:image bundle:kHockeyBundleName]] autorelease];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.frame = frame;
        [authorizeView_ addSubview:imageView];
    }
    
    if (message != nil) {
        frame.origin.x = 20;
        frame.origin.y = frame.size.height - 140;
        frame.size.width -= 40;
        frame.size.height = 40;
        
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.text = message;
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        
        [authorizeView_ addSubview:label];
    }
    
    [visibleWindow addSubview:authorizeView_];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark JSONParsing

- (id)parseJSONResultString:(NSString *)jsonString {
    NSError *error = nil;
    id feedResult = nil;
    
    SEL sbJSONSelector = NSSelectorFromString(@"JSONValue");
    SEL jsonKitSelector = NSSelectorFromString(@"objectFromJSONStringWithParseOptions:error:");
    
    if (jsonKitSelector && [jsonString respondsToSelector:jsonKitSelector]) {
        // first try JSONkit
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[jsonString methodSignatureForSelector:jsonKitSelector]];
        invocation.target = jsonString;
        invocation.selector = jsonKitSelector;
        int parseOptions = 0;
        [invocation setArgument:&parseOptions atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [invocation setArgument:&error atIndex:3];
        [invocation invoke];
        [invocation getReturnValue:&feedResult];
    } else if (sbJSONSelector && [jsonString respondsToSelector:sbJSONSelector]) {
        // now try SBJson
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[jsonString methodSignatureForSelector:sbJSONSelector]];
        invocation.target = jsonString;
        invocation.selector = sbJSONSelector;
        [invocation invoke];
        [invocation getReturnValue:&feedResult];
    } else {
        BWHockeyLog(@"Error: You need a JSON Framework in your runtime!");
        [self doesNotRecognizeSelector:_cmd];
    }    
    if (error) {
        BWHockeyLog(@"Error while parsing response feed: %@", [error localizedDescription]);
        [self reportError_:error];
        return nil;
    }
    
    return feedResult;
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

- (void)checkForAuthorization {
    NSMutableString *parameter = [NSMutableString stringWithFormat:@"api/2/apps/%@", [[self encodedAppIdentifier_] bw_URLEncodedString]];
    
    [parameter appendFormat:@"?format=json&authorize=yes&app_version=%@&udid=%@",
     [[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] bw_URLEncodedString],
     [[[UIDevice currentDevice] uniqueIdentifier] bw_URLEncodedString]
     ];
    
    // build request & send
    NSString *url = [NSString stringWithFormat:@"%@%@", self.updateURL, parameter];
    BWHockeyLog(@"sending api request to %@", url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:1 timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"Hockey/iOS" forHTTPHeaderField:@"User-Agent"];
    
    NSURLResponse *response = nil;
    NSError *error = NULL;
    BOOL failed = YES;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if ([responseData length]) {
        NSString *responseString = [[[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding: NSUTF8StringEncoding] autorelease];
        
        NSDictionary *feedDict = (NSDictionary *)[self parseJSONResultString:responseString];
        
        // server returned empty response?
        if (![feedDict count]) {
            [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIServerReturnedEmptyResponse userInfo:
                                [NSDictionary dictionaryWithObjectsAndKeys:@"Server returned empty response.", NSLocalizedDescriptionKey, nil]]];
            return;
		} else {
            NSString *token = [[feedDict objectForKey:@"authcode"] lowercaseString];
            failed = NO;
            if ([[self authenticationToken] compare:token] == NSOrderedSame) {
                // identical token, activate this version
                
                // store the new data
                [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:kHockeyAuthorizedVersion];
                [[NSUserDefaults standardUserDefaults] setObject:token forKey:kHockeyAuthorizedToken];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                self.requireAuthorization = NO;
                [authorizeView_ removeFromSuperview];
                
                // now continue with an update check right away
                if (self.checkForUpdateOnLaunch) {
                    [self checkForUpdate];
                }
            } else {
                // different token, block this version
                NSLog(@"AUTH FAILURE");
                
                // store the new data
                [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:kHockeyAuthorizedVersion];
                [[NSUserDefaults standardUserDefaults] setObject:token forKey:kHockeyAuthorizedToken];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self showAuthorizationScreen:BWHockeyLocalize(@"HockeyAuthorizationDenied") image:@"authorize_denied.png"];
            }
        }
        
    }
    
    if (failed) {
        [self showAuthorizationScreen:BWHockeyLocalize(@"HockeyAuthorizationOffline") image:@"authorize_request.png"];
    }
}

- (void)checkForUpdate {
    if (self.requireAuthorization) return;
    [self checkForUpdateShowFeedback:NO];
}

- (void)checkForUpdateShowFeedback:(BOOL)feedback {
    if (self.isCheckInProgress) return;
    
    showFeedback_ = feedback;
    self.checkInProgress = YES;
    
    // do we need to update?
    if (![self shouldCheckForUpdates] && !currentHockeyViewController_) {
        BWHockeyLog(@"update not needed right now");
        self.checkInProgress = NO;
        return;
    }
    
    NSMutableString *parameter = [NSMutableString stringWithFormat:@"api/2/apps/%@?format=json&udid=%@", 
                                  [[self encodedAppIdentifier_] bw_URLEncodedString],
                                  [[[UIDevice currentDevice] uniqueIdentifier] bw_URLEncodedString]];
    
    // add additional statistics if user didn't disable flag
    if (self.shouldSendUserData) {
        [parameter appendFormat:@"&app_version=%@&os=iOS&os_version=%@&device=%@&lang=%@&usage_time=%@&first_start_at=%@",
         [[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] bw_URLEncodedString],
         [[[UIDevice currentDevice] systemVersion] bw_URLEncodedString],
         [[self getDevicePlatform_] bw_URLEncodedString],
         [[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0] bw_URLEncodedString],
         [[[self currentUsageString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] bw_URLEncodedString],
         [[[self installationDateString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] bw_URLEncodedString]
         ];
    }
    
    // build request & send
    NSString *url = [NSString stringWithFormat:@"%@%@", self.updateURL, parameter];
    BWHockeyLog(@"sending api request to %@", url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:1 timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"Hockey/iOS" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    self.urlConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    if (!urlConnection_) {
        self.checkInProgress = NO;
        [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIClientCannotCreateConnection userInfo:
                            [NSDictionary dictionaryWithObjectsAndKeys:@"Url Connection could not be created.", NSLocalizedDescriptionKey, nil]]];
    }
}

- (BOOL)initiateAppDownload {
    if (!self.isUpdateAvailable) {
        BWHockeyLog(@"Warning: No update available. Aborting.");
        return NO;
    }
    
    IF_PRE_IOS4
    (
     NSString *message = [NSString stringWithFormat:BWHockeyLocalize(@"HockeyiOS3Message"), self.updateURL];
     UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:BWHockeyLocalize(@"HockeyWarning") message:message delegate:nil cancelButtonTitle:BWHockeyLocalize(@"HockeyOK") otherButtonTitles:nil] autorelease];
     [alert show];
     return NO;
     )
    
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:BWHockeyLocalize(@"HockeyWarning") message:BWHockeyLocalize(@"HockeySimulatorMessage") delegate:nil cancelButtonTitle:BWHockeyLocalize(@"HockeyOK") otherButtonTitles:nil] autorelease];
    [alert show];
    return NO;
#endif
    
    NSString *extraParameter = [NSString string];
    if (self.shouldSendUserData) {
        extraParameter = [NSString stringWithFormat:@"&udid=%@", [[UIDevice currentDevice] uniqueIdentifier]];
    }
    
    NSString *hockeyAPIURL = [NSString stringWithFormat:@"%@api/2/apps/%@?format=plist%@", self.updateURL, [self encodedAppIdentifier_], extraParameter];
    NSString *iOSUpdateURL = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [hockeyAPIURL bw_URLEncodedString]];
    
    BWHockeyLog(@"API Server Call: %@, calling iOS with %@", hockeyAPIURL, iOSUpdateURL);
    BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iOSUpdateURL]];
    BWHockeyLog(@"System returned: %d", success);
    return success;
}


// checks wether this app version is authorized
- (BOOL)appVersionIsAuthorized {
    if (self.requireAuthorization && !authenticationSecret_) {
        [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIClientAuthorizationMissingSecret userInfo:
                            [NSDictionary dictionaryWithObjectsAndKeys:@"Authentication secret is not set but required.", NSLocalizedDescriptionKey, nil]]];
        
        return NO;
    }
    
    if (!self.requireAuthorization) {
        if (authorizeView_ != nil) {
            [authorizeView_ removeFromSuperview];
        }
        
        return YES;
    }
    
    HockeyAuthorizationState state = [self authorizationState];
    if (state == HockeyAuthorizationDenied) {
        [self showAuthorizationScreen:BWHockeyLocalize(@"HockeyAuthorizationDenied") image:@"authorize_denied.png"];
    } else if (state == HockeyAuthorizationAllowed) {
        self.requireAuthorization = NO;
        return YES;
    }
    
    return NO;
}


// begin the startup process
- (void)startManager {
    if (![self appVersionIsAuthorized]) {
        if ([self authorizationState] == HockeyAuthorizationPending) {
            [self showAuthorizationScreen:BWHockeyLocalize(@"HockeyAuthorizationProgress") image:@"authorize_request.png"];
            
            [self performSelector:@selector(checkForAuthorization) withObject:nil afterDelay:0.0f];
        }
    } else {
        if ([self shouldCheckForUpdates]) {
            [self performSelector:@selector(checkForUpdate) withObject:nil afterDelay:0.0f];
        }
    }
}


- (void)wentOnline {
    if (![self appVersionIsAuthorized]) {
        if ([self authorizationState] == HockeyAuthorizationPending) {
            [self checkForAuthorization];
        }
    } else {
        if (lastCheckFailed_) {
            [self checkForUpdate];
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSURLRequest

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    [self connectionOpened_];
	NSURLRequest *newRequest = request;
	if (redirectResponse) {
		newRequest = nil;
	}
	return newRequest;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response respondsToSelector:@selector(statusCode)]) {
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];
        if (statusCode == 404) {
            [connection cancel];  // stop connecting; no more delegate messages
            NSString *errorStr = [NSString stringWithFormat:@"Hockey API received HTTP Status Code %d", statusCode];
            [self connectionClosed_];
            [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIServerReturnedInvalidStatus userInfo:
                                [NSDictionary dictionaryWithObjectsAndKeys:errorStr, NSLocalizedDescriptionKey, nil]]];
            return;
        }
    }
    
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
    self.checkInProgress = NO;
    [self reportError_:error];
}

// api call returned, parsing
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self connectionClosed_];
    self.checkInProgress = NO;
    
	if ([self.receivedData length]) {
        NSString *responseString = [[[NSString alloc] initWithBytes:[receivedData_ bytes] length:[receivedData_ length] encoding: NSUTF8StringEncoding] autorelease];
        BWHockeyLog(@"Received API response: %@", responseString);
        
        NSArray *feedArray = (NSArray *)[self parseJSONResultString:responseString];
        
        self.receivedData = nil;
        self.urlConnection = nil;
        
        // remember that we just checked the server
        self.lastCheck = [NSDate date];
        
        // server returned empty response?
        if (![feedArray count]) {
            [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIServerReturnedEmptyResponse userInfo:
                                [NSDictionary dictionaryWithObjectsAndKeys:@"Server returned empty response.", NSLocalizedDescriptionKey, nil]]];
            return;
		} else {
            lastCheckFailed_ = NO;
        }
        
        
        NSString *currentAppCacheVersion = [[[self app].version copy] autorelease];
        
        // clear cache and reload with new data
        NSMutableArray *tmpApps = [NSMutableArray arrayWithCapacity:[feedArray count]];
        for (NSDictionary *dict in feedArray) {
            BWApp *app = [BWApp appFromDict:dict];
            if ([app isValid]) {
                [tmpApps addObject:app];
            } else {
                [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIServerReturnedInvalidData userInfo:
                                    [NSDictionary dictionaryWithObjectsAndKeys:@"Invalid data received from server.", NSLocalizedDescriptionKey, nil]]];
            }
        }
        // only set if different!
        if (![self.apps isEqualToArray:tmpApps]) {
            self.apps = [[tmpApps copy] autorelease];
        }
        [self saveAppCache_];
        
        [self checkUpdateAvailable_];
        BOOL newVersionDiffersFromCachedVersion = ![self.app.version isEqualToString:currentAppCacheVersion];
        
        // show alert if we are on the latest & greatest
        if (showFeedback_ && !self.isUpdateAvailable) {
            // use currentVersionString, as version still may differ (e.g. server: 1.2, client: 1.3)
            NSString *versionString = [self currentAppVersion];
            NSString *shortVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            shortVersionString = shortVersionString ? [NSString stringWithFormat:@"%@ ", shortVersionString] : @"";
            versionString = [shortVersionString length] ? [NSString stringWithFormat:@"(%@)", versionString] : versionString;
            NSString *currentVersionString = [NSString stringWithFormat:@"%@ %@ %@%@", self.app.name, BWHockeyLocalize(@"HockeyVersion"), shortVersionString, versionString];
            NSString *alertMsg = [NSString stringWithFormat:BWHockeyLocalize(@"HockeyNoUpdateNeededMessage"), currentVersionString];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BWHockeyLocalize(@"HockeyNoUpdateNeededTitle") message:alertMsg delegate:nil cancelButtonTitle:BWHockeyLocalize(@"HockeyOK") otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        
        if (self.isUpdateAvailable && (self.alwaysShowUpdateReminder || newVersionDiffersFromCachedVersion)) {
            if (updateAvailable_ && !currentHockeyViewController_) {
                [self showCheckForUpdateAlert_];
            }
        }
        showFeedback_ = NO;
    }else {
        [self reportError_:[NSError errorWithDomain:kHockeyErrorDomain code:HockeyAPIServerReturnedEmptyResponse userInfo:
                            [NSDictionary dictionaryWithObjectsAndKeys:@"Server returned an empty response.", NSLocalizedDescriptionKey, nil]]];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (void)setCurrentHockeyViewController:(BWHockeyViewController *)aCurrentHockeyViewController {
    if (currentHockeyViewController_ != aCurrentHockeyViewController) {
        [currentHockeyViewController_ release];
        currentHockeyViewController_ = [aCurrentHockeyViewController retain];
        //BWHockeyLog(@"active hockey view controller: %@", aCurrentHockeyViewController);
    }
}

- (void)setUpdateURL:(NSString *)anUpdateURL {
    // ensure url ends with a trailing slash
    if (![anUpdateURL hasSuffix:@"/"]) {
        anUpdateURL = [NSString stringWithFormat:@"%@/", anUpdateURL];
    }
    
    IF_IOS4_OR_GREATER(
                       // register/deregister logic
                       NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                       if (!updateURL_ && anUpdateURL) {
                           [dnc addObserver:self selector:@selector(startUsage) name:UIApplicationDidBecomeActiveNotification object:nil];
                           [dnc addObserver:self selector:@selector(stopUsage) name:UIApplicationWillResignActiveNotification object:nil];
                       } else if (updateURL_ && !anUpdateURL) {
                           [dnc removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                           [dnc removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
                       }
                       )
    
    if (updateURL_ != anUpdateURL) {
        [updateURL_ release];
        updateURL_ = [anUpdateURL copy];
    }
    
    [self performSelector:@selector(startManager) withObject:nil afterDelay:0.0f];
}

- (void)setAppIdentifier:(NSString *)anAppIdentifier {    
    if (appIdentifier_ != anAppIdentifier) {
        [appIdentifier_ release];
        appIdentifier_ = [anAppIdentifier copy];
    }
    
    [self setUpdateURL:@"https://beta.hockeyapp.net/"];
}

- (void)setCheckForUpdateOnLaunch:(BOOL)flag {
    if (checkForUpdateOnLaunch_ != flag) {
        checkForUpdateOnLaunch_ = flag;
        IF_IOS4_OR_GREATER(
                           NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                           if (flag) {
                               [dnc addObserver:self selector:@selector(checkForUpdate) name:UIApplicationDidBecomeActiveNotification object:nil];
                           } else {
                               [dnc removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                           }
                           )
    }
}

- (void)setUserAllowsSendUserData:(BOOL)flag {
    userAllowsSendUserData_ = flag;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:userAllowsSendUserData_] forKey:kHockeyAllowUsageSetting];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUserAllowsSendUsageTime:(BOOL)flag {
    userAllowsSendUsageTime_ = flag;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:userAllowsSendUsageTime_] forKey:kHockeyAllowUsageSetting];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)currentAppVersion {
    return currentAppVersion_;
}


- (void)setUpdateSetting:(HockeyUpdateSetting)anUpdateSetting {
    if (anUpdateSetting > HockeyUpdateCheckManually) {
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

- (void)setApps:(NSArray *)anApps {
    if (apps_ != anApps || !apps_) {
        [apps_ release];
        [self willChangeValueForKey:@"apps"];
        
        // populate with default values (if empty)
        if (![anApps count]) {
            BWApp *defaultApp = [[[BWApp alloc] init] autorelease];
            defaultApp.name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            defaultApp.version = currentAppVersion_;
            defaultApp.shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            apps_ = [[NSArray arrayWithObject:defaultApp] retain];
        }else {
            apps_ = [anApps copy]; 
        }      
        [self didChangeValueForKey:@"apps"];
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
    if ([alertView tag] == 1) {
        [self alertFallback:[alertView message]];
        return;
    }
    
    updateAlertShowing_ = NO;
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        // YES button has been clicked
        [self showUpdateView];
    } else if (buttonIndex == [alertView firstOtherButtonIndex] + 1) {
        // YES button has been clicked
        [self initiateAppDownload];
    }
}

@end
