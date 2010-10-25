#import "BWWebViewController.h"


@interface BWWebViewController ()
@property (nonatomic, copy) NSString *htmlString;
@end

@implementation BWWebViewController

- (id)initWithHTMLString:(NSString *)htmlString
{
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Release Notes", nil);
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [webView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:webView];
		[webView release];

        self.htmlString = htmlString;
    }
    return self;    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [webView loadHTMLString:self.htmlString baseURL:nil];
}


- (void)dealloc
{
	self.htmlString = nil;

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
