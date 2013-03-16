#import "CalatravaWebView.h"
#import "CalatravaEventDispatcher.h"
#import "UIWebView+SafeJavaScriptExecution.h"

@interface ComposedUIWebViewDelegate : NSObject<UIWebViewDelegate>

+ (ComposedUIWebViewDelegate*)delegateWith:(NSArray*)delegates;

@end

@implementation ComposedUIWebViewDelegate {
  NSArray* delegates;
}

+ (ComposedUIWebViewDelegate*)delegateWith:(NSArray*)delegates {
  return [[ComposedUIWebViewDelegate alloc] initWith:delegates];
}

- (id)initWith:(NSArray*)theDelegates {
  if (self = [self init]) {
    delegates = theDelegates;
  }
  
  return self;
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
  for (id <UIWebViewDelegate> delegate in delegates) {
    if ([delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
      if ([delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType]) {
        return YES;
      }
    }
  }

  return NO;
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
  for (id <UIWebViewDelegate> delegate in delegates) {
    if ([delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
      [delegate webViewDidStartLoad:webView];
    }
  }
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
  for (id <UIWebViewDelegate> delegate in delegates) {
    if ([delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
      [delegate webViewDidFinishLoad:webView];
    }
  }
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
  for (id <UIWebViewDelegate> delegate in delegates) {
    if ([delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
      [delegate webView:webView didFailLoadWithError:error];
    }
  }
}

@end

@interface CalatravaWebView () <UIWebViewDelegate>
@end

@implementation CalatravaWebView {
  BOOL isReady;
  NSMutableOrderedSet* queuedJavascript;
  id <CalatravaEventDispatcher> eventDispatcher;
}

- (id)initWithEventDispatcher:(id <CalatravaEventDispatcher>)theEventDispatcher {
  if (self = [self initWithFrame:CGRectZero]) {
    eventDispatcher = theEventDispatcher;
    self.delegate = self;
    queuedJavascript = [[NSMutableOrderedSet alloc] init];
  }

  return self;
}

- (void)setDelegate:(id <UIWebViewDelegate>)delegate {
  [super setDelegate:[ComposedUIWebViewDelegate delegateWith:@[self, delegate]]];
}

- (void)enqueueJavascript:(NSString*)javascript {
  if (isReady) {
    [self stringBySafelyEvaluatingJavaScriptFromString:javascript];
  } else {
    [queuedJavascript addObject:javascript];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if (!isReady) {
    for (NSString *javascript in queuedJavascript) {
      [self stringBySafelyEvaluatingJavaScriptFromString:javascript];
    }

    [queuedJavascript removeAllObjects];
  }

  isReady = YES;
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

    [eventDispatcher dispatchEvent:event withArgs:args];

    // Cancel the location change
    return NO;
  }

  if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    [[UIApplication sharedApplication] openURL:request.URL];
    return false;
  }

  return YES;
}

- (void)loadView:(NSString*)pageName {
  // read the HTML file from disk and load it with a base URL,
  // this makes the page act as if it was requested from the
  // public dir rather than the public/views dir.
  NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"public/views/%@", pageName] ofType:@"html"];
  NSString* publicPath = [NSString stringWithFormat:@"%@/public", [[NSBundle mainBundle] bundlePath]];
  NSString* content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];

  [self loadHTMLString:content baseURL:[NSURL fileURLWithPath:publicPath]];
}

@end