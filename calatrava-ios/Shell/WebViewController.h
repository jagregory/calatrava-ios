#import <UIKit/UIKit.h>
#import "BaseUIViewController.h"

@interface WebViewController :  BaseUIViewController <UIWebViewDelegate>

- (id)initWithPageName:(NSString *)thePageName;
- (NSString *)pageName;

@end
