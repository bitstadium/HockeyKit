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

#define khockeyLastCheck @"HockeyLastCheck"

@interface BWHockeyController : NSObject <UIAlertViewDelegate> {
	id <NSObject> delegate;
    NSString *betaCheckUrl;
    NSMutableDictionary *betaDictionary;

	BWHockeyViewController *currentHockeyViewController;
	
	NSMutableData *_receivedData;
}

@property (nonatomic, assign) id <NSObject> delegate;

@property (nonatomic, retain) NSString *betaCheckUrl;
@property (nonatomic, retain) NSMutableDictionary *betaDictionary;

+ (BWHockeyController *)sharedHockeyController;

- (void)setBetaURL:(NSString *)url;
- (void)setBetaURL:(NSString *)url delegate:(id <NSObject>)delegate;
- (void) checkForBetaUpdate:(BWHockeyViewController *)hockeyViewController;

- (BWHockeyViewController *)hockeyViewController:(BOOL)modal;

@end

@interface NSObject (BWHockeyControllerDelegate)

-(void) connectionOpened;	// Invoked when the internet connection is started, to let the app enable the activity indicator
-(void) connectionClosed;	// Invoked when the internet connection is closed, to let the app disable the activity indicator

@end