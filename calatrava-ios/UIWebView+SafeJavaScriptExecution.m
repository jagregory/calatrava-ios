#import "UIWebView+SafeJavaScriptExecution.h"

@implementation UIWebView (SafeJavaScriptExecution)

- (NSString *)stringBySafelyEvaluatingJavaScriptFromString:(NSString *)js {
  NSString *result = [self stringByEvaluatingJavaScriptFromString:[self wrapScriptInTryCatch:js]];

  if (!result) {
    // according to this StackOverflow answer http://stackoverflow.com/a/7389032/27206
    // stringByEvaluatingJavaScriptFromString may return nil to indicate an execution timeout.
    @throw [NSException
      exceptionWithName:@"JavaScript Unknown Exception"
                 reason:@"stringByEvaluatingJavaScriptFromString returned nil, which usually indicates a timeout"
               userInfo:nil];
  }

  if ([result hasPrefix:@"@@EX@@"]) {
    // the javascript execution failed with an unhandled exception, result should contain the exception
    @throw [NSException
      exceptionWithName:@"JavaScript Exception"
                 reason:[result stringByReplacingOccurrencesOfString:@"@@EX@@" withString:@""]
               userInfo:nil];
  }

  return result;
}

- (NSString *)wrapScriptInTryCatch:(NSString *)js {
  return [NSString stringWithFormat:@"(function() { try { return %@; } catch (ex) { return '@@EX@@' + ex.toString() + '\\n' + ex.stack.toString(); } })();", js];
}

@end