#import "WebViewController.h"
#import "UIWebView+SafeJavaScriptExecution.h"
#import "CalatravaWebView.h"

@implementation WebViewController {
  NSString *pageName;
  CalatravaWebView* webView;
}

- (id)initWithPageName:(NSString *)thePageName {
  if (self = [super initWithNibName:nil bundle:nil]) {
    pageName = thePageName;
    [self initWebView];
  }

  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    pageName = @"OVERRIDE pageName IN SUB-CLASS"; // default page name
    [self initWebView];
  }
  
  return self;
}

- (void)initWebView {
  queuedBinds = [[NSMutableOrderedSet alloc] init];
  queuedRenders = [[NSMutableOrderedSet alloc] init];
  
  webViewReady = NO;
  
  webView = [[CalatravaWebView alloc] initWithEventDispatcher:self];
  self.view = webView;
  [self removeWebViewBounceShadow];

  // read the HTML file from disk and load it with a base URL,
  // this makes the page act as if it was requested from the
  // public dir rather than the public/views dir.
  NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"public/views/%@", [self pageName]] ofType:@"html"];
  NSString* publicPath = [NSString stringWithFormat:@"%@/public", [[NSBundle mainBundle] bundlePath]];
  NSString* content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];

  [webView loadHTMLString:content baseURL:[NSURL fileURLWithPath:publicPath]];
}

- (NSString *)pageName {
  return pageName;
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"Dispatching pageOpened for page %@", [self pageName]);
  [self dispatchEvent:@"pageOpened" withArgs:[NSArray array]];
}

#pragma mark - Kernel methods

- (void)render:(id)viewMessage {
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:viewMessage
                                                     options:kNilOptions
                                                       error:nil];
  NSString *responseJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  NSLog(@"Web data: %@", responseJson);
  NSLog(@"Page name: %@", [self pageName]);

  NSString *render = [NSString stringWithFormat:@"window.%@View.render(%@);", [self pageName], responseJson];
  [webView enqueueJavascript:render];
}

- (id)valueForField:(NSString *)field {
  return [webView stringBySafelyEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.%@View.get('%@');", [self pageName], field]];
}

- (id)attachHandler:(NSString *)proxyId forEvent:(NSString *)event
{
  [super attachHandler:proxyId forEvent:event];

  NSString *jsCode = [NSString stringWithFormat:@"window.%@View.bind('%@', tw.batSignalFor('%@'));", [self pageName], event, event];
  [webView enqueueJavascript:jsCode];

  return self;
}

- (void)bindWebEvent:(NSString *)event
{
  NSString *jsCode = [NSString stringWithFormat:@"window.%@View.bind('%@', tw.batSignalFor('%@'));", [self pageName], event, event];
  [webView enqueueJavascript:jsCode];
}

# pragma mark - WebView delegate methods

- (id)scrollToTop {
  [webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  [webView.scrollView flashScrollIndicators];
  return self;
}

- (void)removeWebViewBounceShadow {
   if ([webView.subviews count] > 0)
    {
        for (UIView* shadowView in [[webView.subviews objectAtIndex:0] subviews])
        {
            [shadowView setHidden:YES];
        }
        // unhide the last view so it is visible again because it has the content
        [[[[webView.subviews objectAtIndex:0] subviews] lastObject] setHidden:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
