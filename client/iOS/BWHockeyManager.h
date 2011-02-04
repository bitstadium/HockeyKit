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
	id <BWHockeyControllerDelegate> delegate;
  NSMutableArray *apps_;

  NSString *updateUrl_;
  NSString *currentAppVersion_;

	BWHockeyViewController *currentHockeyViewController;

	NSMutableData *receivedData_;

  BOOL checkInProgress;
  BOOL dataFound;

  NSURLConnection *urlConnection;
  NSDate *lastCheck_;
  BOOL sendUserData_;
  BOOL showUpdateReminder_;
  BOOL checkForUpdateOnLaunch_;
  HockeyComparisonResult compareVersionType_;
  HockeyUpdateSetting updateSetting_;
}

// settings

// if YES, the current user data is send: device type, iOS version, app version, UDID (default)
// if NO, no such data is send to the server
@property (nonatomic, assign, getter=isSendUserData) BOOL sendUserData;

// if YES, the new version alert will be displayed always if the current version is outdated
// if NO, the alert will be displayed only once for each new update (default)
@property (nonatomic, assign) BOOL alwaysShowUpdateReminder;

//if YES, then an update check will be performed after the application becomes active (default)
//if NO, then the update check will not happen unless invoked explicitly
@property (nonatomic, assign, getter=isCheckForUpdateOnLaunch) BOOL checkForUpdateOnLaunch;

// HockeyComparisonResultDifferent: alerts if the version on the server is different (default)
// HockeyComparisonResultGreater: alerts if the version on the server is greate
@property (nonatomic, assign) HockeyComparisonResult compareVersionType;

// see HockeyUpdateSetting-enum. Will be saved in user defaults.
@property (nonatomic, assign) HockeyUpdateSetting updateSetting;


// delegate
@property (nonatomic, assign) id <BWHockeyControllerDelegate> delegate;

// internal
@property (nonatomic, retain) NSString *updateUrl;
@property (nonatomic, retain) NSURLConnection *urlConnection;

@property (readonly) BOOL checkInProgress;

- (NSString *)currentAppVersion;
- (BWApp *)app;
- (NSArray *)apps;

+ (BWHockeyManager *)sharedHockeyController;

- (void) setUpdateURL:(NSString *)url;
- (void) setUpdateURL:(NSString *)url delegate:(id <BWHockeyControllerDelegate>)delegate;
- (void) checkForUpdate:(BWHockeyViewController *)hockeyViewController;
- (void) checkForUpdate;	// invoke this if you need to start a check process manually, e.g. if the hockey controller is set after the
                              // UIApplicationDidBecomeActiveNotification notification is sent by iOS
- (BWHockeyViewController *) hockeyViewController:(BOOL)modal;
- (void) unsetHockeyViewController;
- (void) showBetaUpdateView;	// shows the update information screen

@end

@protocol BWHockeyControllerDelegate <NSObject>

@optional
- (void) connectionOpened;	// Invoked when the internet connection is started, to let the app enable the activity indicator
- (void) connectionClosed;	// Invoked when the internet connection is closed, to let the app disable the activity indicator

- (HockeyComparisonResult) compareVersionType;

- (UIViewController *) viewControllerForHockeyController:(BWHockeyManager *)hockeyController;
// optional parent view controller for the update screen when invoked via the alert view, default is the root UIWindow instance

@end
