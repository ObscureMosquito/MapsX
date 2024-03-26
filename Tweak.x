#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

%hook GEOResourceManifestServerLocalProxy

- (id)_manifestURL {
    id originalURL = %orig;
    NSLog(@"Original Manifest URL: %@", originalURL);

    NSString *newURLString = @"https://gspe21-ssl.ls.apple.com/config/prod-resources-hidpi-20";

    // Return the new URL
    return newURLString;
}

%end

%hook NSURLRequest

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    // Check if the URL host is "gspa19.ls.apple.com" and redirect to "gspe19-ssl.ls.apple.com"
    if ([[URL host] isEqualToString:@"gspa19.ls.apple.com"]) {
        NSString *newURLString = [[URL absoluteString] stringByReplacingOccurrencesOfString:@"gspa19.ls.apple.com" withString:@"gspe19-ssl.ls.apple.com"];
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return %orig(newURL, cachePolicy, timeoutInterval);
    }
    // Check if the URL host is "gspe21-ssl.ls.apple.com" and change the scheme to "http"
    else if ([[URL host] isEqualToString:@"gspe21-ssl.ls.apple.com"]) {
        NSString *newURLString = [[URL absoluteString] stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
        NSURL *newURL = [NSURL URLWithString:newURLString];
        return %orig(newURL, cachePolicy, timeoutInterval);
    }
    return %orig(URL, cachePolicy, timeoutInterval);
}

%end