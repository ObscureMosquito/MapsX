#import <Foundation/Foundation.h>

%hook GEOResourceManager

-(NSData *)dataForResourceWithName:(NSString *)name fallbackBundle:(NSBundle *)bundle {
    NSData *data = %orig(name, bundle);
    if ([name isEqualToString:@"altitude.xml"] && [data isKindOfClass:[NSData class]]) {
        NSString *xml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (xml) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<trigger region=\"(25[6-9]|2[6-9][0-9]|[3-9][0-9]{2}|[0-9]{4,})\"[^>]*></trigger>" options:0 error:nil];
            NSString *patched = [xml stringByReplacingOccurrencesOfString:@"key=\"USE_APPLE_DG\" value=\"dtm\"" withString:@"key=\"USE_APPLE_DG\" value=\"true\""];
            patched = [regex stringByReplacingMatchesInString:patched options:0 range:NSMakeRange(0, [patched length]) withTemplate:@""];
            return [patched dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return data;
}

%end