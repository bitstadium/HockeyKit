//
//  BWHockeyViewController.m
//
//  Created by Andreas Linde on 8/17/10.
//  Copyright 2010-2011 Andreas Linde, Peter Steinberger. All rights reserved.
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

#import <QuartzCore/QuartzCore.h>
#import "NSString+HockeyAdditions.h"
#import "BWHockeyViewController.h"
#import "BWHockeyManager.h"
#import "BWGlobal.h"
#import "UIImage+HockeyAdditions.h"
#import "PSWebTableViewCell.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define kWebCellIdentifier @"PSWebTableViewCell"
#define kAppStoreViewHeight 90

@interface BWHockeyViewController ()
// updates the whole view
- (void)redrawTableView;
@property (nonatomic, assign) AppStoreButtonState appStoreButtonState;
- (void)setAppStoreButtonState:(AppStoreButtonState)anAppStoreButtonState animated:(BOOL)animated;
@end


@implementation BWHockeyViewController

@synthesize appStoreButtonState = appStoreButtonState_;
@synthesize hockeyManager = hockeyManager_;
@synthesize modal = modal_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)restoreStoreButtonStateAnimated_:(BOOL)animated {
    if ([self.hockeyManager isUpdateURLOffline]) {
        [self setAppStoreButtonState:AppStoreButtonStateOffline animated:animated];
    }else if ([self.hockeyManager isUpdateAvailable]) {
        [self setAppStoreButtonState:AppStoreButtonStateUpdate animated:animated];
    }else {
        [self setAppStoreButtonState:AppStoreButtonStateCheck animated:animated];
    }
}

- (void)updateAppStoreHeader_ {
    BWApp *app = self.hockeyManager.app;
    appStoreHeader_.headerLabel = app.name;
    NSString *shortVersion = app.shortVersion ? [NSString stringWithFormat:@"%@ ", app.shortVersion] : @"";
    NSString *version = [shortVersion length] ? [NSString stringWithFormat:@"(%@)",app.version] : app.version;
    appStoreHeader_.middleHeaderLabel = [NSString stringWithFormat:@"%@ %@%@", BWLocalize(@"HockeyVersion"), shortVersion, version];
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    NSMutableString *subHeaderString = [NSMutableString string];
    if (app.date) {
        [subHeaderString appendString:[formatter stringFromDate:app.date]];
    }
    if (app.size) {
        if ([subHeaderString length]) {
            [subHeaderString appendString:@" - "];
        }
        [subHeaderString appendString:app.sizeInMB];
    }
    appStoreHeader_.subHeaderLabel = subHeaderString;
}

- (void)closeSettings {
    [settingsSheet_ dismissWithClickedButtonIndex:[settingPicker_ selectedRowInComponent:0] animated:YES];
}


- (void)appDidBecomeActive_ {
    if (self.appStoreButtonState == AppStoreButtonStateInstalling) {
        [self setAppStoreButtonState:AppStoreButtonStateUpdate animated:YES];
    }
}

- (void)openSettings:(id)sender {
    [settingPicker_ release]; settingsSheet_ = nil;
    [settingsSheet_ release]; settingsSheet_ = nil;
    
    settingPicker_ = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 44.0, 0.0, 0.0)];
    settingPicker_.showsSelectionIndicator = YES;
    settingPicker_.dataSource = self;
    settingPicker_.delegate = self;
    [settingPicker_ selectRow:[self.hockeyManager updateSetting] inComponent:0 animated:NO];
    
    Class popoverControllerClass = NSClassFromString(@"UIPopoverController");
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && popoverControllerClass) {
        UIViewController *pickerViewController = [[[UIViewController alloc] init] autorelease];
        [pickerViewController.view addSubview:settingPicker_];
        
        id popOverController = [[popoverControllerClass alloc] initWithContentViewController:pickerViewController];
        [popOverController setPopoverContentSize: CGSizeMake(300, 216)];
        
        // show popover
        CGSize sizeOfPopover = CGSizeMake(300, 222);
        CGPoint positionOfPopover = [sender view].frame.origin;
        settingPicker_.frame = CGRectMake(0, 0, sizeOfPopover.width, sizeOfPopover.height);
        [popOverController presentPopoverFromRect:CGRectMake(positionOfPopover.x, positionOfPopover.y, sizeOfPopover.width, sizeOfPopover.height)
                                           inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else {
        settingsSheet_ = [[UIActionSheet alloc] initWithTitle:@"Settings"
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:nil];
        
        UIToolbar *pickerToolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] autorelease];
        pickerToolbar.barStyle = UIBarStyleBlackOpaque;
        [pickerToolbar sizeToFit];
        
        NSMutableArray *barItems = [[[NSMutableArray alloc] init] autorelease];
        
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        [barItems addObject:flexSpace];
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
        [barItems addObject:doneBtn];
        
        [pickerToolbar setItems:barItems animated:YES];
        
        [settingsSheet_ addSubview:pickerToolbar];
        [settingsSheet_ addSubview:settingPicker_];
        [settingsSheet_ showInView:self.view];
        
        [UIView beginAnimations:nil context:nil];
        [settingsSheet_ setBounds:CGRectMake(0, 0, self.view.frame.size.width, settingPicker_.frame.size.height*2+40)];
        if(self.view.frame.size.width > 320) { // ugly partial landscape fix
            CGRect frame = settingPicker_.frame;
            frame.origin.y = 32;
            settingPicker_.frame = frame;
            [settingsSheet_ setBounds:CGRectMake(0, 0, self.view.frame.size.width, settingPicker_.frame.size.height*2+10)];
        }
        
        [UIView commitAnimations];
    }
}

