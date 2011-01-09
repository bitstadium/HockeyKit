//
//  PSAppStoreHeader.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSAppStoreHeader.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+PSReflection.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

#define kLightGrayColor RGBCOLOR(200, 202, 204)
#define kDarkGrayColor  RGBCOLOR(140, 141, 142)

#define kImageHeight 60
#define kReflectionHeight 20
#define kImageBorderRadius 10
#define kImageMargin 10
#define kTextRow kImageMargin*2 + kImageHeight

@implementation PSAppStoreHeader

@synthesize headerLabel = headerLabel_;
@synthesize middleHeaderLabel = middleHeaderLabel_;
@synthesize subHeaderLabel;
@synthesize iconImage = iconImage_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = kLightGrayColor;
  }
  return self;
}

- (void)dealloc {
  [headerLabel_ release];
  [middleHeaderLabel_ release];
  [subHeaderLabel release];
  [iconImage_ release];

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
  CGRect bounds = self.bounds;
  CGFloat globalWidth = self.frame.size.width;
  CGContextRef context = UIGraphicsGetCurrentContext();

  // draw the gradient
  NSArray *colors = [NSArray arrayWithObjects:(id)kDarkGrayColor.CGColor, (id)kLightGrayColor.CGColor, nil];
  CGGradientRef gradient = CGGradientCreateWithColors(CGColorGetColorSpace((CGColorRef)[colors objectAtIndex:0]), (CFArrayRef)colors, (CGFloat[2]){0, 1});
  CGPoint top = CGPointMake(CGRectGetMidX(bounds), bounds.origin.y);
  CGPoint bottom = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds)-kReflectionHeight);
  CGContextDrawLinearGradient(context, gradient, top, bottom, 0);
  CGGradientRelease(gradient);

  // draw header name
  UIColor *mainTextColor = RGBCOLOR(0,0,0);
  UIColor *secondaryTextColor = RGBCOLOR(48,48,48);
  UIFont *mainFont = [UIFont boldSystemFontOfSize:17];
	UIFont *secondaryFont = [UIFont boldSystemFontOfSize:12];
	UIFont *smallFont = [UIFont systemFontOfSize:12];

  float myColorValues[] = {255, 255, 255, .8};
  CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
  CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);
  CGContextSetShadowWithColor (context, CGSizeMake(1, 1), 1, myColor);

  // icon
  [iconImage_ drawAtPoint:CGPointMake(kImageMargin, kImageMargin)];
  [reflectedImage_ drawAtPoint:CGPointMake(kImageMargin, kImageMargin+kImageHeight)];

  // header
  [mainTextColor set];
  [headerLabel_ drawInRect:CGRectMake(kTextRow, kImageMargin, globalWidth-kTextRow, 20) withFont:mainFont lineBreakMode:UILineBreakModeTailTruncation];

  // middle
  [secondaryTextColor set];
  [middleHeaderLabel_ drawInRect:CGRectMake(kTextRow, kImageMargin + 20, globalWidth-kTextRow, 20) withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];

  // sub
  [secondaryTextColor set];
  [subHeaderLabel drawInRect:CGRectMake(kTextRow, kImageMargin + 35, globalWidth-kTextRow, 20) withFont:smallFont lineBreakMode:UILineBreakModeTailTruncation];

  CGColorRelease(myColor);
  CGColorSpaceRelease(myColorSpace);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (void)setIconImage:(UIImage *)anIconImage {
  if (iconImage_ != anIconImage) {
    [iconImage_ release];

    // scale, make borders and reflection
    iconImage_ = [anIconImage bw_imageToFitSize:CGSizeMake(kImageHeight, kImageHeight) method:MGImageResizeScale honorScaleFactor:YES];
    iconImage_ = [[iconImage_ bw_roundedCornerImage:kImageBorderRadius borderSize:0.0] retain];
//    iconImage_ = [anIconImage retain];

    // create reflected image
    [reflectedImage_ release];
    reflectedImage_ = nil;
    if (anIconImage) {
      reflectedImage_ = [[iconImage_ ps_reflectedImageWithHeight:kReflectionHeight fromAlpha:0.5 toAlpha:0.0] retain];
    }
  }
}

@end
