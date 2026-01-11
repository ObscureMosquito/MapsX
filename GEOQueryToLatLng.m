#import <Foundation/Foundation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSError.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#import <CoreFoundation/CoreFoundation.h>
#import "GEOTokenManager.h"
#import "GEOQueryToLatLng.h"
#import "GeoHeaders.h"

// Custom URL decoding function, i duplicated this because im tired
NSString *customURLDecode(NSString *string) {
    if (!string) return nil;
    
    NSMutableString *result = [NSMutableString string];
    NSUInteger length = [string length];
    NSUInteger i = 0;
    
    while (i < length) {
        unichar c = [string characterAtIndex:i];
        if (c == '%' && i + 2 < length) {
            // Try to parse the hex value
            NSString *hexStr = [string substringWithRange:NSMakeRange(i + 1, 2)];
            NSScanner *scanner = [NSScanner scannerWithString:hexStr];
            unsigned int hexValue;
            
            if ([scanner scanHexInt:&hexValue]) {
                [result appendFormat:@"%C", (unichar)hexValue];
                i += 3; // Skip the '%' and the two hex digits
            } else {
                // If it's not a valid hex sequence, just add the '%'
                [result appendString:@"%"];
                i++;
            }
        } else if (c == '+') {
            // '+' is decoded as space
            [result appendString:@" "];
            i++;
        } else {
            // Not encoded, add as is
            [result appendFormat:@"%C", c];
            i++;
        }
    }
    
    return result;
}

// Hell. You may be wondering why is this nessiary?
// well stringByAddingPercentEscapesUsingEncoding doesn't encode = for the query params :)
NSString *customURLEncode(NSString *string) {
    if (!string) return nil;
    
    // Characters that don't need encoding in URLs
    NSString *reservedChars = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
    
    NSMutableString *result = [NSMutableString string];
    NSUInteger length = [string length];
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [string characterAtIndex:i];
        if ([reservedChars rangeOfString:[NSString stringWithFormat:@"%C", c]].location != NSNotFound) {
            // Character doesn't need encoding
            [result appendFormat:@"%C", c];
        } else {
            // Character needs encoding
            [result appendFormat:@"%%%02X", c];
        }
    }
    
    return result;
}

@interface GEOQueryToLatLng ()
@end

@implementation GEOQueryToLatLng

+(NSError*)getQueryToLatLng:(NSString*)query region:(GEOMapRegion*)currentMapRegion out:(GEOWaypointID*)output{
    NSString *queryURL = [NSString stringWithFormat:@"https://api.apple-mapkit.com/v1/searchAutocomplete?q=%@&searchRegion=%f,%f,%f,%f&mkjsVersion=5.78.158", customURLEncode(query), currentMapRegion.northLat, currentMapRegion.eastLng, currentMapRegion.southLat, currentMapRegion.westLng];
    NSString *token = [[GEOTokenManager sharedManager] currentAccessToken];

    // make request
    NSURL *url = [NSURL URLWithString:queryURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url 
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                 timeoutInterval:60.0];
    
    [request setHTTPMethod:@"GET"];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    
    NSLog(@"[MapsX] URL is %@", queryURL);


    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request // its a blocking thread, but theres not much i can do.
                                         returningResponse:&response 
                                                     error:&error];
    
    if (error) {
        NSLog(@"[MapsX] Request failed to get more info on directions query: %@", [error localizedDescription]);
        return error;
    }
    
    error = nil;
    id object = [NSJSONSerialization
                      JSONObjectWithData:responseData
                      options:0
                      error:&error];

    if(error) { 
        NSLog(@"[MapsX] Failed to decode location query JSON: %@", [error localizedDescription]);
        return error; 
    }

    if([object isKindOfClass:[NSDictionary class]])
    {  
        NSDictionary *data = object;

        if ([data[@"results"] isKindOfClass:[NSArray class]] && ([data[@"results"] count] > 0)) {
            NSArray *mapResults = data[@"results"];
            for (int i = 0; mapResults.count > i; i++) {
                if (mapResults[i][@"type"] && ![mapResults[i][@"type"] isEqualToString:@"QUERY"]) {
                    // hopefully a valid place. i hope
                    NSDictionary *mapPlace = mapResults[i];
                    if (mapPlace[@"muid"]) { output.muid = [mapPlace[@"muid"] longLongValue]; }
                    
                    // Lat long
                    if ([mapPlace[@"location"] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *locationInfo = mapPlace[@"location"];
                        GEOLatLng *locationHint = [GEOLatLng alloc];
                        [locationHint setValue:locationInfo[@"lat"] forKey:@"_lat"];
                        [locationHint setValue:locationInfo[@"lng"] forKey:@"_lng"];
                        output.locationHint = locationHint;
                    }

                    // address lines
                    if ([mapPlace[@"displayLines"] isKindOfClass:[NSArray class]]) { // not exact but close enough
                        output.formattedAddressLineHints = mapPlace[@"displayLines"];
                    }

                    // structured address
                    output.addressHint = [GEOStructuredAddress alloc];
                    if (mapPlace[@"administrativeArea"]) { output.addressHint.administrativeArea = mapPlace[@"administrativeArea"]; }
                    if (mapPlace[@"subAdministrativeArea"]) { output.addressHint.subAdministrativeArea = mapPlace[@"subAdministrativeArea"]; }
                    if (mapPlace[@"locality"]) { output.addressHint.locality = mapPlace[@"locality"]; }
                    if (mapPlace[@"postCode"]) { output.addressHint.postCode = mapPlace[@"postCode"]; }
                    if (mapPlace[@"thoroughfare"]) { output.addressHint.thoroughfare = mapPlace[@"thoroughfare"]; }
                    if (mapPlace[@"subThoroughfare"]) { output.addressHint.subThoroughfare = mapPlace[@"subThoroughfare"]; }
                    if (mapPlace[@"fullThoroughfare"]) { output.addressHint.fullThoroughfare = mapPlace[@"fullThoroughfare"]; }

                    return nil;
                }
            }
            return [NSError errorWithDomain:@"maps place no exist :(" code:1 userInfo:nil];
        } else {
            return [NSError errorWithDomain:@"maps result either does not exist, or is blank" code:1 userInfo:nil];
        }
    }
    else
    {
        return [NSError errorWithDomain:@"decoded json was not a dictionary" code:1 userInfo:nil];
    }
}
@end