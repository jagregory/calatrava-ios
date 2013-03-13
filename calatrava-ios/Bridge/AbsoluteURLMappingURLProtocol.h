#import <Foundation/Foundation.h>

// A URLProtocol that will intercept absolute path requests
// from the webview and execute them relative to the bundle
// path. This allows the developer to use absolute urls in
// their HAML files without having to worry that the page
// might be requested as a file:// in iOS
@interface AbsoluteURLMappingURLProtocol : NSURLProtocol
@end