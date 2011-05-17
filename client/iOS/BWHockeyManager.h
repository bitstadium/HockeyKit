//
//  BWHockeyManager.h
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


//  Note: Hockey currently supports following JSON Frameworks: JSONKit
//  To detect internet accessibility, Apple's Reachability Class has to be linked and used

#import <UIKit/UIKit.h>
#import "BWGlobal.h"
#import "BWApp.h"
#import "BWHockeyViewController.h"

typedef enum {
	HockeyComparisonResultDifferent,
	HockeyComparisonResultGreater
} HockeyComparisonResult;

typedef enum {
	HockeyAuthorizationDenied,
	HockeyAuthorizationAllowed,
	HockeyAuthorizationPending
} HockeyAuthorizationState;

typedef enum {
    HockeyUpdateCheckStartup = 0,
    HockeyUpdateCheckDaily = 1,
    HockeyUpdateCheckManually = 2
} HockeyUpdateSetting;

@protocol BWHockeyManagerDelegate;

@interface BWHockeyManager : NSObject <UIAlertViewDelegate> {
    id <BWHockeyManagerDelegate> delegate_;
    NSArray *apps_;
    
    NSString *updateURL_;
    NSString *appIdentifier_;
    NSString *currentAppVersion_;
    
    UINavigationController *navController_;
    BWHockeyViewController *currentHockeyViewController_;
    UIView *authorizeView_;
    
    NSMutableData *receivedData_;
    
    BOOL checkInProgress_;
    BOOL dataFound;
    BOOL updateAvailable_;
    BOOL showFeedback_; 
    BOOL updateURLOffline_;
    BOOL updateAlertShowing_;
    BOOL lastCheckFailed_;
    
    NSURLConnection *urlConnection_;
    NSDate *lastCheck_;
    NSDate *usageStartTimestamp_;
    
    BOOL sendUserData_;
    BOOL sendUsageTime_;
    BOOL allowUserToDisableSendData_;
    BOOL userAllowsSendUserData_;
    BOOL userAllowsSendUsageTime_;
    BOOL showUpdateReminder_;
    BOOL checkForUpdateOnLaunch_;
    HockeyComparisonResult compareVersionType_;
    HockeyUpdateSetting updateSetting_;
    BOOL showUserSettings_;
    BOOL showDirectInstallOption_;
    
    BOOL requireAuthorization_;
    NSString *authenticationSecret_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

// this is a singleton
+ (BWHockeyManager *)sharedHockeyManager;

// update url needs to be set
@property (nonatomic, retain) NSString *updateURL;

// private app identifier (optional)
@property (nonatomic, retain) NSString *appIdentifier;

// delegate is optional
@property (nonatomic, assign) id <BWHockeyManagerDelegate> delegate;

// hockey secret is required if authentication is used
@property (nonatomic, retain) NSString *authenticationSecret;


///////////////////////////////////////////////////////////////////////////////////////////////////
// settings

// if YES, the current user data is send: device type, iOS version, app version, UDID (default)
// if NO, no such data is send to the server
@property (nonatomic, assign, getter=shouldSendUserData) BOOL sendUserData;

// if YES, the the users usage time of the app to the service, only in 1 minute granularity! (default)
// if NO, no such data is send to the server
@property (nonatomic, assign, getter=shouldSendUsageTime) BOOL sendUsageTime;

// if YES, the user agrees to send the usage data, user can change it if the developer shows the settings (default)
// if NO, the user overwrites the developer setting and no such data is sent
@property (nonatomic, assign, getter=isAllowUserToDisableSendData) BOOL allowUserToDisableSendData;

// if YES, the user allowed to send user data (default)
// if NO, the user denied to send user data
@property (nonatomic, assign, getter=doesUserAllowsSendUserData) BOOL userAllowsSendUserData;

// if YES, the user allowed to send usage data (default)
// if NO, the user denied to send usage data
@property (nonatomic, assign, getter=doesUserAllowsSendUsageTime) BOOL userAllowsSendUsageTime;

// if YES, the new version alert will be displayed always if the current version is outdated
// if NO, the alert will be displayed only once for each new update (default)
@property (nonatomic, assign) BOOL alwaysShowUpdateReminder;

// if YES, the user can change the HockeyUpdateSetting value (default)
// if NO, the user can not change it, and the default or developer defined value will be used
@property (nonatomic, assign, getter=shouldShowUserSettings) BOOL showUserSettings;

//if YES, then an update check will be performed after the application becomes active (default)
//if NO, then the update check will not happen unless invoked explicitly
@property (nonatomic, assign, getter=isCheckForUpdateOnLaunch) BOOL checkForUpdateOnLaunch;

//if YES, the alert notifying about an new update also shows a button to install the update directly
//if NO, the alert notifying about an new update only shows ignore and show update button
@property (nonatomic, assign, getter=ishowingDirectInstallOption) BOOL showDirectInstallOption;

//if YES, each app version needs to be authorized by the server to run on this device
//if NO, each app version does not need to be authorized (default) 
@property (nonatomic, assign, getter=isRequireAuthorization) BOOL requireAuthorization;

// HockeyComparisonResultDifferent: alerts if the version on the server is different (default)
// HockeyComparisonResultGreater: alerts if the version on the server is greater
@property (nonatomic, assign) HockeyComparisonResult compareVersionType;

// see HockeyUpdateSetting-enum. Will be saved in user defaults.
// default value: HockeyUpdateCheckStartup
@property (nonatomic, assign) HockeyUpdateSetting updateSetting;

///////////////////////////////////////////////////////////////////////////////////////////////////

// is an update available?
- (BOOL)isUpdateAvailable;

// are we currently checking for updates?
- (BOOL)isCheckInProgress;

// open update info view
- (void)showUpdateView;

// manually start an update check
- (void)checkForUpdate;

// checks for update, informs the user (error, no update found, etc)
- (void)checkForUpdateShowFeedback:(BOOL)feedback;

// initiates app-download call. displays an system UIAlertView
- (BOOL)initiateAppDownload;

// checks wether this app version is authorized
- (BOOL)appVersionIsAuthorized;

// start checking for an authorization key
- (void)checkForAuthorization;

// convenience methode to create hockey view controller
- (BWHockeyViewController *)hockeyViewController:(BOOL)modal;

// get/set current active hockey view controller
@property (nonatomic, retain) BWHockeyViewController *currentHockeyViewController;

// convenience method to get current running version string
- (NSString *)currentAppVersion;

// get newest app or array of all available versions
- (BWApp *)app;

- (NSArray *)apps;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol BWHockeyManagerDelegate <NSObject>
@optional

// Invoked when the internet connection is started, to let the app enable the activity indicator
- (void)connectionOpened;

// Invoked when the internet connection is closed, to let the app disable the activity indicator
- (void)connectionClosed;

// optional parent view controller for the update screen when invoked via the alert view, default is the root UIWindow instance
- (UIViewController *)viewControllerForHockeyController:(BWHockeyManager *)hockeyController;

@end