- (UIImage *)addGlossToImage_:(UIImage *)image {
    IF_IOS4_OR_GREATER(UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);)
    IF_PRE_IOS4(UIGraphicsBeginImageContext(image.size);)
    
    [image drawAtPoint:CGPointZero];
    UIImage *iconGradient = [UIImage bw_imageNamed:@"IconGradient.png" bundle:kHockeyBundleName];
    [iconGradient drawInRect:CGRectMake(0, 0, image.size.width, image.size.height) blendMode:kCGBlendModeNormal alpha:0.5];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

#define kMinPreviousVersionButtonHeight 100
- (void)realignPreviousVersionButton {
    
    // manually collect actual table height size
    NSUInteger tableViewContentHeight = 0;
    for (int i=0; i < [self tableView:self.tableView numberOfRowsInSection:0]; i++) {
        tableViewContentHeight += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    tableViewContentHeight += self.tableView.tableHeaderView.frame.size.height;
    
    NSUInteger footerViewSize = kMinPreviousVersionButtonHeight;
    NSUInteger frameHeight = self.view.frame.size.height;
    if(tableViewContentHeight < frameHeight && (frameHeight - tableViewContentHeight > 100)) {
        footerViewSize = frameHeight - tableViewContentHeight;
    }
    
    // update footer view
    if(self.tableView.tableFooterView) {
        CGRect frame = self.tableView.tableFooterView.frame;
        frame.size.height = footerViewSize;
        self.tableView.tableFooterView.frame = frame;
    }
}

- (void)showHidePreviousVersionsButton {
    BOOL multipleVersionButtonNeeded = [self.hockeyManager.apps count] > 1 && !showAllVersions_;
    
    if(multipleVersionButtonNeeded) {
        // align at the bottom if tableview is small
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kMinPreviousVersionButtonHeight)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIButton *footerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        IF_IOS4_OR_GREATER(
                           //footerButton.layer.shadowOffset = CGSizeMake(-2, 2);
                           footerButton.layer.shadowColor = [[UIColor blackColor] CGColor];
                           footerButton.layer.shadowRadius = 2.0f;
                           )
        footerButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [footerButton setTitle:BWLocalize(@"HockeyShowPreviousVersions") forState:UIControlStateNormal];
        [footerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        footerButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [footerButton addTarget:self action:@selector(showPreviousVersionAction) forControlEvents:UIControlEventTouchUpInside];
        footerButton.frame = CGRectMake(0, kMinPreviousVersionButtonHeight-44, self.view.frame.size.width, 44);
        footerButton.backgroundColor = RGBCOLOR(183,183,183);
        [footerView addSubview:footerButton];
        self.tableView.tableFooterView = footerView;
        [self realignPreviousVersionButton];
    }else {
        self.tableView.tableFooterView = nil;
    }
}

- (void)configureWebCell:(PSWebTableViewCell *)cell forApp_:(BWApp *)app {
    // create web view for a version
    NSString *installed = @"";
    if ([app.version isEqualToString:[self.hockeyManager currentAppVersion]]) {
        installed = [NSString stringWithFormat:@"<span style=\"float:%@;text-shadow:rgba(255,255,255,0.6) 1px 1px 0px;\"><b>%@</b></span>", [app isEqual:self.hockeyManager.app] ? @"left" : @"right", BWLocalize(@"HockeyInstalled")];
    }
    
    if ([app isEqual:self.hockeyManager.app]) {
        if ([app.notes length] > 0) {
            installed = [NSString stringWithFormat:@"<p>&nbsp;%@</p>", installed];
            cell.webViewContent = [NSString stringWithFormat:@"%@%@", installed, app.notes];
        }else {
            cell.webViewContent = [NSString stringWithFormat:@"<div style=\"min-height:200px;vertical-align:middle;text-align:center;text-shadow:rgba(255,255,255,0.6) 1px 1px 0px;\">%@</div>", BWLocalize(@"HockeyNoReleaseNotesAvailable")];
        }
    } else {
        cell.webViewContent = [NSString stringWithFormat:@"<p><b style=\"text-shadow:rgba(255,255,255,0.6) 1px 1px 0px;\">%@</b>%@<br/><small>%@</small></p><p>%@</p>", [app versionString], installed, [app dateString], [app notesOrEmptyString]];
    }
    [cell addWebView];
    // hack
    cell.textLabel.text = @"";
    
    [cell addObserver:self forKeyPath:@"webViewSize" options:0 context:nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init:(BWHockeyManager *)newHockeyManager modal:(BOOL)newModal {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.hockeyManager = newHockeyManager;
        self.modal = newModal;
        self.title = BWLocalize(@"HockeyUpdateScreenTitle");
        
        if ([self.hockeyManager shouldShowUserSettings]) {
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage bw_imageNamed:@"gear.png" bundle:kHockeyBundleName]
                                                                                       style:UIBarButtonItemStyleBordered
                                                                                      target:self
                                                                                      action:@selector(openSettings:)] autorelease];
        }
        
        cells_ = [[NSMutableArray alloc] initWithCapacity:5];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(appDidBecomeActive_) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        // hook into manager with kvo!
        [self.hockeyManager addObserver:self forKeyPath:@"checkInProgress" options:0 context:nil];
        [self.hockeyManager addObserver:self forKeyPath:@"isUpdateURLOffline" options:0 context:nil];
        [self.hockeyManager addObserver:self forKeyPath:@"updateAvailable" options:0 context:nil];
        [self.hockeyManager addObserver:self forKeyPath:@"apps" options:0 context:nil];
    }
    return self;
}

