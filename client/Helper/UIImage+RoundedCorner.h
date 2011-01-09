// UIImage+RoundedCorner.h
// Created by Trevor Harmon on 9/20/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

// Extends the UIImage class to support making rounded corners
@interface UIImage (BWRoundedCorner)

typedef enum {
  MGImageResizeCrop,	// analogous to UIViewContentModeScaleAspectFill, i.e. "best fit" with no space around.
  MGImageResizeCropStart,
  MGImageResizeCropEnd,
  MGImageResizeScale	// analogous to UIViewContentModeScaleAspectFit, i.e. scale down to fit, leaving space around if necessary.
} MGImageResizingMethod;

- (UIImage *)bw_roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;
- (UIImage *)bw_imageToFitSize:(CGSize)fitSize method:(MGImageResizingMethod)resizeMethod honorScaleFactor:(BOOL)honorScaleFactor;

@end
