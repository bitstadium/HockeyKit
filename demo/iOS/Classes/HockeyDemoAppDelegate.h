//
//  HockeyDemoAppDelegate.h
//  HockeyDemo
//
//  Created by Andreas Linde on 8/22/10.
//  Copyright Andreas Linde 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#if !defined (CONFIGURATION_AppStore_Distribution)
#import "BWHockeyManager.h"
#endif

@class HockeyDemoViewController;

@interface HockeyDemoAppDelegate : NSObject <UIApplicationDelegate, BWHockeyManagerDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    HockeyDemoViewController *viewController;    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet HockeyDemoViewController *viewController;

@end

