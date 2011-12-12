//
//  HockeyDemoSettingsViewController.m
//  HockeyDemo
//
//  Created by Andreas Linde on 8/22/10.
//  Copyright 2010 Andreas Linde. All rights reserved.
//

#import "HockeyDemoSettingsViewController.h"
#import "BWHockeyManager.h"

@implementation HockeyDemoSettingsViewController

#pragma mark -
#pragma mark Initialization

- (void)dismissSelf {
  [self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(dismissSelf)] autorelease];
  
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  }
  
  // Configure the cell...
  cell.textLabel.text = NSLocalizedString(@"Beta Updates", @"");
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#if !defined (CONFIGURATION_AppStore_Distribution)
  BWHockeyViewController *hockeyViewController = [[BWHockeyManager sharedHockeyManager] hockeyViewController:NO];
  // ...
  // Pass the selected object to the new view controller.
  [self.navigationController pushViewController:hockeyViewController animated:YES];
#endif
}


@end

