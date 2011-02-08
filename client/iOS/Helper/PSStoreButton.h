//
//  PSStoreButton.h
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// defines a button action set (data container)
@interface PSStoreButtonData : NSObject {
    CGPoint customPadding_;
    NSString *label_;
    NSArray *colors_;
    BOOL enabled_;
}

+ (id)dataWithLabel:(NSString*)aLabel colors:(NSArray*)aColors enabled:(BOOL)flag;

@property (nonatomic, copy) NSString *label;
@property (nonatomic, retain) NSArray *colors;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end


@class PSStoreButton;
@protocol PSStoreButtonDelegate
- (void)storeButtonFired:(PSStoreButton *)button;
@end


// Simulate the Paymeny-Button from the AppStore
// The interface is flexible, so there is now fixed order
@interface PSStoreButton : UIButton {
    PSStoreButtonData *buttonData_;
    id<PSStoreButtonDelegate> buttonDelegate_;

    CAGradientLayer *gradient_;
    CGPoint customPadding_;
}

- (id)initWithFrame:(CGRect)frame;
- (id)initWithPadding:(CGPoint)padding;

// action delegate
@property (nonatomic, assign) id<PSStoreButtonDelegate> buttonDelegate;

// change the button layer
@property (nonatomic, retain) PSStoreButtonData *buttonData;
- (void)setButtonData:(PSStoreButtonData *)aButtonData animated:(BOOL)animated;

// align helper
@property (nonatomic, assign) CGPoint customPadding;
- (void)alignToSuperview;

// helpers to mimic an AppStore button
+ (NSArray *)appStoreGreenColor;
+ (NSArray *)appStoreBlueColor;
+ (NSArray *)appStoreGrayColor;

@end
