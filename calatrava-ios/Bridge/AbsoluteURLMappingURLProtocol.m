#import "AbsoluteURLMappingURLProtocol.h"

@interface AbsoluteURLMappingURLProtocol () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation AbsoluteURLMappingURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
  if (![request.URL.scheme isEqualToString:@"file"]) {
    // not a file request, we don't want to do anything with it.
    // let the normal stack handle it
    return NO;
  }

  if (![request.URL.path hasPrefix:@"/"]) {
    // not an absolute file request, skip it
    return NO;
  }

  for (NSString* prefix in @[@"/var", @"/Users"]) {
    if ([request.URL.path hasPrefix:prefix]) {
      // URL is a valid file
      return NO;
    }
  }

  // if we've got here, then the request is for an absolute file path.
  // it won't work normally because the page is loaded using a file://
  // scheme which breaks absolute URLs. We intercept them here and
  // turn them into acceptable file:// urls.
  return YES;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
  return request;
}

- (id)initWithRequest:(NSURLRequest*)request cachedResponse:(NSCachedURLResponse*)cachedResponse client:(id <NSURLProtocolClient>)client {
  // clone the requested URL and tinker with it so it's a proper file URL relative to the bundle
  NSMutableURLRequest* mutableRequest = [request mutableCopy];
  NSURL* tweakedUrl = [NSURL URLWithString:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:[NSString stringWithFormat:@"%@public", [[NSBundle mainBundle] bundleURL].absoluteString]]];
  [mutableRequest setURL:tweakedUrl];

  self = [super initWithRequest:mutableRequest cachedResponse:cachedResponse client:client];
  return self;
}

- (void)startLoading {
  [NSURLConnection connectionWithRequest:self.request delegate:self];
}

- (void)stopLoading {
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  [[self client] URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
  [[self client] URLProtocol:self didFailWithError:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
  [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
  [[self client] URLProtocolDidFinishLoading:self];
}

@end