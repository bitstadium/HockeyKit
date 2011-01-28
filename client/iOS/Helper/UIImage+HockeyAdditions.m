//
//  UIImage+HockeyAdditions.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 10.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "UIImage+HockeyAdditions.h"

@implementation UIImage (HockeyAdditions)

CGImageRef CreateGradientImage(int pixelsWide, int pixelsHigh, float fromAlpha, float toAlpha) {
	CGImageRef theCGImage = NULL;

	// gradient is always black-white and the mask must be in the gray colorspace
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

	// create the bitmap context
	CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
                                                             8, 0, colorSpace, kCGImageAlphaNone);

	// define the start and end grayscale values (with the alpha, even though
	// our bitmap context doesn't support alpha the gradient requires it)
	CGFloat colors[] = {toAlpha, 1.0, fromAlpha, 1.0};

	// create the CGGradient and then release the gray color space
	CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);

	// create the start and end points for the gradient vector (straight down)
	CGPoint gradientEndPoint = CGPointZero;
	CGPoint gradientStartPoint = CGPointMake(0, pixelsHigh);

	// draw the gradient into the gray bitmap context
	CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
                              gradientEndPoint, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(grayScaleGradient);

	// convert the context into a CGImageRef and release the context
	theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
	CGContextRelease(gradientBitmapContext);

	// return the imageref containing the gradient
  return theCGImage;
}

CGContextRef MyCreateBitmapContext(int pixelsWide, int pixelsHigh) {
  CGSize size = CGSizeMake(pixelsWide, pixelsHigh);
  if (UIGraphicsBeginImageContextWithOptions != NULL) {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  }
  else {
    UIGraphicsBeginImageContext(size);
  }

  return UIGraphicsGetCurrentContext();
}

- (UIImage *)ps_reflectedImageWithHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha {
  if(height == 0)
		return nil;

	// create a bitmap graphics context the size of the image
	CGContextRef mainViewContentContext = MyCreateBitmapContext(self.size.width, height);

	// create a 2 bit CGImage containing a gradient that will be used for masking the
	// main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
	// function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
	CGImageRef gradientMaskImage = CreateGradientImage(1, height, fromAlpha, toAlpha);

	// create an image by masking the bitmap of the mainView content with the gradient view
	// then release the  pre-masked content bitmap and the gradient bitmap
	CGContextClipToMask(mainViewContentContext, CGRectMake(0.0, 0.0, self.size.width, height), gradientMaskImage);
	CGImageRelease(gradientMaskImage);

	// draw the image into the bitmap context
	CGContextDrawImage(mainViewContentContext, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);

	// convert the finished reflection image to a UIImage
	UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();

	return theImage;
}


+ (UIImage *)imageNamed:(NSString *)imageName bundle:(NSString *)bundleName {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
	NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];
	return [UIImage imageWithContentsOfFile:imagePath];
}

@end
