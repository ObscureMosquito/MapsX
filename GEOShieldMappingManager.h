#import <Foundation/Foundation.h>

@interface GEOShieldMappingManager : NSObject
@property (atomic, strong) NSDictionary *shieldMappings;
@property (atomic, strong) NSDictionary *iconMappings;
@property (atomic, assign) int dataVersion;
@property (atomic, assign) BOOL hasFetchedFromOnline;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *recievedData;


+ (instancetype)sharedManager;
-(NSError *)loadShieldsFile;
-(NSError*)loadMappingsFromData:(NSData*)data;
-(int)translateShieldMap:(int)map;
-(int)translateIconMap:(uint64_t)map;
+(void)initForUse;
+(void)cacheToFile;
@end
