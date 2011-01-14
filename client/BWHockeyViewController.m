//
//  BWHockeyViewController.m
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

#import "BWHockeyViewController.h"
#import "BWHockeyController.h"
#import "BWWebViewController.h"
#import "NSString+URLEncoding.h"
#import "BWGlobal.h"


@implementation BWHockeyViewController


@synthesize hockeyController = _hockeyController;
@synthesize modal = _modal;

#pragma mark -
#pragma mark Initialization

- (id)init:(BWHockeyController *)newHockeyController modal:(BOOL)newModal {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.hockeyController = newHockeyController;
        self.modal = newModal;
        self.title = NSLocalizedStringFromTable(@"HockeyUpdateScreenTitle", @"Hockey", @"Update Details");
    }
    return self;    
}

- (id)init {
	return [self init:[BWHockeyController sharedHockeyController] modal:NO];
}

- (NSUInteger)sectionIndexOfSettings {
    if (
        self.hockeyController.betaDictionary == nil ||
        [self.hockeyController.betaDictionary count] == 0
        ) {
        return 0;
    } else {
        return 2;
    }    
}


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
	
	[[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
	
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.modal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                              target:self
                                                                                              action:@selector(onAction:)];
    }
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	_statusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
	[[UIApplication sharedApplication] setStatusBarStyle:(self.navigationController.navigationBar.barStyle == UIBarStyleDefault) ? UIStatusBarStyleDefault : UIStatusBarStyleBlackOpaque];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.hockeyController unsetHockeyViewController];
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
}

- (void)redrawTableView {
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
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.hockeyController.checkInProgress) {
        return 1;
    } else {
        return [self sectionIndexOfSettings] + 2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 44;
    if (self.hockeyController.checkInProgress)
        return rowHeight;
    
    NSUInteger startIndexOfSettings = [self sectionIndexOfSettings];
    
    if (indexPath.section == startIndexOfSettings - 1) {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0" options:NSNumericSearch] < NSOrderedSame) {
            rowHeight = 88;
        }
    }
    
    return rowHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.hockeyController.checkInProgress)
        return nil;
	NSInteger settingIndex = [self sectionIndexOfSettings];
    
    if (section == settingIndex)
        return NSLocalizedStringFromTable(@"HockeySectionCheckHeader", @"Hockey", @"Check For Updates");
    else if (section == settingIndex - 2) {
        return NSLocalizedStringFromTable(@"HockeySectionAppHeader", @"Hockey", @"Application");
    } else {
        return nil;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.hockeyController.checkInProgress)
        return 1;
    
    int startIndexOfSettings = [self sectionIndexOfSettings];
    int numberOfSectionRows = 0;
    
    if (section == startIndexOfSettings + 1) {
        // check again button
        numberOfSectionRows = 1;
    } else if (section == startIndexOfSettings) {
        // update check interval selection
        numberOfSectionRows = 3;
    } else if (section == startIndexOfSettings - 1) {
        // install application button
        numberOfSectionRows = 1;
    } else if (section == startIndexOfSettings - 2) {
        // last application update information
        if ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_NOTES])
            numberOfSectionRows = 3;
        else
            numberOfSectionRows = 2;
    }
    
    // Return the number of rows in the section.
    return numberOfSectionRows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 2 lines cell
    static NSString *BetaCell1Identifier = @"BetaCell1";
    // 1 line cell with discolure
    static NSString *BetaCell2Identifier = @"BetaCell2";
    // 1 line cell with value
    static NSString *BetaCell3Identifier = @"BetaCell3";
    // check cell
    static NSString *BetaCell4Identifier = @"BetaCell4";
	
	NSString* lastHockeyCheck = [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION];
	NSString* bundleVersion   = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

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
        cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionCheckProgress", @"Hockey", @"Checking...");
        cell.textLabel.textAlignment = UITextAlignmentCenter;        
        cell.textLabel.textColor = [UIColor grayColor];
        
        return cell;
    }

    NSUInteger startIndexOfSettings = [self sectionIndexOfSettings];

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
        cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionCheckButton", @"Hockey", @"Check Now");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == startIndexOfSettings) {
        // update check interval selection
        
        NSNumber *hockeyAutoUpdateSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting];        
        if (indexPath.row == 0) {
            // on startup
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionCheckStartup", @"Hockey", @"On Startup");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_STARTUP) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else if (indexPath.row == 1) {
            // daily
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionCheckDaily", @"Hockey", @"Daily");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_DAILY) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else {
            // manually
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionCheckManually", @"Hockey", @"Manually");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_MANUAL) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    } else if (indexPath.section == startIndexOfSettings - 1) {        
        if ([lastHockeyCheck compare:bundleVersion] == NSOrderedSame) {
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionAppSameVersionButton", @"Hockey", @"Same Version");
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if ([[[UIDevice currentDevice] systemVersion] compare:@"4.0" options:NSNumericSearch] < NSOrderedSame) {
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionAppWebsite", @"Hockey", @"Visit the beta website on your Mac or PC to update");
            cell.textLabel.numberOfLines = 3;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            // install application button
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionAppButton", @"Hockey", @"Install Update");
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

            cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", 
                                   NSLocalizedStringFromTable(@"HockeySectionAppNewVersion", @"Hockey", @"New Version"), 
                                   versionString];
            
            if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] != nil) {
                currentVersionString = [NSString stringWithFormat:@"%@ (%@)", 
                                 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], 
                                 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
                                 ];
            } else {
                currentVersionString = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
            }

            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", 
                                         NSLocalizedStringFromTable(@"HockeySectionAppCurrentVersion", @"Hockey", @"Current Version"), 
                                         currentVersionString];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            // release notes
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedStringFromTable(@"HockeySectionAppReleaseNotes", @"Hockey", @"Release Notes");
        }
    }
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.hockeyController.checkInProgress) {
        return;
    }
	NSString* lastHockeyCheck = [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION];
	NSString* bundleVersion   = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

    NSUInteger startIndexOfSettings = [self sectionIndexOfSettings];
    
    NSString *url = nil;

    if (indexPath.section == startIndexOfSettings + 1) {
        // check again button
        if (!self.hockeyController.checkInProgress) {
            [self.hockeyController checkForBetaUpdate:self];
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
        if ([lastHockeyCheck compare:bundleVersion] != NSOrderedSame) {
            // install application button
            NSString *parameter = [NSString stringWithFormat:@"?type=%@&bundleidentifier=%@", BETA_DOWNLOAD_TYPE_APP, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
            NSString *temp = [NSString stringWithFormat:@"%@%@", self.hockeyController.betaCheckUrl, parameter];
            url = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [temp URLEncodedString]];
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
        [webString appendString:@"<meta name=\"viewport\" content=\"user-scalable=no width=device-width\" /></head>"];
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
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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

@end

