#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <execinfo.h>
#import "Protobufs.h"
#import "GeoHeaders.h"
#import "GEOQueryToLatLng.h"

%group EnableDirectionsPatch
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

        [writer writeUint32:3 forTag:3];

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
%end

%ctor {
	if (kCFCoreFoundationVersionNumber <= 847.27) {
		%init(EnableDirectionsPatch);
	}
}