- (id)init {
	return [self init:[BWHockeyManager sharedHockeyManager] modal:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.hockeyManager removeObserver:self forKeyPath:@"checkInProgress"];
    [self.hockeyManager removeObserver:self forKeyPath:@"isUpdateURLOffline"];
    [self.hockeyManager removeObserver:self forKeyPath:@"updateAvailable"];
    [self.hockeyManager removeObserver:self forKeyPath:@"apps"];
    [self viewDidUnload];
    for (UITableViewCell *cell in cells_) {
        [cell removeObserver:self forKeyPath:@"webViewSize"];
    }
    [cells_ release];
    [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View lifecycle

- (void)onAction:(id)sender {
    if (self.modal) {
        
		if (self.navigationController.parentViewController) {
			[self.navigationController dismissModalViewControllerAnimated:YES];
		} else {
			[self.navigationController.view removeFromSuperview];
			[self.navigationController release];
		}
	}
    else
		[self.navigationController popViewControllerAnimated:YES];
    
	[[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle_];
    
}

- (CAGradientLayer *)backgroundLayer {
	UIColor *colorOne	= [UIColor colorWithWhite:0.9 alpha:1.0];
	UIColor *colorTwo	= [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.85 alpha:1.0];
	UIColor *colorThree	= [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.7 alpha:1.0];
	UIColor *colorFour	= [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.4 alpha:1.0];
    
	NSArray *colors     = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, colorThree.CGColor, colorFour.CGColor, nil];
    
	NSNumber *stopOne	= [NSNumber numberWithFloat:0.0];
	NSNumber *stopTwo	= [NSNumber numberWithFloat:0.02];
	NSNumber *stopThree = [NSNumber numberWithFloat:0.99];
	NSNumber *stopFour  = [NSNumber numberWithFloat:1.0];
    
	NSArray *locations  = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, stopFour, nil];
    
	CAGradientLayer *headerLayer = [CAGradientLayer layer];
	//headerLayer.frame = CGRectMake(0.0, 0.0, 320.0, 77.0);
	headerLayer.colors = colors;
	headerLayer.locations = locations;
    
	return headerLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = RGBCOLOR(200, 202, 204);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIView *topView = [[[UIView alloc] initWithFrame:CGRectMake(0, -(600-kAppStoreViewHeight), self.view.frame.size.width, 600)] autorelease];
    topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topView.backgroundColor = RGBCOLOR(140, 141, 142);
    [self.tableView addSubview:topView];
    
    appStoreHeader_ = [[PSAppStoreHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kAppStoreViewHeight)];
    [self updateAppStoreHeader_];
    
    NSString *iconString;
    NSArray *icons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFiles"];
    if (!icons) {
        iconString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];
    } else {
        BOOL useHighResIcon = NO;
        IF_IOS4_OR_GREATER(if ([UIScreen mainScreen].scale == 2.0f) useHighResIcon = YES;)
        
        for(NSString *icon in icons) {
            iconString = icon;
            UIImage *iconImage = [UIImage imageNamed:icon];
            
            if (iconImage.size.height == 57 && !useHighResIcon) {
                // found!
                break;
            }
            if (iconImage.size.height == 114 && useHighResIcon) {
                // found!
                break;
            }
        }
    }
    
    BOOL addGloss = YES;
    NSNumber *prerendered = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIPrerenderedIcon"];
    if (prerendered) {
        addGloss = ![prerendered boolValue];
    }
    
    if (addGloss) {
        appStoreHeader_.iconImage = [self addGlossToImage_:[UIImage imageNamed:iconString]];
    } else {
        appStoreHeader_.iconImage = [UIImage imageNamed:iconString];
    }
    
    self.tableView.tableHeaderView = appStoreHeader_;
    
    if (self.modal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(onAction:)];
    }
    
    PSStoreButton *storeButton = [[[PSStoreButton alloc] initWithPadding:CGPointMake(5, 40)] autorelease];
    storeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    storeButton.buttonDelegate = self;
    [self.tableView.tableHeaderView addSubview:storeButton];
    storeButton.buttonData = [PSStoreButtonData dataWithLabel:@"" colors:[PSStoreButton appStoreGrayColor] enabled:NO];
    self.appStoreButtonState = AppStoreButtonStateCheck;
    [storeButton alignToSuperview];
    appStoreButton_ = [storeButton retain];
    
    [self redrawTableView];
}

