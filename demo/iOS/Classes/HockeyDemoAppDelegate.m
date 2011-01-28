//
//  HockeyDemoAppDelegate.m
//  HockeyDemo
//
//  Created by Andreas Linde on 8/22/10.
//  Copyright Andreas Linde 2010. All rights reserved.
//

#import "HockeyDemoAppDelegate.h"
#import "HockeyDemoViewController.h"


@implementation HockeyDemoAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;

#pragma mark -
#pragma mark BWHockeyController

- (BOOL)showUpdateReminder {
  return YES;
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [window addSubview:viewController.view];
  [window makeKeyAndVisible];

  if ([window respondsToSelector:@selector(setRootViewController:)]) {
    [window setRootViewController:navigationController];
  }

  // This variable is available if you add "CONFIGURATION_$(CONFIGURATION)"
  // to the Preprocessor Macros in the project settings to all configurations
#if !defined (CONFIGURATION_AppStore_Distribution)
  [[BWHockeyController sharedHockeyController] setBetaURL:@"http://worldviewmobileapp.com/apps/hockey/" delegate:self];
#endif

  return YES;
}

- (void)dealloc {
  [viewController release];
  [window release];
  [super dealloc];
}


@end
