#import <Foundation/Foundation.h>
#import <malloc/malloc.h>
#import <substrate.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "GEOShieldMappingManager.h"

typedef struct PointsStruct {
	unsigned x;
	unsigned y;
} PointsStruct;


typedef struct {
	int list;
	unsigned count;
	unsigned size;
} SCD_Struct_VK106;

typedef struct {
	CGPoint origin;
	CGPoint size;
} SCD_Struct_VK63;

@interface VKPShieldIndex : NSObject
-(id)entries;
@end

@interface VKShieldAtlas : NSObject
@end

static void ReachabilityCallback(SCNetworkReachabilityRef target,
                                  SCNetworkReachabilityFlags flags,
                                  void *info) {
    BOOL reachable = (flags & kSCNetworkReachabilityFlagsReachable) &&
                      !(flags & kSCNetworkReachabilityFlagsConnectionRequired);

    if (reachable) {
        [GEOShieldMappingManager cacheToFile];
    }
}

static SCNetworkReachabilityRef reachabilityRef;

%hook GEOResourceManifestServer 

-(void)init {
    reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, "www.apple.com");

    SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
    SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    %orig;
}

%end

// %hook VKPShieldIndex

// -(NSString*)artworkIdentifierForShieldType:(int)shieldType
// {
//     // return %orig(8420);
//     id orig = %orig;
//     if (!orig) {
//         NSLog(@"sdid(%i)", shieldType);
//     }
//     return orig;
// }
// %end

%hook VKShieldManager
-(id)init {
    [GEOShieldMappingManager initForUse];
    return %orig;
}

-(id)artworkForShieldType:(int)shieldType textLength:(NSUInteger)textLen contentScale:(CGFloat)contentScale resourceNames:(id)resourceNames style:(id)style mode:(NSInteger)mode numberOfLines:(NSUInteger)numOfLines {
    int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
    if (newShieldID == 0) return %orig();

    return %orig(newShieldID, textLen, contentScale, resourceNames, style, mode, numOfLines);
}

-(id)artworkForShieldType:(int)shieldType textLength:(NSUInteger)textLen contentScale:(CGFloat)contentScale resourceNames:(id)resourceNames style:(id)style mode:(NSInteger)mode {
    int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
    if (newShieldID == 0) return %orig(shieldType, textLen, contentScale, resourceNames, style, mode);

    return %orig(newShieldID, textLen, contentScale, resourceNames, style, mode);
}

/// iOS 7
- (id)artworkForShieldType:(int)shieldType textLength:(NSUInteger)textLen contentScale:(CGFloat)contentScale resourceNames:(id)resourceNames style:(id)style size:(NSInteger)size idiom:(NSInteger)idiom numberOfLines:(NSUInteger)numberOfLines {
    // NSLog(@"shield type -> %i", shieldType);
    int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
    if (newShieldID == 0) return %orig(shieldType, textLen, contentScale, resourceNames, style, size, idiom, numberOfLines);
    NSLog(@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");

    return %orig(newShieldID, textLen, contentScale, resourceNames, style, size, idiom, numberOfLines);
}

-(id)artworkForShieldType:(int)shieldType textLength:(NSUInteger)textLen contentScale:(CGFloat)contentScale size:(NSUInteger)size idiom:(NSUInteger)idiom mapRect:(SCD_Struct_VK63)mapRect {
    int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
    if (newShieldID == 0) return %orig();

    return %orig(newShieldID, textLen, contentScale, size, idiom, mapRect);
}

-(id)artworkForShieldType:(int)shieldType textLength:(NSUInteger)textLen contentScale:(CGFloat)contentScale size:(NSUInteger)size idiom:(NSUInteger)idiom {
    int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
    if (newShieldID == 0) return %orig();

    return %orig(newShieldID, textLen, contentScale, size, idiom);
}
%end

%hook VKIconManager 

-(id)iconForFeatureID:(uint64_t)featureId withResourceNames:(id)resourceNames style:(void*)style {
    int newIconID = [[GEOShieldMappingManager sharedManager] translateIconMap:featureId];
    if (newIconID == 0)  {
        // NSLog(@"icid(%llu)", featureId);
        return %orig();
    } 
    return %orig(newIconID, resourceNames, style);
}

/// iOS 7
-(id)artworkForFeatureID:(uint64_t)featureId withResourceNames:(id)resourceNames style:(void*)style contentScale:(double)contentScale {
    int newIconID = [[GEOShieldMappingManager sharedManager] translateIconMap:featureId];
    if (newIconID == 0)  {
        NSLog(@"[MapsX] icid(%llu)", featureId);
        return %orig();
    } 
    return %orig(newIconID, resourceNames, style, contentScale);
}

// -(id)artworkForShieldType:(int)shieldType textLength:(unsigned)textLen contentScale:(float)contentScale resourceNames:(id)resourceNames style:(id)style mode:(int)mode {
//     int newShieldID = [[GEOShieldMappingManager sharedManager] translateShieldMap:shieldType];
//     if (newShieldID == 0) return %orig();

//     return %orig(newShieldID, textLen, contentScale, resourceNames, style, mode);
// }

%end