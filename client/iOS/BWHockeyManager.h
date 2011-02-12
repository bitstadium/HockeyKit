//
//  BWHockeyController.h
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

//  Note: Hockey currently supports either JSONKit or sb-json.

#import <UIKit/UIKit.h>
#import "BWGlobal.h"
#import "BWApp.h"
#import "BWHockeyViewController.h"

typedef enum {
	HockeyComparisonResultDifferent,
	HockeyComparisonResultGreater
} HockeyComparisonResult;

typedef enum {
    HockeyUpdateCheckStartup,
    HockeyUpdateCheckDaily,
    HockeyUpdateCheckManually
} HockeyUpdateSetting;

@protocol BWHockeyControllerDelegate;

@interface BWHockeyManager : NSObject <UIAlertViewDelegate> {
    id <BWHockeyControllerDelegate> delegate_;
    NSMutableArray *apps_;

    NSString *updateURL_;
    NSString *currentAppVersion_;

	  BWHockeyViewController *currentHockeyViewController_;

	  NSMutableData *receivedData_;

    BOOL checkInProgress_;
    BOOL dataFound;
    BOOL updateAvailable_;

    NSURLConnection *urlConnection_;
    NSDate *lastCheck_;
    NSDate *usageStartTimestamp_;

    BOOL sendUserData_;
    BOOL showUpdateReminder_;
    BOOL checkForUpdateOnLaunch_;
    BOOL sendUsageTime_;
    HockeyComparisonResult compareVersionType_;
    HockeyUpdateSetting updateSetting_;
    BOOL showUserSettings_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

// this is a singleton
+ (BWHockeyManager *)sharedHockeyManager;

// update url needs to be set
@property (nonatomic, retain) NSString *updateURL;

// delegate is optional
@property (nonatomic, assign) id <BWHockeyControllerDelegate> delegate;


///////////////////////////////////////////////////////////////////////////////////////////////////
// settings

// if YES, the current user data is send: device type, iOS version, app version, UDID (default)
// if NO, no such data is send to the server
@property (nonatomic, assign, getter=isSendUserData) BOOL sendUserData;

// if YES, the the users usage time of the app to the service, only in 15 minute granularity! (default)
// if NO, no such data is send to the server
@property (nonatomic, assign, getter=isSendUsageTime) BOOL sendUsageTime;

// if YES, the new version alert will be displayed always if the current version is outdated
// if NO, the alert will be displayed only once for each new update (default)
@property (nonatomic, assign) BOOL alwaysShowUpdateReminder;

// if YES, the user can change the HockeyUpdateSetting value (default)
// if NO, the user can not change it, and the default or developer defined value will be used
@property (nonatomic, assign, getter=isShowUserSettings) BOOL showUserSettings;

//if YES, then an update check will be performed after the application becomes active (default)
//if NO, then the update check will not happen unless invoked explicitly
@property (nonatomic, assign, getter=isCheckForUpdateOnLaunch) BOOL checkForUpdateOnLaunch;

// HockeyComparisonResultDifferent: alerts if the version on the server is different (default)
// HockeyComparisonResultGreater: alerts if the version on the server is greater
@property (nonatomic, assign) HockeyComparisonResult compareVersionType;

// see HockeyUpdateSetting-enum. Will be saved in user defaults.
// default value: HockeyUpdateCheckStartup
@property (nonatomic, assign) HockeyUpdateSetting updateSetting;

///////////////////////////////////////////////////////////////////////////////////////////////////

// is an update available?
@property (nonatomic, readonly, getter=isUpdateAvailable) BOOL updateAvailable;

// are we currently checking for updates?
@property (readonly, readonly, getter=isCheckInProgress) BOOL checkInProgress;

// open update info view
- (void)showUpdateView;

// initiates app-download call. displays an system UIAlertView
- (BOOL)initiateAppDownload;

// convenience method to get current running version string
- (NSString *)currentAppVersion;

// get newest app or array of all available versions
- (BWApp *)app;
- (NSArray *)apps;

- (void)checkForUpdate:(BWHockeyViewController *)hockeyViewController;
- (void)checkForUpdate;	// invoke this if you need to start a check process manually, e.g. if the hockey controller is set after the
- (BWHockeyViewController *)hockeyViewController:(BOOL)modal;
- (void)unsetHockeyViewController;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol BWHockeyControllerDelegate <NSObject>
@optional

// Invoked when the internet connection is started, to let the app enable the activity indicator
- (void)connectionOpened;

// Invoked when the internet connection is closed, to let the app disable the activity indicator
- (void)connectionClosed;

// optional parent view controller for the update screen when invoked via the alert view, default is the root UIWindow instance
- (UIViewController *)viewControllerForHockeyController:(BWHockeyManager *)hockeyController;

@end
