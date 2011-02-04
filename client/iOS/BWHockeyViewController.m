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
#import "NSString+URLEncoding.h"
#import "BWHockeyViewController.h"
#import "BWHockeyManager.h"
#import "BWWebViewController.h"
#import "BWGlobal.h"
#import "UIImage+HockeyAdditions.h"
#import "PSWebTableViewCell.h"

#define kWebCellIdentifier @"PSWebTableViewCell"
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

@implementation BWHockeyViewController

@synthesize hockeyManager = hockeyManager_;
@synthesize modal = modal_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)openSettings:(id)sender {
  
}

// apply gloss
- (UIImage *)addGloss:(UIImage *)image {
  UIGraphicsBeginImageContext(image.size);
  
  [image drawAtPoint:CGPointZero];
  UIImage *iconGradient = [UIImage imageNamed:@"IconGradient.png"];
  [iconGradient drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:0.5];
  
  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return result;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init:(BWHockeyManager *)newHockeyController modal:(BOOL)newModal {
  if ((self = [super initWithStyle:UITableViewStylePlain])) {
    self.hockeyManager = newHockeyController;
    self.modal = newModal;
    self.title = BWLocalize(@"HockeyUpdateScreenTitle");
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png" bundle:kHockeyBundleName]
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(openSettings:)] autorelease];
    
    cells_ = [[NSMutableArray alloc] initWithCapacity:5];
    
  }
  return self;
}

- (id)init {
	return [self init:[BWHockeyManager sharedHockeyController] modal:NO];
}

- (void)dealloc {
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
	UIColor *colorOne		= [UIColor colorWithWhite:0.9 alpha:1.0];
	UIColor *colorTwo		= [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.85 alpha:1.0];
	UIColor *colorThree = [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.7 alpha:1.0];
	UIColor *colorFour	= [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.4 alpha:1.0];
  
	NSArray *colors     = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, colorThree.CGColor, colorFour.CGColor, nil];
  
	NSNumber *stopOne		= [NSNumber numberWithFloat:0.0];
	NSNumber *stopTwo		= [NSNumber numberWithFloat:0.02];
	NSNumber *stopThree = [NSNumber numberWithFloat:0.99];
	NSNumber *stopFour  = [NSNumber numberWithFloat:1.0];
  
	NSArray *locations  = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, stopFour, nil];
  
	CAGradientLayer *headerLayer = [CAGradientLayer layer];
	//headerLayer.frame = CGRectMake(0.0, 0.0, 320.0, 77.0);
	headerLayer.colors = colors;
	headerLayer.locations = locations;
  
	return headerLayer;
}

#define kAppStoreViewHeight 90
- (void)viewDidLoad {
  [super viewDidLoad];
  
  //self.view.backgroundColor = RGBCOLOR(140, 141, 142);
  self.tableView.backgroundColor = RGBCOLOR(200, 202, 204);
  
  UIView *topView = [[[UIView alloc] initWithFrame:CGRectMake(0, -(600-kAppStoreViewHeight), self.view.frame.size.width, 600)] autorelease];
  topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  topView.backgroundColor = RGBCOLOR(140, 141, 142);
  [self.tableView addSubview:topView];
  //  self.tableView.contentInset = UIEdgeInsetsMake(600-kAppStoreViewHeight, 0, 0, 0);
  
  // DEBUG
  //  self.tableView.layer.borderColor = [[UIColor orangeColor] CGColor];
  //self.tableView.layer.borderWidth = 2.0;
  
  appStoreHeader_ = [[PSAppStoreHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kAppStoreViewHeight)];
  appStoreHeader_.headerLabel = self.hockeyManager.app.name;
  NSString *appSize = [NSString stringWithFormat:@", %@", self.hockeyManager.app.sizeInMB];
  appStoreHeader_.middleHeaderLabel = [NSString stringWithFormat:@"%@ %@%@", BWLocalize(@"HockeyVersion"), self.hockeyManager.app.version, appSize];
  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
  [formatter setDateStyle:NSDateFormatterMediumStyle];
  appStoreHeader_.subHeaderLabel = self.hockeyManager.app.date ? [formatter stringFromDate:self.hockeyManager.app.date] : nil;
  //appStoreHeader_.iconImage = //[UIImage imageNamed:@"AngryBirds.png"];
  
  NSString *iconString;
  NSArray *icons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFiles"];
  if (!icons) {
    iconString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];
  }else {
    BOOL useHighResIcon = NO;
    IF_IOS4_OR_GREATER(if ([UIScreen mainScreen].scale == 2.0f) useHighResIcon = YES;)
    
    for(NSString *icon in icons) {
      iconString = icon;
      UIImage *iconImage = [UIImage imageNamed:icon];
      
      if(iconImage.size.height == 57 && !useHighResIcon) {
        // found!
        break;
      }
      if(iconImage.size.height == 114 && useHighResIcon) {
        // found!
        break;
      }
    }
  }
  appStoreHeader_.iconImage = [self addGloss:[UIImage imageNamed:iconString]];
  
  
  self.tableView.tableHeaderView = appStoreHeader_;
  
  if (self.modal) {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(onAction:)];
  }
  
  PSStoreButton *storeButton = [[[PSStoreButton alloc] initWithFrame:CGRectMake(0, 0, 85.0, 22.0)] autorelease];
  storeButton.buttonDelegate = self;
  storeButton.buttonData = [PSStoreButtonData dataWithLabel:@"Update" colors:[PSStoreButton appStoreGreenColor] enabled:YES];
  storeButton.center = CGPointMake(250, 55);
	[self.tableView addSubview:storeButton];
  
  [self redrawTableView];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	statusBarStyle_ = [[UIApplication sharedApplication] statusBarStyle];
	[[UIApplication sharedApplication] setStatusBarStyle:(self.navigationController.navigationBar.barStyle == UIBarStyleDefault) ? UIStatusBarStyleDefault : UIStatusBarStyleBlackOpaque];
}

