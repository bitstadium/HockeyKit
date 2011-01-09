//
//  PSAppStoreHeader.h
//  HockeyDemo
//
//  Created by Peter Steinberger on 09.01.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

@interface PSAppStoreHeader : UIView {
  NSString *headerLabel_;
  NSString *middleHeaderLabel_;
  NSString *subHeaderLabel;
  UIImage *iconImage_;
}

@property (nonatomic, copy) NSString *headerLabel;
@property (nonatomic, copy) NSString *middleHeaderLabel;
@property (nonatomic, copy) NSString *subHeaderLabel;
@property (nonatomic, retain) UIImage *iconImage;

@end
