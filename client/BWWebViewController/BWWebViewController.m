#import "BWWebViewController.h"


@implementation BWWebViewController


- (id)initWithHTMLString:(NSString *)htmlString
{
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Release Notes", @"");
        webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [webView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:webView];
        NSLog(@"1: %@", NSStringFromCGRect(self.view.frame));
        NSLog(@"2: %@", NSStringFromCGRect(webView.frame));
        
        html = htmlString;
    }
    return self;    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [webView loadHTMLString:html baseURL:nil];
}


- (void)dealloc
{
	[super dealloc];
}


#pragma mark Rotation


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait || 
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


@end
