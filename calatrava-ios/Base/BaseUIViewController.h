#import <UIKit/UIKit.h>
#import "CalatravaEventDispatcher.h"

@interface BaseUIViewController : UIViewController <CalatravaEventDispatcher> {
    NSMutableDictionary *handlers;
}

- (id)attachHandler:(NSString *)proxyId forEvent:(NSString *)event;
- (id)dispatchEvent:(NSString *)event withArgs:(NSArray *)args;
- (id)valueForField:(NSString *)field;
- (void)render:(NSDictionary *)viewMessage;
- (void) scrollToTop;
- (void) displayDialog:(NSString *)message;
@end
