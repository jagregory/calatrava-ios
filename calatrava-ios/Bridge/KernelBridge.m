#import "KernelBridge.h"
#import "WebRuntime.h"
#import "TWBridgePageRegistry.h"
#import "TWBridgeURLRequestManager.h"
#import "PluginRegistry.h"
#import "AlertPlugin.h"
#import "AbsoluteURLMappingURLProtocol.h"

static KernelBridge *kernel = nil;

@implementation KernelBridge

+ (KernelBridge *)sharedKernel
{
  if (kernel == nil)
  {
    kernel = [[KernelBridge alloc] init];
  }
  return kernel;
}

- (id)init
{
  if (self = [super init])
  {
    [NSURLProtocol registerClass:[AbsoluteURLMappingURLProtocol class]];

    //    jsRt = [[EmbeddedRuntime alloc] init];
    jsRt = [[WebRuntime alloc] init];
    pluginRegistry = [[PluginRegistry alloc] init];
  }
  return self;
}

- (PluginRegistry *)pluginRegistry
{
  return pluginRegistry;
}

- (void)startWith:(UINavigationController *)root
{
  NSString *bundle = [[NSBundle mainBundle] bundlePath];
  
  // Load js libraries
  [jsRt loadJsFile:[NSString stringWithFormat:@"%@/public/scripts/underscore.js", bundle]];
  
  // Load js bridge
  [jsRt loadJsFile:[NSString stringWithFormat:@"%@/public/scripts/env.js", bundle]];
  NSString *loadFileText = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/public/load_file.txt", bundle]
                                                     encoding:NSASCIIStringEncoding
                                                        error:nil];
  NSArray *jsFiles = [loadFileText componentsSeparatedByString:@"\n"];
  for (NSString *jsFile in jsFiles) {
    if ([jsFile length] != 0)
    {
      [jsRt loadJsFile:[NSString stringWithFormat:jsFile, bundle]];
    }
  }
  
  [[TWBridgePageRegistry sharedRegistry] attachToRuntime:jsRt under:root];
  [[TWBridgeURLRequestManager sharedManager] attachToRuntime:jsRt under:root];
  [pluginRegistry attachToRuntime:jsRt];
  
  [pluginRegistry registerPlugin:[[AlertPlugin alloc] init]
                           named:@"alert"];
}

- (void)launch:(NSString *)flow
{
  [jsRt callJsFunction:flow withArgs:nil];
}

@end
