//
//  BWHockeyViewController.h
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
#import "PSStoreButton.h"
#import "PSTableViewController.h"
#import "PSAppStoreHeader.h"

typedef enum {
	AppStoreButtonStateNone,
	AppStoreButtonStateCheck,
	AppStoreButtonStateSearching,
	AppStoreButtonStateUpdate,
	AppStoreButtonStateInstalling
} AppStoreButtonState;


@class BWHockeyManager;

@interface BWHockeyViewController : PSTableViewController <PSStoreButtonDelegate, UIActionSheetDelegate, UIPickerViewDelegate, UIPickerViewDataSource> {
    BWHockeyManager *hockeyManager_;

    NSDictionary *cellLayout;

    BOOL modal_;
    BOOL showAllVersions_;
	UIStatusBarStyle statusBarStyle_;
    PSAppStoreHeader *appStoreHeader_;
    PSStoreButton *appStoreButton_;

    UIActionSheet *settingsSheet_;
    UIPickerView *settingPicker_;
    
    AppStoreButtonState appStoreButtonState_;

    NSMutableArray *cells_;
}

@property (nonatomic, retain) BWHockeyManager *hockeyManager;
@property (nonatomic, readwrite) BOOL modal;

- (id)init:(BWHockeyManager *)newHockeyController modal:(BOOL)newModal;
- (id)init;

- (void)redrawTableView;

@end
