#import <UIKit/UIKit.h>
#import "BaseUIViewController.h"

@interface WebViewController :  BaseUIViewController <UIWebViewDelegate> {
  NSMutableOrderedSet *queuedBinds;
  NSMutableOrderedSet *queuedRenders;
  BOOL webViewReady;
}

- (id)initWithPageName:(NSString *)thePageName;
- (NSString *)pageName;

@end
