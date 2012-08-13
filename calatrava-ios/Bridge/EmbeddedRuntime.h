#import <Foundation/Foundation.h>
#import "JsRuntime.h"
#import "JSCocoaController.h"

@interface EmbeddedRuntime : NSObject<JsRuntime>
{
  JSCocoaController *jsCore;
  id<JsRtPageDelegate> pageDelegate;
  id<JsRtTimerDelegate> timerDelegate;
  id<JsRtRequestDelegate> requestDelegate;
}

@property (nonatomic, retain) id<JsRtPageDelegate> pageDelegate;
@property (nonatomic, retain) id<JsRtTimerDelegate> timerDelegate;
@property (nonatomic, retain) id<JsRtRequestDelegate> requestDelegate;
@property (nonatomic, retain) id<JsRtUiDelegate> uiDelegate;

- (id)init;

@end
