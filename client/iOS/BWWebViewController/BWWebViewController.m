#import "BWWebViewController.h"


@interface BWWebViewController ()
@property (nonatomic, copy) NSString *htmlString;
@property (nonatomic, assign) UIWebView *webView;
@end


@implementation BWWebViewController

@synthesize htmlString;
@synthesize webView;


- (id)initWithHTMLString:(NSString *)aHtmlString {
    if ((self = [super init])) {
        self.title = NSLocalizedStringFromTable(@"HockeySectionAppReleaseNotes", @"Hockey", @"Release Notes");
        self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.webView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.webView];

        self.htmlString = aHtmlString;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.webView loadHTMLString:self.htmlString baseURL:nil];
}


- (void)dealloc {
	self.htmlString = nil;

	[super dealloc];
}


#pragma mark Rotation


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldAutorotate;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        shouldAutorotate = (interfaceOrientation == UIInterfaceOrientationPortrait ||
                            interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
                            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
    } else {
        shouldAutorotate = YES;
    }

    return shouldAutorotate;
}


@end
