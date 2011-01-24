//
//  UIImage+HockeyAdditions.h
//  HockeyDemo
//
//  Created by Peter Steinberger on 10.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

@interface UIImage (HockeyAdditions)

- (UIImage *)ps_reflectedImageWithHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha;

- (id)initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)imageWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (id)cachedImageWithContentsOfFile:(NSString *)path;
+ (void)clearCache;

@end
