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
#import "BWHockeyManager.h"
#endif

@implementation HockeyDemoViewController

- (void)openUpdateViewAnimated:(BOOL)animated {
#if !defined (CONFIGURATION_AppStore_Distribution)
    BWHockeyViewController *hockeyViewController = [[BWHockeyManager sharedHockeyManager] hockeyViewController:YES];
    UINavigationController *hockeyNavController = [[[UINavigationController alloc] initWithRootViewController:hockeyViewController] autorelease];
    IF_3_2_OR_GREATER(hockeyNavController.modalPresentationStyle = UIModalPresentationFormSheet;)
    [self presentModalViewController:hockeyNavController animated:animated];
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(showSettings)];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
