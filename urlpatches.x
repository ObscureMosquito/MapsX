#import <Foundation/Foundation.h>

%group EnableURLPatches
%hook GEOResourceManifestServerLocalProxy

- (id)_manifestURL {
    id originalURL = %orig;
    NSLog(@"[MapsX] Original Manifest URL: %@", originalURL);

    NSString *newURLString = @"http://gspe21-ssl.ls.apple.com/config/prod-resources-hidpi-20";

    // Return the new URL
    return newURLString;
}

%end


// %hook GEOActiveTileGroup
// baseURLStringForTileKey:

// %end
// -[GEOActiveTileGroup ]

NSString *URLPatches(NSString *baseURL) {
    if ([@"http://gspa19.ls.apple.com/tile.vf" isEqualToString:baseURL]) { // reqular
        return @"http://gspe19.ls.apple.com/tile.vf";
    } else if ([@"http://gspa19.ls.apple.com/tile.vf?flags=4" isEqualToString:baseURL]) { // reqular with flag 4 (driving)
        return @"http://gspe19.ls.apple.com/tile.vf?flags=4";
    } else if ([@"http://gspa12.ls.apple.com/traffic" isEqualToString:baseURL]) { // traffic
        return @"http://gspe12.ls.apple.com/traffic";
    } else if ([@"http://gspa11.ls.apple.com/tile" isEqualToString:baseURL]) { // sat
        return @"http://gspe11.ls.apple.com/tile";
    }
    return baseURL;
}

%hook GEOActiveTileSet
-(NSString*)baseURL {
    NSString *baseURL = %orig;
    return URLPatches(baseURL);
}

-(NSString*)localizationURL {
    NSString *baseURL = %orig;
    return URLPatches(baseURL);
}

// cool feature, seems to be borked
// -(NSString*)multiTileURL {
//     NSLog(@"multitile -> %@", %orig);
//     // return %orig;
//     return @"http://gspe19-ssl.ls.apple.com/tile.vf";
// }

%end

%hook GEOResources

-(id)resourcesURL {
    // NSLog(@"resourcesURL -> %@", %orig); // originally https://gspe21-ssl.ls.apple.com/
    return @"http://gspe21-ssl.ls.apple.com/";
}


%end
%end


%ctor {
	if (kCFCoreFoundationVersionNumber <= 847.27) {
		%init(EnableURLPatches);
	}
}