#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "GEOTokenManager.h"
#import <execinfo.h>
#import "Protobufs.h"
#import "GeoHeaders.h"
#import "GEOQueryToLatLng.h"
#import <objc/message.h>

NSURL *addAccessKeyToURL(NSURL *originalURL) {
    if (!originalURL) return originalURL;
    
    NSString *urlString = [originalURL absoluteString];
    NSString *token = [[GEOTokenManager sharedManager] currentAccessKey];
    
    // Parse URL parts
    NSString *baseURLString;
    NSString *queryString;
    
    // Split URL into base and query components
    NSRange queryRange = [urlString rangeOfString:@"?"];
    if (queryRange.location == NSNotFound) {
        baseURLString = urlString;
        queryString = @"";
    } else {
        baseURLString = [urlString substringToIndex:queryRange.location];
        queryString = [urlString substringFromIndex:queryRange.location + 1];
    }
    
    // Parse query parameters
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    NSArray *queryPairs = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *pair in queryPairs) {
        if ([pair length] == 0) continue;
        
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if ([keyValue count] < 2) continue;
        
        NSString *key = customURLDecode(keyValue[0]);
        NSString *value = customURLDecode(keyValue[1]);
        
        queryParams[key] = value;
    }
    
    // Add accessKey parameter
    queryParams[@"accessKey"] = token;
    
    // Rebuild query string
    NSMutableArray *newQueryPairs = [NSMutableArray array];
    for (NSString *key in queryParams) {
        NSString *value = queryParams[key];
        
        NSString *escapedKey = customURLEncode(key);
        NSString *escapedValue = customURLEncode(value);
        
        [newQueryPairs addObject:[NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue]];
    }
    
    NSString *newQueryString = [newQueryPairs componentsJoinedByString:@"&"];
    NSString *newURLString = baseURLString;
    if ([newQueryString length] > 0) {
        newURLString = [baseURLString stringByAppendingFormat:@"?%@", newQueryString];
    }
    
    return [NSURL URLWithString:newURLString];
}

%hook GEOResourceManifestServerLocalProxy

- (id)_manifestURL {
    id originalURL = %orig;
    NSLog(@"Original Manifest URL: %@", originalURL);

    NSString *newURLString = @"https://gsp21.ls.apple.com/config/prod-resources-hidpi-20";

    // Return the new URL
    return newURLString;
}

%end

%hook NSURLRequest

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    //  URL Rewrites
	if (!URL) {
		NSLog(@"[MapsX] Bad URL");
		return %orig;
	}
	
	NSString *host = [URL host];
	if (!host) {
		NSLog(@"[MapsX] Bad URL: %@", [URL absoluteString]);
		return %orig;
	}

	NSString *newHost = nil;
	BOOL modifyHost = false;
	if ([host isEqualToString:@"gspa35-ssl.ls.apple.com"]) {
		newHost = @"gspe35-ssl.ls.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gspa11.ls.apple.com"]) {
		newHost = @"gspe11-ssl.ls.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gspa12.ls.apple.com"]) {
		newHost = @"gspe12-ssl.ls.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gspa19.ls.apple.com"]) {
		newHost = @"gspe19.ls.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gspa21.ls.apple.com"]) {
		newHost = @"gsp21.ls.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gsp1.apple.com"]) {
		newHost = @"gsp1.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gs-loc.apple.com"]) {
		newHost = @"gsp10-ssl.apple.com";
		modifyHost = true;
	} else if ([host isEqualToString:@"gspe21-ssl.ls.apple.com"]) {
		newHost = @"gsp21.ls.apple.com";
		modifyHost = true;
	}

	if (!modifyHost) {
		return %orig;
	}

	// and now for the fun bit, recreating!
	NSString *scheme = [URL scheme];
	NSString *path = [URL path];
	NSString *query = [URL query];

	NSMutableString *newURLString = [NSMutableString string];
	[newURLString appendFormat:@"%@://%@", scheme, newHost];

	// now for the extra params
	// if (path && ![path isEqualToString:@""]) {
    //     if ([newHost isEqualToString:@"gsp64-ssl.ls.apple.com"] && [path isEqualToString:@"/use"]) {
    //         [newURLString appendString:@"/a/v2/use"];
    //     } else {
            [newURLString appendString:path];
    //     }
	// }

	if (query && ![query isEqualToString:@""]) {
		[newURLString appendFormat:@"?%@", query];
	}

    NSURL *newURL = [NSURL URLWithString:newURLString];
    return %orig(newURL, cachePolicy, timeoutInterval);
}

