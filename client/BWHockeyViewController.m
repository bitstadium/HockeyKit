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

- (id)init:(BWHockeyController *)hockeyController modal:(BOOL)modal {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.hockeyController = hockeyController;
        self.modal = modal;
        self.title = NSLocalizedString(@"Beta Updates", @"");
    }
    return self;    
}


- (NSUInteger)sectionIndexOfSettings {
    amountProfileRows = 0;
    if (
        self.hockeyController.betaDictionary == nil ||
        [self.hockeyController.betaDictionary count] == 0
        ) {
        return 0;
    } else {
        if ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_PROFILE] != nil) {
            amountProfileRows = 2;
        }
        
        return amountProfileRows + 2;
    }    
}


#pragma mark -
#pragma mark View lifecycle

- (void)onAction:(id)sender {
    if (self.modal)
		[self.parentViewController dismissModalViewControllerAnimated:YES];
    else
		[self.navigationController popViewControllerAnimated:YES];
	
	[[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
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

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self sectionIndexOfSettings] + 2;
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == [self sectionIndexOfSettings])
        return NSLocalizedString(@"Check for updates", @"");
    else if (section == [self sectionIndexOfSettings] - 2 - amountProfileRows) {
        return NSLocalizedString(@"Application", @"");
    } else if (section == [self sectionIndexOfSettings] - amountProfileRows) {
        return NSLocalizedString(@"Provisioning Profile", @"");
    } else {
        return nil;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int startIndexOfSettings = [self sectionIndexOfSettings];
    int numberOfSectionRows = 0;
    
    if (section == startIndexOfSettings + 1) {
        // check again button
        numberOfSectionRows = 1;
    } else if (section == startIndexOfSettings) {
        // update check interval selection
        numberOfSectionRows = 3;
    } else if (section == startIndexOfSettings - 1 - amountProfileRows) {
        // install application button
        numberOfSectionRows = 1;
    } else if (section == startIndexOfSettings - 2 - amountProfileRows) {
        // last application update information
        if ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_NOTES])
            numberOfSectionRows = 3;
        else
            numberOfSectionRows = 2;
    } else if (section == startIndexOfSettings - 1 ) {
        // install profile button
        numberOfSectionRows = 1;
    } else if (section == startIndexOfSettings - 2) {
        // last profile update information
        numberOfSectionRows = 1;
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
    // button cell
    static NSString *BetaCell5Identifier = @"BetaCell5";

    
    int startIndexOfSettings = [self sectionIndexOfSettings];

    UITableViewCell *cell = nil;

    NSString *requiredIdentifier = BetaCell1Identifier;
    NSInteger cellStyle = UITableViewCellStyleSubtitle;
    
    // preselect the required cell style
    if (indexPath.section == startIndexOfSettings - 2 - amountProfileRows && indexPath.row == 2) {
        // we need a one line cell with discloure
        requiredIdentifier = BetaCell2Identifier;
        cellStyle = UITableViewCellStyleDefault;
    } else if (indexPath.section == startIndexOfSettings + 1 ||
        indexPath.section == startIndexOfSettings - 1 ||
        indexPath.section == startIndexOfSettings - 1 - amountProfileRows) {
        // we need a button style
        requiredIdentifier = BetaCell3Identifier;
        cellStyle = UITableViewCellStyleDefault;
    } else if (indexPath.section == startIndexOfSettings) {
        // we need a check cell
        requiredIdentifier = BetaCell4Identifier;
        cellStyle = UITableViewCellStyleDefault;
    } else if (amountProfileRows > 0 && indexPath.section == startIndexOfSettings - amountProfileRows) {
        // we need a one line style with value
        requiredIdentifier = BetaCell5Identifier;
        cellStyle = UITableViewCellStyleValue1;
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:requiredIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:requiredIdentifier] autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    if (indexPath.section == startIndexOfSettings + 1) {
        // check again button
        cell.textLabel.text = NSLocalizedString(@"Check Now", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else if (indexPath.section == startIndexOfSettings) {
        // update check interval selection
        
        NSNumber *hockeyAutoUpdateSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kHockeyAutoUpdateSetting];        
        if (indexPath.row == 0) {
            // on startup
            cell.textLabel.text = NSLocalizedString(@"On Startup", @"");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_STARTUP) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else if (indexPath.row == 1) {
            // daily
            cell.textLabel.text = NSLocalizedString(@"Daily", @"");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_DAILY) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else {
            // manually
            cell.textLabel.text = NSLocalizedString(@"Manually", @"");
            if ([hockeyAutoUpdateSetting intValue] == BETA_UPDATE_CHECK_MANUAL) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    } else if (indexPath.section == startIndexOfSettings - 1 - amountProfileRows) {
        // install application button
        cell.textLabel.text = NSLocalizedString(@"Install Update", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else if (indexPath.section == startIndexOfSettings - 2 - amountProfileRows) {
        // last application update information
        if (indexPath.row == 0) {
            // app name
            cell.textLabel.text = ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_TITLE] != [NSNull null]) ? [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_TITLE] : nil;
			cell.detailTextLabel.text = ([self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_SUBTITLE] != [NSNull null]) ? [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_SUBTITLE] : nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1) {
            // app version
            cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", 
                                   NSLocalizedString(@"New Version", @""), 
                                   [self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_VERSION]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", 
                                         NSLocalizedString(@"Installed", @""), 
                                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            // release notes
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Release Notes", @"");
        }
    } else if (indexPath.section == startIndexOfSettings - 1) {
        // install profile button
        cell.textLabel.text = NSLocalizedString(@"Install Profile", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else if (indexPath.section == startIndexOfSettings - 2) {
        // last profile update information
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Last Update", @"");
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[self.hockeyController.betaDictionary objectForKey:BETA_UPDATE_PROFILE] intValue]];
        
        cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
    }
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int startIndexOfSettings = [self sectionIndexOfSettings];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *url = nil;

    if (indexPath.section == startIndexOfSettings + 1) {
        // check again button
        // TODO: invoke check
        [self.hockeyController checkForBetaUpdate:self];
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
    } else if (indexPath.section == startIndexOfSettings - 1 - amountProfileRows) {
        // install application button
        NSString *parameter = [NSString stringWithFormat:@"?type=%@&bundleidentifier=%@", BETA_DOWNLOAD_TYPE_APP, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
        NSString *temp = [NSString stringWithFormat:@"%@%@", self.hockeyController.betaCheckUrl, parameter];
        url = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", [temp URLEncodedString]];        
    } else if (indexPath.section == startIndexOfSettings - 1) {
        // install profile button
        NSString *parameter = [NSString stringWithFormat:@"?type=%@&bundleidentifier=%@", BETA_DOWNLOAD_TYPE_PROFILE, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
        url = [NSString stringWithFormat:@"%@%@", self.hockeyController.betaCheckUrl, parameter];
    } else if (indexPath.section == startIndexOfSettings - 2 - amountProfileRows && indexPath.row == 2) {
        // release notes in a webview
        
        NSMutableString *webString = [[[NSMutableString alloc] init] autorelease];
        
        [webString appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"];
        [webString appendString:@"<html xmlns=\"http://www.w3.org/1999/xhtml\">"];
        [webString appendString:@"<head>"];
        [webString appendString:@"<style type=\"text/css\">"];
        [webString appendString:@" * {margin:0px; padding:0px; }  body { background-color:#FFF; color:#000; -webkit-text-size-adjust:none; font-size:18px; font-family:Helvetica; word-wrap:break-word; word-spacing:-0.075em; padding:8px; } p {min-height:1em; margin:0; white-space:pre-wrap;}"];
        [webString appendString:@"</style>"];
        [webString appendString:@"<meta name=\"viewport\" content=\"user-scalable=no\" /></head>"];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait || 
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end

