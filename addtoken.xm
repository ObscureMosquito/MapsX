#include <Foundation/Foundation.h>
#import "GEOTokenManager.h"
#import "GEOQueryToLatLng.h"
#import <execinfo.h>
#import <objc/message.h>
#import <CommonCrypto/CommonCrypto.h>

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

typedef struct SessionID {
	unsigned long long var0;
	unsigned long long var1;
} SessionID;


@interface GEOResourceManifestManager : NSObject

+(GEOResourceManifestManager*)sharedManager;
-(NSString*)authToken;

@end

@interface GEOUserSession : NSObject

+(GEOUserSession*)sharedInstance;
-(SessionID)sessionID;

@end

@interface NSMutableData (MapsX)
-(NSString*)base64Encoding;
@end

static NSString *generateTokenP3() {
    NSString *chars = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *result = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        [result appendFormat:@"%c", [chars characterAtIndex:arc4random_uniform((uint32_t)chars.length)]];
    }
    return result;
}


%hookf(NSURL *, GEOURLAuthenticationGenerateURL, NSURL *url, NSString *tk) {
    // NSLog(@"tk -> %@, url -> %@", tk, url);

    // GEOResourceManifestManager *v3; // r0
    // GEOUserSession *v4; // r1
    // NSString *sid; // r11 MAPDST
    // NSString *originalURL; // r6 MAPDST
    // __CFString *seperator; // r1
    // NSString *newURLStr; // r0
    // NSURL *newURL; // r5
    // GEOCountryConfiguration *v12; // r0
    // id urlTTL; // r0
    // __int64 jankTTL; // d8
    // int v15; // r1
    // id encryptionKey; // r4
    // CFAbsoluteTime CurrentTime; // r0
    // NSString *authToken; // [sp+14h] [bp-3Ch]
    // int v21; // [sp+18h] [bp-38h] BYREF
    // int v22; // [sp+1Ch] [bp-34h]
    // SessionID v23; // [sp+20h] [bp-30h] BYREF
    NSString *p3 = generateTokenP3();
    NSString *authToken = [[%c(GEOResourceManifestManager) sharedManager] authToken];
    if ( authToken )
    {
        // GEOUserSession *userSession = [%c(GEOUserSession) sharedInstance];
        NSString *sid = @"6942069420694206942069420694206942067676";
        // if (userSession)
        // {
            
        //     SessionID sessionID = [userSession sessionID];
        //     sid = [NSString stringWithFormat:@"69%llu%llu", sessionID.var0, sessionID.var1];
        // }
        // else
        // {
        //     // memset(&v23, 0, sizeof(v23));
        //     sid = [NSString stringWithFormat:@"69%llu%llu", 0llu, 0llu];
        // }

        NSString *token = [NSString stringWithFormat:@"4cjLaD4jGRwlQ9U%@%@", authToken, p3];
        long long timestamp = (long long)[[NSDate date] timeIntervalSince1970] + 4200;

        NSString *originalURL = [url absoluteString];



        NSString *seperator = @"?";
        if ([originalURL rangeOfString:@"?"].location != NSNotFound) {
            seperator = @"&";
        }


        NSData *hashData = [token dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(hashData.bytes, (CC_LONG)hashData.length, digest);        
        NSData *key = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];

        NSString *query = [url query] ?: @"";
        NSString *plaintext = [NSString stringWithFormat:@"%@?%@%@sid=%@%lld%@", [url path], query, query.length > 0 ? @"&" : @"", sid, timestamp, p3];

        NSData *plaintextData = [plaintext dataUsingEncoding:NSUTF8StringEncoding];

        NSUInteger blockSize = 16;
        NSUInteger padding = blockSize - (plaintextData.length % blockSize);
        NSMutableData *padded = [plaintextData mutableCopy];
        for (NSUInteger i = 0; i < padding; i++) {
            uint8_t byte = (uint8_t)padding;
            [padded appendBytes:&byte length:1];
        }

        NSMutableData *ciphertext = [NSMutableData dataWithLength:padded.length];
        uint8_t iv[16] = {0};
        size_t bytesEncrypted = 0;
        CCCryptorStatus status = CCCrypt(
            kCCEncrypt,
            kCCAlgorithmAES,
            0,
            key.bytes, key.length,
            iv,
            padded.bytes, padded.length,
            ciphertext.mutableBytes, ciphertext.length,
            &bytesEncrypted);

        if (status != kCCSuccess) {
            NSLog(@"[MapsX] CCCrypt failed: %d", status);
            return url;
        }
        ciphertext.length = bytesEncrypted;

        NSString *b64 = [ciphertext base64Encoding];

        NSString *encoded = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
            NULL,
            (CFStringRef)b64,
            NULL,
            CFSTR("!*'();:@&=+$,/?#[]"),
            kCFStringEncodingUTF8));

        NSString *accessKey = [NSString stringWithFormat:@"%lld_%@_%@", timestamp, p3, encoded];
        NSString *newURLString = [NSString stringWithFormat:@"%@%@sid=%@&accessKey=%@", originalURL, seperator, sid, accessKey];
        return [NSURL URLWithString:newURLString];
    }
    return url;
    //     originalURL = -[NSURL absoluteString](url);
    //     if ( originalURL )
    //     {
    //     objc_msgSend_stret(&v21, (SEL)originalURL, "rangeOfString:", CFSTR("?"));
    //     seperator = CFSTR("&");
    //     if ( !v22 )
    //         seperator = CFSTR("?");
    //     }
    //     else
    //     {
    //     v22 = 0;
    //     seperator = CFSTR("?");
    //     v21 = 0;
    //     }
    //     newURLStr = +[NSString stringWithFormat:](
    //                 CFSTR("%@%@sid=%@&tk=%@"),
    //                 originalURL,
    //                 seperator,
    //                 sid,
    //                 tk);
    //     newURL = +[NSURL URLWithString:](newURLStr);
    //     v12 = +[GEOCountryConfiguration sharedConfiguration]();
    //     urlTTL = -[GEOCountryConfiguration defaultForKey:defaultValue:](
    //             v12,
    //             CFSTR("GEOURLAuthenticationTTL"),
    //             0);
    //     if ( urlTTL )
    //     {
    //     LODWORD(jankTTL) = objc_msgSend(urlTTL, "doubleValue");
    //     HIDWORD(jankTTL) = v15;
    //     }
    //     else
    //     {
    //     jankTTL = 0x40B0680000000000LL;
    //     }
    //     encryptionKey = [@"" stringByAppendingString:authToken];
    //     CurrentTime = CFAbsoluteTimeGetCurrent();
    //     return (NSURL *)_GEOURLAuthenticationGenerateURL(
    //                     newURL,
    //                     LODWORD(CurrentTime),
    //                     HIDWORD(CurrentTime),
    //                     jankTTL,
    //                     (NSString *)HIDWORD(jankTTL),
    //                     encryptionKey,
    //                     nullptr);
    // }
    // return url;





    //         void *callstack[128];
	// int frames = backtrace(callstack, 128);
	// char **symbols = backtrace_symbols(callstack, frames);
	// NSMutableString *callstackString = [NSMutableString stringWithFormat:@"[MapsX] Callstack for auth gen url"];
	// for (int i = 0; i < frames; i++) {
	// 	[callstackString appendFormat:@"%s\n", symbols[i]];
	// }
	// NSLog(@"%@", callstackString);
	
	// free(symbols);

    // technically we don't *need* to do the original result, but it makes the logic *slightly* simpler
    // NSURL *originalResult = %orig(url, tk);

    // NSString *token = [[GEOTokenManager sharedManager] currentAccessKey];
    // NSString *urlString = [originalResult absoluteString];
    // if (token == nil) {
    //     return originalResult;
    // }

    // // unless original result fails, this should always already have a query param.
    // urlString = [NSString stringWithFormat:@"%@&accessKey=%@", originalResult, customURLEncode(token)];
    // // NSLog(@"url string -> %@", urlString);
    // return [NSURL URLWithString:urlString];
}

%ctor {
  %init(GEOURLAuthenticationGenerateURL=MSFindSymbol(NULL, "_GEOURLAuthenticationGenerateURL"));
}