%end

%hook NSURLConnection

- (instancetype)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
    NSURL *originalURL = [request URL];
    if (!(
         ([[originalURL host] isEqualToString:@"gspe11-ssl.ls.apple.com"]) || 
         ([[originalURL host] isEqualToString:@"gspe11.ls.apple.com"]) || 
         ([[originalURL host] isEqualToString:@"gspe19.ls.apple.com"]) || 
         ([[originalURL host] isEqualToString:@"gspe12-ssl.ls.apple.com"]))) {
        return %orig(request, delegate, startImmediately);
    }

    // NSString *urlString = [originalURL absoluteString];
    
    // NSLog(@"Original URL (initWithRequest:delegate:startImmediately:): %@", urlString);
    
    // Use the helper function to add the accessKey parameter
    NSURL *newURL = addAccessKeyToURL(originalURL);
    
    // Create a mutable copy of the request and set the new URL
    NSMutableURLRequest *modifiedRequest = [request mutableCopy];
    [modifiedRequest setURL:newURL];
    
    // NSLog(@"Modified URL (initWithRequest:delegate:startImmediately:): %@", [newURL absoluteString]);
    
    return %orig(modifiedRequest, delegate, startImmediately);
}

%end

%hook GEODirectionsRequest

-(void)writeTo:(id)writer {
    // void *callstack[128];
    // int frames = backtrace(callstack, 128);
    // char **symbols = backtrace_symbols(callstack, frames);
    // NSString *imlazy = @"a";
    // NSMutableString *callstackString = [NSMutableString stringWithFormat:@"[MapsX] Callstack for modifying %@:\n", imlazy];
    // for (int i = 0; i < frames; i++) {
    //     [callstackString appendFormat:@"%s\n", symbols[i]];
    // }
    // NSLog(@"%@", callstackString);
    
    // free(symbols);
    NSLog(@"[MapsX] GEODirectionsRequest.writeTo called!");
    if ([writer isKindOfClass:[PBDataWriter class]]) {      
        NSValue *hasValue = [self valueForKey:@"_has"];
        unsigned int hasFlags = 0;
        
        // i have no clue if this works
        if ([hasValue isKindOfClass:[NSNumber class]]) {
            hasFlags = [(NSNumber *)hasValue unsignedIntValue];
        } else {
            [hasValue getValue:&hasFlags];
        }
        
        NSLog(@"[MapsX] Has flags: %u", hasFlags);

        // route attributes  
        PBCodable *routeAttributes = [self valueForKey:@"_routeAttributes"];
        if (routeAttributes != nil) {
            PBDataWriter *dataWriter = [[PBDataWriter alloc] init];
            [routeAttributes writeTo:dataWriter];
            [writer writeData:[dataWriter data] forTag:1];
        }

        if (hasFlags & 0x2) {  // maxRouteCount flag
            NSNumber *maxRouteCount = [self valueForKey:@"_maxRouteCount"];
            if (maxRouteCount != nil) {
                [writer writeUint32:[maxRouteCount unsignedIntValue] forTag:3]; // mainTransportTypeMaxRouteCount on iOS 11
            }
        }
        
        PBCodable *currentUserLocation = [self valueForKey:@"_currentUserLocation"];
        if (currentUserLocation != nil) {
            PBDataWriter *dataWriter = [[PBDataWriter alloc] init];
            [currentUserLocation writeTo:dataWriter];
            [writer writeData:[dataWriter data] forTag:4];
        }

        GEOMapRegion *currentMapRegion = [self valueForKey:@"_currentMapRegion"];
        if (currentMapRegion != nil) {
            PBDataWriter *dataWriter = [[PBDataWriter alloc] init];
            [currentMapRegion writeTo:dataWriter];
            [writer writeData:[dataWriter data] forTag:5];
        }
        

        NSData* (^writeWaypointAsTyped)(GEOWaypoint *) = ^NSData* (GEOWaypoint *waypoint) {
            PBDataWriter *waypointWriter = [[PBDataWriter alloc] init];
            // I'm not sure of all the types but,
            // 2 = place search result?
            // 4 = Latlong/gps loc?

            // In actual source it's
            // 2 = Waypoint ID
            // 3 = Waypoint Place
            // 4 = Waypoint Location
            GEOPlaceSearchRequest *placeRequest = [waypoint valueForKey:@"_placeSearchRequest"];
            GEOPlaceSearchRequest *location = [waypoint valueForKey:@"_location"];
            if (placeRequest) { // type 2, GEOWaypointID, https://github.com/nst/iOS-Runtime-Headers/blob/f53e3d01aceb4aab6ec2c37338d2df992d917536/PrivateFrameworks/GeoServices.framework/GEOWaypointID.h
                // logGEOPlaceSearchRequestDetails(placeRequest);
                [waypointWriter writeInt32:2 forTag:1];
                PBDataWriter *waypointId = [[PBDataWriter alloc] init];
                // [waypointId writeUint64:11026153924627430591LLU forTag:1]; // I think this is some sort of ID for the location? i dunno.
                // [waypointId writeUint64:7618 forTag:2]; // ResultProviderId
                NSString *search = [placeRequest valueForKey:@"_search"]; // I am not happy about this being the only data for some requests.
                GEOLocation *placeLocation = [placeRequest valueForKey:@"_location"];
                if (placeLocation) {
                    GEOLatLng *latLng = [placeLocation valueForKey:@"_latLng"];
                    if (latLng) {
                        NSNumber *lat = [latLng valueForKey:@"_lat"];
                        NSNumber *lng = [latLng valueForKey:@"_lng"];
                        if (lat && lng) {
                            PBDataWriter *latlong = [[PBDataWriter alloc] init];
                            [latlong writeDouble:[lat doubleValue] forTag:1];
                            [latlong writeDouble:[lng doubleValue] forTag:2];
                            [waypointId writeData:[latlong data] forTag:3];
                        }
                    }
                    GEOAddress *address = [placeRequest valueForKey:@"_address"]; // if it has it.
                    if (address) {
                        GEOStructuredAddress *stAddress = [placeRequest valueForKey:@"_structuredAddress"];
                        if (stAddress) {
                            PBDataWriter *stAddressP = [[PBDataWriter alloc] init];
                            [stAddress writeTo:stAddressP];
                            [waypointId writeData:[stAddressP data] forTag:4];
                        }
                    }
                } else {
                    GEOAddress *address = [placeRequest valueForKey:@"_address"];
                    if (address) {
                        NSLog(@"[MapsX] has address");
                        GEOStructuredAddress *stAddress = [placeRequest valueForKey:@"_structuredAddress"];
                        if (stAddress) {
                            NSLog(@"[MapsX] writing structured address data ");
                            PBDataWriter *stAddressP = [[PBDataWriter alloc] init];
                            [stAddress writeTo:stAddressP];
                            [waypointId writeData:[stAddressP data] forTag:4];
                        }
                    } else {
                        // welcome to nightmare mode. from here, we do not have enough information to complete the request successfully. We need extra data. Which means a web request! 2G users must be screaming rn.
                        if (search) {
                            NSLog(@"[MapsX] search request %@", search);
                            if (currentMapRegion) { 
                                NSLog(@"[MapsX] generating new data");
                                GEOWaypointID *waypointID = [GEOWaypointID alloc];
                                NSError *error = [GEOQueryToLatLng getQueryToLatLng:search region:currentMapRegion out:waypointID];
                                if (!error) {
                                    // nice
                                    [waypointID writeTo:waypointId]; // crimes
                                } else {
                                    NSLog(@"[MapsX] Failed to get more info for location: %@", error);
                                }
                            } else {
                                NSLog(@"[MapsX] Uhhhh we don't have currentMapRegion, thats fun!");
                            }
                            

                            // [waypointId writeString:search forTag:5]; 
                            // [waypointId writeString:search forTag:6]; // mapRegion, or smth like that
                        } else {
                            NSLog(@"[MapsX] no search request, uhhhh what? bruh.");
                        }
                    }
                }
                

                // [waypointId writeString:@"Los Angeles" forTag:5]; // placeName
                
                
                [waypointId writeInt32:16 forTag:7]; // placeTypeHint
                [waypointWriter writeData:[waypointId data] forTag:2];
            } else if (location) {
                [waypointWriter writeInt32:4 forTag:1];// types
        
                // // Create a properly nested message for tag4 inside tag22
                PBDataWriter *locationP = [[PBDataWriter alloc] init];
                [location writeTo:locationP];

                PBDataWriter *tag22_4 = [[PBDataWriter alloc] init];
                [tag22_4 writeData:[locationP data] forTag:1];
                
                [waypointWriter writeData:[tag22_4 data] forTag:4];
                [waypointWriter writeInt32:1 forTag:5];
            }
            return [waypointWriter data];
        };
        
        NSArray *waypoints = [self valueForKey:@"_waypoints"];
        NSFastEnumerationState state = {0};
        __unsafe_unretained id objects[16];
        NSUInteger count = [waypoints countByEnumeratingWithState:&state objects:objects count:16];
        if (count != 0) {
            do {
                for (NSUInteger i = 0; i < count; i++) {
                    id waypoint = state.itemsPtr[i];
                    NSData *waypointData = writeWaypointAsTyped(waypoint);
                    [writer writeData:waypointData forTag:22]; // waypointTyped
                }
                count = [waypoints countByEnumeratingWithState:&state objects:objects count:16];
            } while (count != 0);
        } 


        NSArray *serviceTags = [self valueForKey:@"_serviceTags"];
        NSFastEnumerationState serviceState = {0};
        __unsafe_unretained id serviceObjects[16];
        count = [serviceTags countByEnumeratingWithState:&serviceState objects:serviceObjects count:16];
        if (count != 0) {
            do {
                for (NSUInteger i = 0; i < count; i++) {
                    id serviceTag = serviceState.itemsPtr[i];
                    PBDataWriter *serviceWriter = [[PBDataWriter alloc] init];
                    [serviceTag writeTo:serviceWriter];
                    [writer writeData:[serviceWriter data] forTag:100];
                }
                count = [serviceTags countByEnumeratingWithState:&serviceState objects:serviceObjects count:16];
            } while (count != 0);
        }
        
    } else {
        return %orig;
    }
}

