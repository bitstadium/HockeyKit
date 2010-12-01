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
#import "BWHockeyViewController.h"


typedef enum {
	HockeyComparisonResultDifferent,
	HockeyComparisonResultGreater
} HockeyComparisonResult;

@protocol BWHockeyControllerDelegate;

@interface BWHockeyController : NSObject <UIAlertViewDelegate> {
	id <BWHockeyControllerDelegate> delegate;
    NSString *betaCheckUrl;
    NSMutableDictionary *betaDictionary;

	BWHockeyViewController *currentHockeyViewController;
	
	NSMutableData *_receivedData;
    
    BOOL checkInProgress;
    BOOL dataFound;
    
    NSURLConnection *urlConnection;
}

@property (nonatomic, assign) id <BWHockeyControllerDelegate> delegate;

@property (nonatomic, retain) NSString *betaCheckUrl;
@property (nonatomic, retain) NSMutableDictionary *betaDictionary;
@property (nonatomic, retain) NSURLConnection *urlConnection;

+ (BWHockeyController *)sharedHockeyController;

- (void) setBetaURL:(NSString *)url;
- (void) setBetaURL:(NSString *)url delegate:(id <BWHockeyControllerDelegate>)delegate;
- (void) checkForBetaUpdate:(BWHockeyViewController *)hockeyViewController;
- (void) checkForBetaUpdate;	// invoke this if you need to start a check process manually, e.g. if the hockey controller is set after the
								// UIApplicationDidBecomeActiveNotification notification is sent by iOS
- (BWHockeyViewController *) hockeyViewController:(BOOL)modal;
- (void) showBetaUpdateView;	// shows the update information screen

@end

@protocol BWHockeyControllerDelegate <NSObject>

@optional
- (void) connectionOpened;	// Invoked when the internet connection is started, to let the app enable the activity indicator
- (void) connectionClosed;	// Invoked when the internet connection is closed, to let the app disable the activity indicator

- (HockeyComparisonResult) compareVersionType;
    						// HockeyComparisonResultDifferent: alerts if the version on the server is different (default)
    						// HockeyComparisonResultGreater: alerts if the version on the server is greate

- (UIViewController*) rootViewController; // returns the viewController used for displaying the Views in 3.2

- (BOOL) showUpdateReminder;// if YES, the new version alert will be displayed always if the current version is outdated
    						// if NO, the alert will be displayed only once for each new update (default)

- (BOOL) showProfileData;	// if YES, the provisioning profile data is also shown in the update screen, if it is available on the server
    						// if NO, the provisioning profile data is not shown even if it is available on the server (default)

- (BOOL) sendCurrentData;	// if YES, the current user data is send: device type, iOS version, app version, UDID (default)
    						// if NO, no such data is send to the server

- (BOOL)shouldCheckForUpdateOnLaunch;  //if YES, then an update check will be performed after the application becomes active (default)
										//if NO, then the update check will not happen unless invoked explicitly


- (UIViewController *) viewControllerForHockeyController:(BWHockeyController *)hockeyController;
    						// optional parent view controller for the update screen when invoked via the alert view, default is the root UIWindow instance

@end
