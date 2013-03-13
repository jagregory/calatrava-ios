#import <Foundation/Foundation.h>

@interface UIWebView (SafeJavaScriptExecution)

- (NSString *)stringBySafelyEvaluatingJavaScriptFromString:(NSString *)js;

@end