%end
// %hook GEOAltitudeManifest
// + (id)sharedManager { %log; id r = %orig; NSLog(@" = %@", r); return r; }
// - (void)parser:(id)arg1 didStartElement:(id)arg2 namespaceURI:(id)arg3 qualifiedName:(id)arg4 attributes:(id)arg5 { %log; %orig; }
// - (void)parseManifest:(id)arg1 { %log; %orig; }
// - (id)availableRegions { %log; id r = %orig; NSLog(@" = %@", r); return r; }
// - (unsigned int)versionForRegion:(unsigned int)arg1 { %log; unsigned int r = %orig; NSLog(@" = %u", r); return r; }
// - (void)dealloc { %log; %orig; }
// - (BOOL)parseXml:(id)arg1 { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
// - (void)_activeTileGroupChanged:(id)arg1 { %log; %orig; }
// - (id)initWithoutObserver { %log; id r = %orig; NSLog(@" = %@", r); return r; }
// - (id)init { %log; id r = %orig; NSLog(@" = %@", r); return r; }
// %end


// // %hook AltitudeNetworkRunLoop
// // + (void)AltitudeNetworkRun:(id)arg1 { %log; %orig; }
// // + (void)_runNetworkThread:(id)arg1 { %log; %orig; }
// // %end
// %hook AltMapView
// // + (Class)layerClass { %log; Class r = %orig; NSLog(@" = %@", r); return r; }
// // - (void)setDirectionsDelegate:(NSObject *)directionsDelegate { %log; %orig; }
// // - (NSObject *)directionsDelegate { %log; NSObject *r = %orig; NSLog(@" = 0x%llx", (uint64_t)r); return r; }
// // - (void)setDownloading:(BOOL)downloading { %log; %orig; }
// // - (BOOL)downloading { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
// // - (void)setDelegate:(id)delegate { %log; %orig; }
// // - (id)delegate { %log; id r = %orig; NSLog(@" = 0x%llx", (uint64_t)r); return r; }
// // - (void)setRenderer:(__strong id *)renderer { %log; %orig; }
// // - (__strong id *)renderer { %log; __strong id *r = %orig; NSLog(@" = %p", r); return r; }
// - (void)setManifest:(NSString *)manifest { %log; %orig; }
// - (NSString *)manifest { %log; NSString *r = %orig; NSLog(@" = %@", r); return r; }
// // - (void)initialize { %log; %orig; }
// %end

// // %hook AltTileFetcher
// // - (BOOL)isDownloading { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
// // - (void)purgeExpired:(double)arg1 { %log; %orig; }
// // - (void)cancelRequests { %log; %orig; }
// // - (_Bool)fetchDataForJobs:(id)arg1 count:(unsigned int)arg2 { %log; _Bool r = %orig; NSLog(@" = %d", r); return r; }
// // %end