- (void) viewWillAppear:(BOOL)animated {
    self.hockeyManager.currentHockeyViewController = self;
    [super viewWillAppear:animated];
    statusBarStyle_ = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:(self.navigationController.navigationBar.barStyle == UIBarStyleDefault) ? UIStatusBarStyleDefault : UIStatusBarStyleBlackOpaque];
}

- (void) viewWillDisappear:(BOOL)animated {
    self.hockeyManager.currentHockeyViewController = nil;
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle_];
}

- (void)redrawTableView {
    [self restoreStoreButtonStateAnimated_:NO];
    [self updateAppStoreHeader_];
    
    // clean up and remove any pending overservers
    for (UITableViewCell *cell in cells_) {
        [cell removeObserver:self forKeyPath:@"webViewSize"];
    }
    [cells_ removeAllObjects];
    
    for (BWApp *app in self.hockeyManager.apps) {
        PSWebTableViewCell *cell = [[[PSWebTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebCellIdentifier] autorelease];
        [self configureWebCell:cell forApp_:app];
        [cells_ addObject:cell];
        
        // stop on first app if we don't show all versions
        if (!showAllVersions_) {
            break;
        }
    }
    
    [self.tableView reloadData];
    [self showHidePreviousVersionsButton];
}

- (void)showPreviousVersionAction {
    showAllVersions_ = YES;
    
    [self.tableView beginUpdates];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[self.hockeyManager.apps count]-1];
    for (BWApp *app in self.hockeyManager.apps) {
        if ([app isEqual:self.hockeyManager.app]) {
            continue; // skip first
        }
        
        PSWebTableViewCell *cell = [[[PSWebTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebCellIdentifier] autorelease];
        [self configureWebCell:cell forApp_:app];
        [cells_ addObject:cell];
        [indexPaths addObject:[NSIndexPath indexPathForRow:[cells_ count]-1 inSection:0]];
    }
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [self showHidePreviousVersionsButton];
}

- (void)viewDidUnload {
    [appStoreHeader_ release]; appStoreHeader_ = nil;
    [super viewDidUnload];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight = 0;
    
    if ([cells_ count] > indexPath.row) {
        PSWebTableViewCell *cell = [cells_ objectAtIndex:indexPath.row];
        rowHeight = cell.webViewSize.height;
    }
    
    if (rowHeight == 0) {
        rowHeight = indexPath.row == 0 ? 250 : 44; // fill screen on startup
    }
    
    return rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger cellCount = [cells_ count];
    return cellCount;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"webViewSize"]) {
        NSInteger index = [cells_ indexOfObject:object];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self realignPreviousVersionButton];
    }else if ([keyPath isEqualToString:@"checkInProgress"]) {
        if (self.hockeyManager.isCheckInProgress) {
            [self setAppStoreButtonState:AppStoreButtonStateSearching animated:YES];
        }else {
            [self restoreStoreButtonStateAnimated_:YES];
        }
    }else if ([keyPath isEqualToString:@"isUpdateURLOffline"]) {
        [self restoreStoreButtonStateAnimated_:YES];
    }else if ([keyPath isEqualToString:@"updateAvailable"]) {
        [self restoreStoreButtonStateAnimated_:YES];
        //[self redrawTableView];
    }else if ([keyPath isEqualToString:@"apps"]) {
        [self redrawTableView];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cells_ count] > indexPath.row) {
        return [cells_ objectAtIndex:indexPath.row];
    }else {
        BWLog(@"Warning: cells_ and indexPath do not match? forgot calling redrawTableView?");
    }
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIPickerView delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        // on startup
        return BWLocalize(@"HockeySectionCheckStartup");
    } else if (row == 1) {
        // daily    
        return BWLocalize(@"HockeySectionCheckDaily");
    } else {
        // manually
        return BWLocalize(@"HockeySectionCheckManually");
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 3;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        // on startup
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:HockeyUpdateCheckStartup] forKey:kHockeyAutoUpdateSetting];
        [self.hockeyManager setUpdateSetting: HockeyUpdateCheckStartup];
    } else if (row == 1) {
        // daily
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:HockeyUpdateCheckDaily] forKey:kHockeyAutoUpdateSetting];
        [self.hockeyManager setUpdateSetting: HockeyUpdateCheckDaily];
    } else {
        // manually
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:HockeyUpdateCheckManually] forKey:kHockeyAutoUpdateSetting];
        [self.hockeyManager setUpdateSetting: HockeyUpdateCheckManually];
    }
    
    // persist the new value
    [[NSUserDefaults standardUserDefaults] synchronize];    
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldAutorotate;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        shouldAutorotate = (interfaceOrientation == UIInterfaceOrientationPortrait ||
                            interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
                            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
    } else {
        shouldAutorotate = YES;
    }
    
    return shouldAutorotate;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    // update all cells
    [cells_ makeObjectsPerformSelector:@selector(addWebView)];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark PSAppStoreHeaderDelegate

