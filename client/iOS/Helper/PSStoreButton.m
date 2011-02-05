//
//  PSStoreButton.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//
// This code was inspired by https://github.com/dhmspector/ZIStoreButton

#import "PSStoreButton.h"

#ifdef DEBUG
#define PSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define PSLog(...)
#endif

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define PS_MAX_WIDTH 120.0f
#define PS_PADDING 12.0f

@implementation PSStoreButtonData

@synthesize label = label_;
@synthesize colors = colors_;
@synthesize enabled = enabled_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)initWithLabel:(NSString*)aLabel colors:(NSArray*)aColors enabled:(BOOL)flag {
  if ((self = [super init])) {
    self.label = aLabel;
    self.colors = aColors;
    self.enabled = flag;
  }
  return self;
}

+ (id)dataWithLabel:(NSString*)aLabel colors:(NSArray*)aColors enabled:(BOOL)flag {
  return [[[[self class] alloc] initWithLabel:aLabel colors:aColors enabled:flag] autorelease];
}

- (void)dealloc {
  [label_ release];
  [colors_ release];

  [super dealloc];
}

@end


@interface PSStoreButton ()

// call when buttonData was updated
- (void)updateButtonAnimated:(BOOL)animated;

@end


@implementation PSStoreButton

@synthesize buttonData = buttonData_;
@synthesize buttonDelegate = buttonDelegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)touchedUpOutside:(id)sender {
  PSLog(@"touched outside...");
}

- (void)buttonPressed:(id)sender {
  PSLog(@"calling delegate:storeButtonFired for %@", sender);
  [buttonDelegate_ storeButtonFired:self];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  // show text again, but only if animation did finish (or else another animation is on the way)
  if ([finished boolValue]) {
    [self setTitle:self.buttonData.label forState:UIControlStateNormal];
  }
}

- (void)updateButtonAnimated:(BOOL)animated {
  if (animated) {
    // hide text, then start animation
    [self setTitle:@"" forState:UIControlStateNormal];
    [UIView beginAnimations:@"storeButtonUpdate" context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
  }else {
    [self setTitle:self.buttonData.label forState:UIControlStateNormal];
  }

  self.enabled = self.buttonData.isEnabled;
  gradient_.colors = self.buttonData.colors;

  // show white or gray text, depending on the state
  if (self.buttonData.isEnabled) {
    [self setTitleShadowColor:[UIColor colorWithWhite:0.200 alpha:1.000] forState:UIControlStateNormal];
    [self.titleLabel setShadowOffset:CGSizeMake(0.0, -0.6)];
    [self setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.000] forState:UIControlStateNormal];
  }else {
    [self.titleLabel setShadowOffset:CGSizeMake(0.0, 0.0)];
    [self setTitleColor:RGBCOLOR(148,150,151) forState:UIControlStateNormal];
  }

  // calculate new width
  CGSize constr = (CGSize){.height = self.frame.size.height, .width = PS_MAX_WIDTH};
	CGSize newSize = [self.buttonData.label sizeWithFont:self.titleLabel.font constrainedToSize:constr lineBreakMode:UILineBreakModeMiddleTruncation];
	CGFloat newWidth = newSize.width + (PS_PADDING * 2);
	CGFloat diff = self.frame.size.width - newWidth;

	for (CALayer *la in self.layer.sublayers) {
		CGRect cr = la.bounds;
		cr.size.width = cr.size.width;
		cr.size.width = newWidth;
		la.bounds = cr;
		[la layoutIfNeeded];
	}

	CGRect cr = self.frame;
	cr.size.width = cr.size.width;
	cr.size.width = newWidth;
	self.frame = cr;
	self.titleEdgeInsets = UIEdgeInsetsMake(2.0, self.titleEdgeInsets.left + diff, 0.0, 0.0);

  if (animated) {
    [UIView commitAnimations];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    // resizing
    //self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    //self.autoresizesSubviews = YES;
		self.layer.needsDisplayOnBoundsChange = YES;

    // setup title label
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0]];
    //self.titleLabel.backgroundColor = [UIColor redColor];

    // register for touch events
    [self addTarget:self action:@selector(touchedUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
		[self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

    // border layers for more sex!
    CAGradientLayer *bevelLayer = [CAGradientLayer layer];
		bevelLayer.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.4 alpha:1.0] CGColor], [[UIColor whiteColor] CGColor], nil];
		bevelLayer.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(frame), CGRectGetHeight(frame));
		bevelLayer.cornerRadius = 2.5;
		bevelLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:bevelLayer];

		CAGradientLayer *topBorderLayer = [CAGradientLayer layer];
		topBorderLayer.colors = [NSArray arrayWithObjects:(id)[[UIColor darkGrayColor] CGColor], [[UIColor lightGrayColor] CGColor], nil];
		topBorderLayer.frame = CGRectMake(0.5, 0.5, CGRectGetWidth(frame) - 1.0, CGRectGetHeight(frame) - 1.0);
		topBorderLayer.cornerRadius = 2.6;
		topBorderLayer.needsDisplayOnBoundsChange = YES;
		[self.layer addSublayer:topBorderLayer];

    // main gradient layer
    gradient_ = [[CAGradientLayer layer] retain];
    gradient_.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil];//[NSNumber numberWithFloat:0.500], [NSNumber numberWithFloat:0.5001],
		gradient_.frame = CGRectMake(0.75, 0.75, CGRectGetWidth(frame) - 1.5, CGRectGetHeight(frame) - 1.5);
		gradient_.cornerRadius = 2.5;
		gradient_.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:gradient_];
    [self bringSubviewToFront:self.titleLabel];
  }
  return self;
}

- (void)dealloc {
  [buttonData_ release];
  [gradient_ release];

  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (void)setButtonData:(PSStoreButtonData *)aButtonData {
  [self setButtonData:aButtonData animated:NO];
}

- (void)setButtonData:(PSStoreButtonData *)aButtonData animated:(BOOL)animated {
  if (buttonData_ != aButtonData) {
    [buttonData_ release];
    buttonData_ = [aButtonData retain];
  }

  [self updateButtonAnimated:animated];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Static

+ (NSArray *)appStoreGreenColor {
  return [NSArray arrayWithObjects:(id)
          [UIColor colorWithRed:0.482 green:0.674 blue:0.406 alpha:1.000].CGColor,
          //[UIColor colorWithRed:0.525 green:0.742 blue:0.454 alpha:1.000].CGColor,
          //[UIColor colorWithRed:0.346 green:0.719 blue:0.183 alpha:1.000].CGColor,
          [UIColor colorWithRed:0.299 green:0.606 blue:0.163 alpha:1.000].CGColor, nil];
}

+ (NSArray *)appStoreBlueColor {
  return [NSArray arrayWithObjects:(id)
          [UIColor colorWithRed:0.306 green:0.380 blue:0.547 alpha:1.000].CGColor,
          //[UIColor colorWithRed:0.258 green:0.307 blue:0.402 alpha:1.000].CGColor,
          //[UIColor colorWithRed:0.159 green:0.270 blue:0.550 alpha:1.000].CGColor,
          [UIColor colorWithRed:0.129 green:0.220 blue:0.452 alpha:1.000].CGColor, nil];
}

+ (NSArray *)appStoreGrayColor {
  return [NSArray arrayWithObjects:(id)
          RGBCOLOR(167,169,171).CGColor,
          RGBCOLOR(185,187,188).CGColor, nil];
}

@end
