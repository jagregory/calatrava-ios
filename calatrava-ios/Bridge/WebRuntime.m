#import "WebRuntime.h"
#import "UIWebView+SafeJavaScriptExecution.h"

@interface WebRuntime()

- (NSString *)argsToString:(NSArray *)args;
- (id)objectFromArgs:(NSArray *) args
             AtIndex:(int)index;

@end

@implementation WebRuntime

@synthesize pageDelegate;
@synthesize timerDelegate;
@synthesize requestDelegate;
@synthesize uiDelegate;
@synthesize pluginDelegate;

- (id)init
{
  if (self = [super init])
  {
    rtWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    
    isLoadingHtml = YES;
    outstandingScriptLoads = 0;
    filesToLoad = [[NSMutableArray alloc] init];
    functionsToCall = [[NSMutableArray alloc] init];
    [rtWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/webRuntime.html", [[NSBundle mainBundle] bundlePath]]]]];
    [rtWebView setDelegate:self];
  }
  return self;
}

- (void)loadJsFile:(NSString *)path
{
  if (isLoadingHtml)
  {
    [filesToLoad addObject:path];
  }
  else
  {
    NSLog(@"Loading: %@", path);
    ++outstandingScriptLoads;
    [rtWebView stringBySafelyEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calatrava.bridge.native.load('%@');", path]];
  }
}

- (void)callJsFunction:(NSString *)function withArgs:(NSArray *)args
{
  if (isLoadingHtml || outstandingScriptLoads > 0)
  {
    NSArray *storeArgs = args == nil ? [NSArray array] : args;
    [functionsToCall addObject:@{ @"function" : function,
     @"args" : storeArgs }];
  }
  else
  {
    NSString *funcCall = [NSString stringWithFormat:@"%@(%@);", function, [self argsToString:args]];
    NSString *returnVal = [rtWebView stringBySafelyEvaluatingJavaScriptFromString:funcCall];
    NSLog(@"Function '%@' returned: %@", funcCall, returnVal);
  }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  isLoadingHtml = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  isLoadingHtml = NO;
  if ([filesToLoad count] > 0)
  {
    [self loadJsFile:[filesToLoad objectAtIndex:0]];
    [filesToLoad removeObjectAtIndex:0];
  }
}

-            (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
  // Intercept custom location change, URL begins with "native-call:"
  NSString *funcPrefix = @"native-call:";
  NSString *requestString = [[request URL] absoluteString];
  NSLog(@"Web RT loading: %@", requestString);
  if ([requestString hasPrefix:funcPrefix])
  {
    NSArray *functionAndArgs = [[requestString substringFromIndex:[funcPrefix length]] componentsSeparatedByString:@"&"];
    NSString *function = [functionAndArgs objectAtIndex:0];
    NSString *argsJson = [rtWebView stringBySafelyEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calatrava.bridge.native.getArgs('%@');", [functionAndArgs objectAtIndex:1]]];
    NSLog(@"Targeting: %@", function);
    NSLog(@"With args: %@", argsJson);
    NSArray *args = (NSArray *)[NSJSONSerialization JSONObjectWithData:[argsJson dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:0
                                                                 error:nil];
    
    if ([function isEqualToString:@"log"]) {
      NSLog(@"WebRTLog: %@", args);
    } else if ([function isEqualToString:@"changePage"]) {
      [pageDelegate changeToPage:[self objectFromArgs:args AtIndex:0]];
    } else if ([function isEqualToString:@"registerProxyForPage"]) {
      [pageDelegate registerProxy:[self objectFromArgs:args AtIndex:0]
                          forPage:[self objectFromArgs:args AtIndex:1]];
    } else if ([function isEqualToString:@"attachProxyEventHandler"]) {
      [pageDelegate attachHandlerTo:[self objectFromArgs:args AtIndex:0]
                           forEvent:[self objectFromArgs:args AtIndex:1]];
    } else if ([function isEqualToString:@"renderProxy"]) {
      [pageDelegate render:[self objectFromArgs:args AtIndex:1]
                      with:[self objectFromArgs:args AtIndex:0]];
    } else if ([function isEqualToString:@"valueOfProxyField"]) {
      [pageDelegate valueFrom:[self objectFromArgs:args AtIndex:0]
                     forField:[self objectFromArgs:args AtIndex:1]
                   returnedTo:[self objectFromArgs:args AtIndex:2]];
    } else if ([function isEqualToString:@"issueRequest"]) {
      [requestDelegate requestFrom:[self objectFromArgs:args AtIndex:0]
                               url:[self objectFromArgs:args AtIndex:1]
                                as:[self objectFromArgs:args AtIndex:2]
                              with:[self objectFromArgs:args AtIndex:3]
                           headers:[self objectFromArgs:args AtIndex:4]];
    } else if ([function isEqualToString:@"startTimerWithTimeout"]) {
      [timerDelegate startTimer:[self objectFromArgs:args AtIndex:0]
                        timeout:[[self objectFromArgs:args AtIndex:1] integerValue]];
    } else if ([function isEqualToString:@"openUrl"]) {
      [uiDelegate openUrl:[self objectFromArgs:args AtIndex:0]];
    } else if ([function isEqualToString:@"loadComplete"]) {
      --outstandingScriptLoads;
      [self webViewDidFinishLoad:webView];
      if (outstandingScriptLoads == 0) {
        for (NSDictionary *call in functionsToCall) {
          [self callJsFunction:[call objectForKey:@"function"]
                      withArgs:[call objectForKey:@"args"]];
        }
        [functionsToCall removeAllObjects];
      }
    } else if ([function isEqualToString:@"callPlugin"]) {
      [pluginDelegate callPlugin:[self objectFromArgs:args AtIndex:0]
                          method:[self objectFromArgs:args AtIndex:1]
                        withArgs:[self objectFromArgs:args AtIndex:2]];
    } else {
      NSLog(@"Unknown function call!");
    }
    return NO;
  }
  else
  {
    if (![requestString hasSuffix:@"webRuntime.html"]) {
      NSLog(@"Unknown RT load cancelled.");
      return NO;
    } else {
      return YES;
    }
  }
}

- (NSString *)argsToString:(NSArray *)args
{
  NSMutableArray *formattedArgs = [[NSMutableArray alloc] initWithCapacity:[args count]];
  for (id arg in args)
  {
    NSString *formatted;
    if ([arg isKindOfClass:[NSString class]]) {
      formatted = [arg stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
      formatted = [NSString stringWithFormat:@"\"%@\"", [formatted stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    } else if ([arg isKindOfClass:[NSNumber class]]) {
      formatted = arg;
    } else if ([arg isKindOfClass:[NSDictionary class]] || [arg isKindOfClass:[NSArray class]]) {
      NSError *err;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arg options:0 error:&err];
      formatted = [[NSString alloc] initWithBytes:[jsonData bytes]
                                                        length:[jsonData length]
                                                      encoding:NSUTF8StringEncoding];
    }
    [formattedArgs addObject:formatted];
  }
  
  return [formattedArgs componentsJoinedByString:@", "];
}

- (id)objectFromArgs:(NSArray *) args
             AtIndex:(int)index
{
  id obj = [args objectAtIndex:index];
  if (obj == [NSNull null])
  {
    return nil;
  }
  else
  {
    return obj;
  }
}

@end