- (void)setAppStoreButtonState:(AppStoreButtonState)anAppStoreButtonState {
    [self setAppStoreButtonState:anAppStoreButtonState animated:NO];
}

- (void)setAppStoreButtonState:(AppStoreButtonState)anAppStoreButtonState animated:(BOOL)animated {
    appStoreButtonState_ = anAppStoreButtonState;
    
    switch (anAppStoreButtonState) {
        case AppStoreButtonStateOffline:
            [appStoreButton_ setButtonData:[PSStoreButtonData dataWithLabel:BWLocalize(@"HockeyButtonOffline") colors:[PSStoreButton appStoreGrayColor] enabled:NO] animated:animated];
            break;
        case AppStoreButtonStateCheck:
            [appStoreButton_ setButtonData:[PSStoreButtonData dataWithLabel:BWLocalize(@"HockeyButtonCheck") colors:[PSStoreButton appStoreGreenColor] enabled:YES] animated:animated];
            break;
        case AppStoreButtonStateSearching:
            [appStoreButton_ setButtonData:[PSStoreButtonData dataWithLabel:BWLocalize(@"HockeyButtonSearching") colors:[PSStoreButton appStoreGrayColor] enabled:NO] animated:animated];
            break;
        case AppStoreButtonStateUpdate:
            [appStoreButton_ setButtonData:[PSStoreButtonData dataWithLabel:BWLocalize(@"HockeyButtonUpdate") colors:[PSStoreButton appStoreBlueColor] enabled:YES] animated:animated];
            break;
        case AppStoreButtonStateInstalling:
            [appStoreButton_ setButtonData:[PSStoreButtonData dataWithLabel:BWLocalize(@"HockeyButtonInstalling") colors:[PSStoreButton appStoreGrayColor] enabled:NO] animated:animated];
            break;
        default:
            break;
    }
}

- (void)storeButtonFired:(PSStoreButton *)button {
    switch (appStoreButtonState_) {
        case AppStoreButtonStateCheck:
            [self.hockeyManager checkForUpdateShowFeedback:YES];
            break;
        case AppStoreButtonStateUpdate:
            if ([self.hockeyManager initiateAppDownload]) {
                [self setAppStoreButtonState:AppStoreButtonStateInstalling animated:YES];
            };
            break;
        default:
            break;
    }
}

@end
