//
//  PSAppStoreHeader.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSAppStoreHeader.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

#define kTextRow 70

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
  NSArray *colors = [NSArray arrayWithObjects:(id)RGBCOLOR(140, 141, 142).CGColor, (id)RGBCOLOR(200, 202, 204).CGColor, nil];
  CGGradientRef gradient = CGGradientCreateWithColors(CGColorGetColorSpace((CGColorRef)[colors objectAtIndex:0]), (CFArrayRef)colors, (CGFloat[2]){0, 1});
  CGPoint top = CGPointMake(CGRectGetMidX(bounds), bounds.origin.y);
  CGPoint bottom = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
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

  // header
  [mainTextColor set];
  [headerLabel_ drawInRect:CGRectMake(kTextRow, 5, globalWidth-kTextRow, 20) withFont:mainFont lineBreakMode:UILineBreakModeTailTruncation];

  // middle
  [secondaryTextColor set];
  [middleHeaderLabel_ drawInRect:CGRectMake(kTextRow, 25, globalWidth-kTextRow, 20) withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];

  // sub
  [secondaryTextColor set];
  [subHeaderLabel drawInRect:CGRectMake(kTextRow, 40, globalWidth-kTextRow, 20) withFont:smallFont lineBreakMode:UILineBreakModeTailTruncation];

  CGColorRelease(myColor);
  CGColorSpaceRelease(myColorSpace);
}

@end
