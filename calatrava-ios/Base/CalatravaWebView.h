#import <Foundation/Foundation.h>

@protocol CalatravaEventDispatcher;

@interface CalatravaWebView : UIWebView

- (id)initWithEventDispatcher:(id <CalatravaEventDispatcher>)eventDispatcher;

// execute a javascript string, this may be deferred until the
// webview has finished loading
- (void)enqueueJavascript:(NSString*)javascript;

@end