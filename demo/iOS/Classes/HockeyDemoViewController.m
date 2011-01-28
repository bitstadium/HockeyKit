//
//  HockeyDemoViewController.m
//  HockeyDemo
//
//  Created by Andreas Linde on 8/22/10.
//  Copyright Andreas Linde 2010. All rights reserved.
//

#import "HockeyDemoViewController.h"
#import "HockeyDemoSettingsViewController.h"

#if !defined (CONFIGURATION_AppStore_Distribution)
#import "BWHockeyController.h"
#endif

#define kAutoOpenHockey

@implementation HockeyDemoViewController

- (void)openUpdateViewAnimated:(BOOL)animated {
#if !defined (CONFIGURATION_AppStore_Distribution)
  BWHockeyViewController *hockeyViewController = [[BWHockeyController sharedHockeyController] hockeyViewController:YES];
  UINavigationController *hockeyNavController = [[[UINavigationController alloc] initWithRootViewController:hockeyViewController] autorelease];
  IF_3_2_OR_GREATER(hockeyNavController.modalPresentationStyle = UIModalPresentationFormSheet;)
  [self presentModalViewController:hockeyNavController animated:animated];
#endif
}

#ifdef kAutoOpenHockey
- (void)openUpdateViewCaller {
  [self openUpdateViewAnimated:NO];
}
#endif

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:self
                                                                           action:@selector(showSettings)];

#ifdef kAutoOpenHockey
  // HACK - DEVELOPMENT AID
  [self performSelector:@selector(openUpdateViewCaller) withObject:nil afterDelay:0.01];
#endif
}

- (void)dealloc {
  [super dealloc];
}


- (void)showSettings {
  HockeyDemoSettingsViewController *hockeySettingsViewController = [[[HockeyDemoSettingsViewController alloc] init] autorelease];
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:hockeySettingsViewController];
  navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navController animated:YES];
}

- (IBAction)openUpdateView {
  [self openUpdateViewAnimated:YES];
}

@end
