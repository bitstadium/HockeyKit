//
//  PSAppStoreHeader.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSAppStoreHeader.h"
#import "UIImage+HockeyAdditions.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

#define kLightGrayColor RGBCOLOR(200, 202, 204)
#define kDarkGrayColor  RGBCOLOR(140, 141, 142)

#define kImageHeight 57
#define kReflectionHeight 20
#define kImageBorderRadius 10
#define kImageMargin 8
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
    UIFont *mainFont = [UIFont boldSystemFontOfSize:20];
	UIFont *secondaryFont = [UIFont boldSystemFontOfSize:12];
	UIFont *smallFont = [UIFont systemFontOfSize:12];

    float myColorValues[] = {255, 255, 255, .6};
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);

    // icon
    [iconImage_ drawAtPoint:CGPointMake(kImageMargin, kImageMargin)];
    [reflectedImage_ drawAtPoint:CGPointMake(kImageMargin, kImageMargin+kImageHeight)];

    // header
    CGContextSetShadowWithColor (context, CGSizeMake(2, 2), 0, myColor);
    [mainTextColor set];
    [headerLabel_ drawInRect:CGRectMake(kTextRow, kImageMargin, globalWidth-kTextRow, 20) withFont:mainFont lineBreakMode:UILineBreakModeTailTruncation];

    // middle
    [secondaryTextColor set];
    [middleHeaderLabel_ drawInRect:CGRectMake(kTextRow, kImageMargin + 28, globalWidth-kTextRow, 20) withFont:secondaryFont lineBreakMode:UILineBreakModeTailTruncation];
    CGContextSetShadowWithColor(context, CGSizeZero, 0, nil);
    
    // sub
    [secondaryTextColor set];
    //  [subHeaderLabel drawAtPoint:CGPointMake(kTextRow, kImageMargin+kImageHeight-12) forWidth:globalWidth-kTextRow withFont:smallFont minFontSize:12 actualFontSize:nil lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentNone];
    [subHeaderLabel drawAtPoint:CGPointMake(kTextRow, kImageMargin+kImageHeight-12) forWidth:globalWidth-kTextRow withFont:smallFont lineBreakMode:UIBaselineAdjustmentNone];
    //  [subHeaderLabel drawInRect:CGRectMake(kTextRow, kImageMargin + 45, globalWidth-kTextRow, 20) withFont:smallFont lineBreakMode:UILineBreakModeTailTruncation];

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
        iconImage_ = [anIconImage bw_imageToFitSize:CGSizeMake(kImageHeight, kImageHeight) honorScaleFactor:YES];
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
