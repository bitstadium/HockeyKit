//
//  HockeyDemoAppDelegate.h
//  HockeyDemo
//
//  Created by Andreas Linde on 8/22/10.
//  Copyright Andreas Linde 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HockeyDemoViewController;
@class BWHockeyController;

@interface HockeyDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    HockeyDemoViewController *viewController;
    
    BWHockeyController *checkForBetaUpdateController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet HockeyDemoViewController *viewController;

@end

