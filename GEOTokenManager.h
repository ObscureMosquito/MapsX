#import <Foundation/Foundation.h>

@interface GEOTokenManager : NSObject

+ (instancetype)sharedManager;
- (NSString *)currentAccessKey;
- (NSString *)currentAccessToken;

@end