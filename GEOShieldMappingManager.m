// This handles the conversion between the old shield ids, and the new ones given by the map. 
// Since we don't know all the new ones, and they might change, this is pulled from my server
// - Preloading, May 13th 2026

#import <Foundation/Foundation.h>
#include <Foundation/NSString.h>
#import <CoreFoundation/CoreFoundation.h>
#import "GEOShieldMappingManager.h"
#import "Protobufs.h" // I use protobuf since it's small
#import "shieldmap-protobuf/GEOXShieldMap.h"

@implementation GEOShieldMappingManager

+ (instancetype)sharedManager {
    static GEOShieldMappingManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        NSLog(@"[MapsX] Initalized Shield Manager: %p", sharedManager);
    });
    return sharedManager;
}

+(void)initForUse {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = [[self sharedManager] loadShieldsFile];
        if (error) {
            NSLog(@"[MapsX] failed to load shield maps!!! error -> %@, retrying in four seconds...", error);
            [NSTimer scheduledTimerWithTimeInterval:4.0
                target:[self sharedManager]
                selector:@selector(loadShieldsFile)
                userInfo:nil
                repeats:NO];

        } else {
            NSLog(@"[MapsX] loaded shield maps version %i", [[self sharedManager] dataVersion]);
        }
    });
}

+(void)cacheToFile {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self sharedManager] loadShieldsOnline];
    });
}

// loads the shield data from a cache file. this should probably be used for the geo resource stuff, but thats quite annoying.
-(NSError *)loadShieldsFile {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:@"/private/var/mobile/Library/Caches/GeoServices/shield_maps.dat" options:0 error:&error];
    if (error) {
        NSLog(@"[MapsX] an error occured loading the shield maps! error: %@", error);
        return error;
    }

    if (![self hasFetchedFromOnline]) {
        return [self loadMappingsFromData:data];
    }
    return [NSError errorWithDomain:@"com.skyglow.mapsx.shields" code:48 userInfo:nil];
}

-(void)loadShieldsOnline {
    NSLog(@"[MapsX] downloading latest shield info...");
    NSURL *url = [NSURL URLWithString:@"http://preloading.dev/tweaks/mapsx/shield_maps.dat"]; // no point in having this be HTTPS.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];

    self->_connection =
        [[NSURLConnection alloc] initWithRequest:request
                                        delegate:self
                                startImmediately:NO];
    [self->_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self->_connection start];
}

// online thingies
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self->_recievedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self->_recievedData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"[MapsX] got new shield data!");
    self->_hasFetchedFromOnline = YES;
    NSError *error = [self loadMappingsFromData:self->_recievedData];
    if (error) {
        NSLog(@"[MapsX] Failed to parse downloaded shield maps!!!");
        return;
    }
    [self->_recievedData writeToFile:@"/private/var/mobile/Library/Caches/GeoServices/shield_maps.dat" atomically:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"[MapsX] shield download failed: %@", error);
    self->_connection = nil;
}

-(NSError*)loadMappingsFromData:(NSData*)data {
    PBDataReader *reader = [[NSClassFromString(@"PBDataReader") alloc] initWithData:data];
    PackMessage *pack = [[PackMessage alloc] init];
    BOOL success = [pack readFrom:reader];
    
    if (success && ![reader hasError]) {
        // shield maps
        NSMutableDictionary *shieldMaps = [[NSMutableDictionary alloc] initWithCapacity:pack.shields.count];
        for (MapMessage *message in pack.shields) {
            shieldMaps[@(message.currentId)] = @(message.oldId);
        }
        self->_shieldMappings = [shieldMaps copy];

        // icon maps
        NSMutableDictionary *iconMaps = [[NSMutableDictionary alloc] initWithCapacity:pack.shields.count];
        for (MapMessage *message in pack.icons) {
            iconMaps[@(message.currentId)] = @(message.oldId);
        }
        self->_iconMappings = [iconMaps copy];

        self->_dataVersion = pack.version;
    } else {
        return [NSError errorWithDomain:@"com.skyglow.mapsx.shields" code:49 userInfo:nil];
    }

    return nil;
}

-(int)translateShieldMap:(int)map {
    return [self->_shieldMappings[@(map)] integerValue];
}
-(int)translateIconMap:(uint64_t)map {
    return [self->_iconMappings[@(map)] integerValue];
}

@end