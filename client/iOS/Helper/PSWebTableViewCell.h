//
//  PSWebTableViewCell.h
//  HockeyDemo
//
//  Created by Peter Steinberger on 04.02.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSWebTableViewCell : UITableViewCell <UIWebViewDelegate> {
  UIWebView *webView_;
  NSString *webViewContent_;
  
  CGSize webViewSize_;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, copy) NSString *webViewContent;
@property (nonatomic, assign) CGSize webViewSize;

- (void)addWebView;

@end
