@protocol CalatravaEventDispatcher

- (void)dispatchEvent:(NSString *)event withArgs:(NSArray *)args;

@end