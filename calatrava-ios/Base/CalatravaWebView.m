#import "CalatravaWebView.h"
#import "CalatravaEventDispatcher.h"
#import "UIWebView+SafeJavaScriptExecution.h"

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

@end