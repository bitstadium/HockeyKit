//
//  PSWebTableViewCell.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 04.02.11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSWebTableViewCell.h"
#import "BWGlobal.h"

@implementation PSWebTableViewCell

static NSString* PSWebTableViewCellHtmlTemplate = @"\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\
<html xmlns=\"http://www.w3.org/1999/xhtml\">\
<head>\
<style type=\"text/css\">\
body { font: 15px 'Helvetica Neue', Helvetica; word-wrap:break-word; padding:8px;} p {margin:0;} ul {padding-left: 18px;}\
</style>\
<meta name=\"viewport\" content=\"user-scalable=no width=%@\" /></head>\
<body>\
%@\
</body>\
</html>\
";

@synthesize webView = webView_;
@synthesize webViewContent = webViewContent_;
@synthesize webViewSize = webViewSize_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)addWebView {
	if(webViewContent_) {
//		CGSize eventTextSize = [self getSizeForEventText];
    CGRect webViewRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		if(!webView_) {
			webView_ = [[[UIWebView alloc] initWithFrame:webViewRect] retain];
			[self addSubview:webView_];
			webView_.hidden = YES;
			webView_.backgroundColor = [UIColor clearColor];
			webView_.opaque = NO;
			webView_.delegate = self;
		}
		else
			webView_.frame = webViewRect;
		
    NSString *deviceWidth = isIPad() ? [NSString stringWithFormat:@"%d", CGRectGetWidth(self.bounds)] : @"device-width";
    BWLog(@"%@\n%@\%@", PSWebTableViewCellHtmlTemplate, deviceWidth, self.webViewContent);
    NSString *contentHtml = [NSString stringWithFormat:PSWebTableViewCellHtmlTemplate, deviceWidth, self.webViewContent];
		[webView_ loadHTMLString:contentHtml baseURL:nil];
	}
}

- (void)showWebView {
	webView_.hidden = NO;
	[self setNeedsDisplay];
}


- (void)removeWebView {
	if(webView_) {
		webView_.delegate = nil;
		[webView_ resignFirstResponder];
		[webView_ removeFromSuperview];
		[webView_ release];
	}
	webView_ = nil;
	[self setNeedsDisplay];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    [self addWebView];
  }
  return self;
}

- (void)dealloc {
  [self removeWebView];
  [webViewContent_ release];
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewCell

/*
- (void)prepareForReuse {
	[self removeWebView];
  self.webViewContent = nil;
	[super prepareForReuse];
}*/

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIWebView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if(navigationType == UIWebViewNavigationTypeOther)
		return YES;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Link!" message:@"You touched a link!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
	
	return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if(webViewContent_)
    [self showWebView];
		//[self performSelector:@selector(showWebView) withObject:nil afterDelay:.35];  
  
  CGRect frame = webView_.frame;
  frame.size.height = 1;
  webView_.frame = frame;
  CGSize fittingSize = [webView_ sizeThatFits:CGSizeZero];
  frame.size = fittingSize;
  webView_.frame = frame;
  
  self.webViewSize = fittingSize;
  BWLog(@"web view size: %f, %f", fittingSize.width, fittingSize.height);
  
  NSString *output = [webView_ stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"];
  BWLog(@"web view size V2: %@", output);
  
  // HACK
  self.webViewSize = CGSizeMake(fittingSize.width, [output integerValue]);
}

@end
