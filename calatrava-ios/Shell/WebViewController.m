#import "WebViewController.h"

@interface WebViewController()
- (void)renderMessage:(NSDictionary *)message;
- (void)bindWebEvent:(NSString *)event;

- (void)removeWebViewBounceShadow;
@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      queuedBinds = [[NSMutableOrderedSet alloc] init];
      queuedRenders = [[NSMutableOrderedSet alloc] init];
      
      webViewReady = NO;
      
      _webView = [[UIWebView alloc] init];
      [self setView:_webView];
      [_webView setDelegate:self];
      [self removeWebViewBounceShadow];

      // read the HTML file from disk and load it with a base URL,
      // this makes the page act as if it was requested from the
      // public dir rather than the public/views dir.
      NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"public/views/%@", [self pageName]] ofType:@"html"];
      NSString* publicPath = [NSString stringWithFormat:@"%@/public", [[NSBundle mainBundle] bundlePath]];
      NSString* content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];

      [_webView loadHTMLString:content baseURL:[NSURL fileURLWithPath:publicPath]];
    }
    return self;
}

- (NSString *)pageName
{
  // No-op implementation. Override in sub class
  return @"OVERRIDE pageName IN SUB-CLASS";
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"Dispatching pageOpened for page %@", [self pageName]);
  [self dispatchEvent:@"pageOpened" withArgs:[NSArray array]];
}

#pragma mark - Kernel methods

- (void)render:(id)viewMessage
{
  if (!webViewReady) {
    [queuedRenders addObject:viewMessage];
  } else {
    [self renderMessage:viewMessage];
  }
}

- (id)valueForField:(NSString *)field {
  return [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.%@View.get('%@');", [self pageName], field]];
}

- (id)attachHandler:(NSString *)proxyId forEvent:(NSString *)event
{
  [super attachHandler:proxyId forEvent:event];
  if (!webViewReady) {
    [queuedBinds addObject:event];
  } else {
    [self bindWebEvent:event];
  }
  return self;
}

- (void)bindWebEvent:(NSString *)event
{
  NSString *jsCode = [NSString stringWithFormat:@"window.%@View.bind('%@', tw.batSignalFor('%@'));", [self pageName], event, event];
  [_webView stringByEvaluatingJavaScriptFromString:jsCode];
}

- (void)renderMessage:(NSDictionary *)message
{
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                     options:kNilOptions
                                                       error:nil];
  NSString *responseJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  NSLog(@"Web data: %@", responseJson);
  NSLog(@"Page name: %@", [self pageName]);
  
  NSString *render = [NSString stringWithFormat:@"window.%@View.render(%@);", [self pageName], responseJson];
  [_webView stringByEvaluatingJavaScriptFromString:render];
}

# pragma mark - WebView delegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if (!webViewReady) {
    for (NSString *event in queuedBinds) {
      [self bindWebEvent:event];
    }
    for (NSDictionary *msg in queuedRenders) {
      [self renderMessage:msg];
    }
    [queuedBinds removeAllObjects];
    [queuedRenders removeAllObjects];
  }
  webViewReady = YES;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // Intercept custom location change, URL begins with "js-call:"
    NSString *requestString = [[request URL] absoluteString];
    if ([requestString hasPrefix:@"js-call:"]) {
      // Extract the event name and any arguments from the URL
      NSArray *eventAndArgs = [[requestString substringFromIndex:[@"js-call:" length]] componentsSeparatedByString:@"&"];
      NSString *event = [eventAndArgs objectAtIndex:0];
      NSMutableArray *args = [NSMutableArray arrayWithCapacity:[eventAndArgs count] - 1];
      for (int i = 1; i < [eventAndArgs count]; ++i) {
        NSString *decoded = [[[eventAndArgs objectAtIndex:i]
                              stringByReplacingOccurrencesOfString:@"+" withString:@" "]
                             stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [args addObject:decoded];
      }
      NSLog(@"Event: %@", event);

      [self dispatchEvent:event withArgs:args];

      // Cancel the location change
      return NO;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return false;
    }
    return YES;
}

- (id)scrollToTop {
  [_webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  [_webView.scrollView flashScrollIndicators];
  return self;
}

- (void)removeWebViewBounceShadow {
   if ([[_webView subviews] count] > 0)
    {
        for (UIView* shadowView in [[[_webView subviews] objectAtIndex:0] subviews])
        {
            [shadowView setHidden:YES];
        }
        // unhide the last view so it is visible again because it has the content
        [[[[[_webView subviews] objectAtIndex:0] subviews] lastObject] setHidden:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