- (void) viewWillDisappear:(BOOL)animated {
  [self.hockeyManager unsetHockeyViewController];
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle_];
}

- (void)redrawTableView {
  if (![cells_ count]) {
    
    for (BWApp *app in self.hockeyManager.apps) {
      PSWebTableViewCell *cell = [[[PSWebTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebCellIdentifier] autorelease];
      cell.webViewContent = app.notes;
      [cell addObserver:self forKeyPath:@"webViewSize" options:0 context:nil];
      [cells_ addObject:cell];
      
      /*
       switch (i) {
       case 0:
       cell.webView.backgroundColor = [UIColor yellowColor];
       break;
       case 1:
       cell.webView.backgroundColor = [UIColor orangeColor];
       break;
       case 2:
       cell.webView.backgroundColor = [UIColor redColor];
       break;
       case 3:
       cell.webView.backgroundColor = [UIColor greenColor];
       break;
       case 4:
       cell.webView.backgroundColor = [UIColor blueColor];
       break;
       default:
       break;
       }
       */
    }
  }
  
  
  
  
  // [self.tableView reloadData];
  /*
   int currentNumberOfSections = [self.tableView numberOfSections];
   int sectionsToShow = [self numberOfSectionsInTableView:self.tableView];
   
   [self.tableView beginUpdates];
   
   // show the rows that should be visible
   // is this row visible?
   for (int i = 0; i < sectionsToShow; i++) {
   // is this row visible?
   if (i < currentNumberOfSections) {
   [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:i]
   withRowAnimation:UITableViewRowAnimationFade];
   } else {
   [self.tableView insertSections:[NSIndexSet indexSetWithIndex:i]
   withRowAnimation:UITableViewRowAnimationFade];
   }
   }
   
   // do we need to remove rows?
   if (currentNumberOfSections > 1) {
   for (int i = 1; i < currentNumberOfSections; i++) {
   [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:i]
   withRowAnimation:UITableViewRowAnimationFade];
   }
   }
   
   [self.tableView endUpdates];
   */
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
    BWLog(@"index: %d has zero height!", indexPath.row);
    rowHeight = 44;
  }
  /*
   if (self.hockeyController.checkInProgress)
   return rowHeight;
   
   int startIndexOfSettings = [self sectionIndexOfSettings];
   
   if (indexPath.section == startIndexOfSettings - 1) {
   if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0" options:NSNumericSearch] < NSOrderedSame) {
   rowHeight = 88;
   }
   }*/
  
  return rowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [cells_ count];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  NSInteger index = [cells_ indexOfObject:object];
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];   
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ([cells_ count] > indexPath.row) {
    return [cells_ objectAtIndex:indexPath.row];
  }else {
    BWLog(@"Warning: cells_ and indexPath do not match? forgot calling redrawTableView?");
  }
  
  
  /*
   
   PSWebTableViewCell *cell = (PSWebTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kWebCellIdentifier];
   
   if (!cell) {
   cell = [[[PSWebTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWebCellIdentifier] autorelease];
   }
   */
  
  //  return cell;
  
  // HACK
  
  
  /*
   // 2 lines cell
   static NSString *BetaCell1Identifier = @"BetaCell1";
   // 1 line cell with discolure
   static NSString *BetaCell2Identifier = @"BetaCell2";
   // 1 line cell with value
   static NSString *BetaCell3Identifier = @"BetaCell3";
   // check cell
   static NSString *BetaCell4Identifier = @"BetaCell4";
   
   UITableViewCell *cell = nil;
   
   NSString *requiredIdentifier = BetaCell1Identifier;
   NSInteger cellStyle = UITableViewCellStyleSubtitle;
   
   if (self.hockeyController.checkInProgress &&
   indexPath.section == 0 &&
   indexPath.row == 0) {
   cell = [tableView dequeueReusableCellWithIdentifier:BetaCell3Identifier];
   
   if (cell == nil) {
   cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:requiredIdentifier] autorelease];
   }
   
   cell.accessoryType = UITableViewCellAccessoryNone;
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   cell.textLabel.text = BWLocalize(@"HockeySectionCheckProgress");
   cell.textLabel.textAlignment = UITextAlignmentCenter;
   cell.textLabel.textColor = [UIColor grayColor];
   
   return cell;
   }
   
   int startIndexOfSettings = [self sectionIndexOfSettings];
   
   // preselect the required cell style
   if (indexPath.section == startIndexOfSettings - 2 && indexPath.row == 2) {
   // we need a one line cell with discloure
   requiredIdentifier = BetaCell2Identifier;
   cellStyle = UITableViewCellStyleDefault;
   } else if (indexPath.section == startIndexOfSettings + 1 ||
   indexPath.section == startIndexOfSettings - 1) {
   // we need a button style
   requiredIdentifier = BetaCell3Identifier;
   cellStyle = UITableViewCellStyleDefault;
   } else if (indexPath.section == startIndexOfSettings) {
   // we need a check cell
   requiredIdentifier = BetaCell4Identifier;
   cellStyle = UITableViewCellStyleDefault;
   }
   
   cell = [tableView dequeueReusableCellWithIdentifier:requiredIdentifier];
   
   if (cell == nil) {
   cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:requiredIdentifier] autorelease];
   }
   
   cell.accessoryType = UITableViewCellAccessoryNone;
   cell.selectionStyle = UITableViewCellSelectionStyleBlue;
   
   if (indexPath.section == startIndexOfSettings + 1) {
   // check again button
   cell.textLabel.text = BWLocalize(@"HockeySectionCheckButton");
   cell.textLabel.textAlignment = UITextAlignmentCenter;
   cell.textLabel.textColor = [UIColor blackColor];
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   } else if (indexPath.section == startIndexOfSettings) {
   // update check interval selection
   
   NSNumber *hockeyAutoUpdateSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting];
   if (indexPath.row == 0) {
   // on startup
   cell.textLabel.text = BWLocalize(@"HockeySectionCheckStartup");
   if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_STARTUP) {
   cell.accessoryType = UITableViewCellAccessoryCheckmark;
   }
   } else if (indexPath.row == 1) {
   // daily
   cell.textLabel.text = BWLocalize(@"HockeySectionCheckDaily");
   if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_DAILY) {
   cell.accessoryType = UITableViewCellAccessoryCheckmark;
   }
   } else {
   // manually
   cell.textLabel.text = BWLocalize(@"HockeySectionCheckManually");
   if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_MANUAL) {
   cell.accessoryType = UITableViewCellAccessoryCheckmark;
   }
   }
   } else if (indexPath.section == startIndexOfSettings - 1) {
   if ([[self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION] compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] == NSOrderedSame) {
   cell.textLabel.text = BWLocalize(@"HockeySectionAppSameVersionButton");
   cell.textLabel.textColor = [UIColor grayColor];
   cell.textLabel.textAlignment = UITextAlignmentCenter;
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   } else if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0" options:NSNumericSearch] < NSOrderedSame) {
   cell.textLabel.text = BWLocalize(@"HockeySectionAppWebsite");
   cell.textLabel.numberOfLines = 3;
   cell.textLabel.textColor = [UIColor grayColor];
   cell.textLabel.textAlignment = UITextAlignmentLeft;
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   } else {
   // install application button
   cell.textLabel.text = BWLocalize(@"HockeySectionAppButton");
   cell.textLabel.textColor = [UIColor blackColor];
   cell.textLabel.textAlignment = UITextAlignmentCenter;
   }
   } else if (indexPath.section == startIndexOfSettings - 2) {
   // last application update information
   if (indexPath.row == 0) {
   // app name
   cell.textLabel.text = ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_TITLE] != [NSNull null]) ? [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_TITLE] : nil;
   cell.detailTextLabel.text = nil;
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   } else if (indexPath.row == 1) {
   // app version
   
   // if subtitle is set, then use it as main version number, since the version field is used for the build number
   NSString *versionString = nil;
   NSString *currentVersionString = nil;
   
   if ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_SUBTITLE] != nil) {
   versionString = [NSString stringWithFormat:@"%@ (%@)",
   [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_SUBTITLE],
   [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION]
   ];
   } else {
   versionString = [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION];
   }
   
   cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", BWLocalize(@"HockeySectionAppNewVersion"), versionString];
   
   if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] != nil) {
   currentVersionString = [NSString stringWithFormat:@"%@ (%@)",
   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
   ];
   } else {
   currentVersionString = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
   }
   
   cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", BWLocalize(@"HockeySectionAppCurrentVersion"), currentVersionString];
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   } else {
   // release notes
   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   cell.textLabel.text = BWLocalize(@"HockeySectionAppReleaseNotes");
   }
   }
   
   return cell;
   */
  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  /*
   [tableView deselectRowAtIndexPath:indexPath animated:YES];
   
   if (self.hockeyController.checkInProgress) {
   return;
   }
   
   int startIndexOfSettings = [self sectionIndexOfSettings];
   
   NSString *url = nil;
   
   if (indexPath.section == startIndexOfSettings + 1) {
   // check again button
   if (!self.hockeyController.checkInProgress) {
   [self.hockeyController checkForUpdate:self];
   [self redrawTableView];
   }
   } else if (indexPath.section == startIndexOfSettings) {
   // update check interval selection
   if (indexPath.row == 0) {
   // on startup
   [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:BETA_UPDATE_CHECK_STARTUP] forKey:kHockeyAutoUpdateSetting];
   } else if (indexPath.row == 1) {
   // daily
   [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:BETA_UPDATE_CHECK_DAILY] forKey:kHockeyAutoUpdateSetting];
   } else {
   // manually
   [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:BETA_UPDATE_CHECK_MANUAL] forKey:kHockeyAutoUpdateSetting];
   }
   
   // persist the new value
   [[NSUserDefaults standardUserDefaults] synchronize];
   [tableView reloadData];
   } else if (indexPath.section == startIndexOfSettings - 1) {
   if ([[self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION] compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame) {
   // install application button
   NSString *parameter = [NSString stringWithFormat:@"?type=%@&bundleidentifier=%@", BETA_DOWNLOAD_TYPE_APP, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
   NSString *temp = [NSString stringWithFormat:@"%@%@", self.hockeyController.updateUrl, parameter];
   url = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [temp bw_URLEncodedString]];
   }
   } else if (indexPath.section == startIndexOfSettings - 2 && indexPath.row == 2) {
   // release notes in a webview
   
   NSMutableString *webString = [[[NSMutableString alloc] init] autorelease];
   
   [webString appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"];
   [webString appendString:@"<html xmlns=\"http://www.w3.org/1999/xhtml\">"];
   [webString appendString:@"<head>"];
   [webString appendString:@"<style type=\"text/css\">"];
   [webString appendString:@" body { font: 15px 'Helvetica Neue', Helvetica; word-wrap:break-word; padding:8px;} p {margin:0;} ul {padding-left: 18px;}"];
   [webString appendString:@"</style>"];
   
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
   [webString appendString:@"<meta name=\"viewport\" content=\"user-scalable=no width=device-width\" /></head>"];
   } else {
   [webString appendFormat:@"<meta name=\"viewport\" content=\"user-scalable=no width=%d\" /></head>", CGRectGetWidth([[self view] bounds])];
   }
   
   [webString appendString:@"<body>"];
   [webString appendString:[self.hockeyController.betaDictionary objectForKey:@"notes"]];
   [webString appendString:@"</body></html>"];
   
   
   BWWebViewController *controller = [[[BWWebViewController alloc] initWithHTMLString:webString] autorelease];
   
   [[self navigationController] pushViewController:controller animated:YES];
   }
   
   if (url != nil && ![[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]])
   {
   // there was an error trying to open the URL. for the moment we'll simply ignore it.
   }
   */
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


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark PSAppStoreHeaderDelegate

- (void)storeButtonFired:(PSStoreButton *)button {
  BWLog(@"************* storeButtonFired *******************: %@", button);
  
  if ([button.buttonData.label isEqual:@"Update"]) {
    [button setButtonData:[PSStoreButtonData dataWithLabel:@"Update 2" colors:[PSStoreButton appStoreBlueColor] enabled:YES] animated:YES];
  }else {
    [button setButtonData:[PSStoreButtonData dataWithLabel:@"Up To Date" colors:[PSStoreButton appStoreGrayColor] enabled:NO] animated:YES];
  }
  
}

@end

