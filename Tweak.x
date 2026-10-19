#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <execinfo.h>
#import <objc/message.h>
#include <stdint.h>

typedef struct GEOTileKey {
	unsigned z : 6;
	unsigned x : 26;
	unsigned y : 26;
	unsigned type : 6;
	unsigned pixelSize : 8;
	unsigned textScale : 8;
	unsigned provider : 8;
	unsigned expires : 1;
	unsigned reserved1 : 7;
	unsigned char reserved2[4];
} GEOTileKey;

// %hook PBCodable

// -(id)initWithData:(NSData*)data {
//         void *callstack[128];
// 	int frames = backtrace(callstack, 128);
// 	char **symbols = backtrace_symbols(callstack, frames);
// 	NSMutableString *callstackString = [NSMutableString stringWithFormat:@"[MapsX] Callstack for protocol buffer"];
// 	for (int i = 0; i < frames; i++) {
// 		[callstackString appendFormat:@"%s\n", symbols[i]];
// 	}
// 	NSLog(@"%@", callstackString);
	
// 	free(symbols);
//     return %orig;
// }


// %end
// %hook GEOResources
// -(void)addTileSet:(id)tileSet
// {
//     id betterTileSet = tileSet;
//     [betterTileSet setValue:@"http://google.com/lol/" forKey:@"_baseURL"];
//     NSLog(@"tileset baseurl -> %@", tileSet);
    
//     return %orig;
// }
// %end


// %hook GEOResourceManifestDownload 
// -(void)setResources:(id)resources
// {
//     NSLog(@"resourcers -> %@", resources);
//     %orig;
// }

// -(id)resources {
//     id orig = %orig;
//     NSLog(@"resources 2 -> %@", orig);
//     return orig;
// }
// %end




%hook GEOResourceLoader

-(id)initWithTileGroupIdentifier:(int)groupIdentifier uniqueIdentifier:(id)uniqueIdentifier targetDirectory:(id)targetDirectory baseURLString:(NSString*)baseURLString isFirstLoad:(BOOL)isFirstLoad {
    NSLog(@"[MapsX] Resource Loader URL: %@", baseURLString);
    return %orig;
}

%end

// %hook GEOResourceManifestManager

// -(id)baseURLStringForTileKey:(GEOTileKey*)tileKey {
//     id orig = %orig;
//     NSLog(@"ManifestManager: %@", orig);
//     return orig;
// }

// %end

%hook GEONameInfo 
-(NSString*)shield {
    id orig = %orig;
    NSLog(@"[MapsX] shield = %@", orig);
    return orig;
}
%end


%hook GEOVFeature
-(id)shieldLabelTypes {
    id orig = %orig;
    NSLog(@"[MapsX] shieldTypes = %@", orig);
    return orig;
}
%end

// void __cdecl -[GEOResourceManifestServerLocalProxy connectionDidFinishLoading:](
//         GEOResourceManifestServerLocalProxy *self,
//         SEL a2,
//         id a3)
// {
//   GEOResources *v5; // r0
//   GEOResources *v6; // r10
//   id v7; // r0
//   NSError *v8; // r5
//   int v9; // r0
//   NSError *v10; // r5
//   int v11; // r2
//   char **v12; // r0
//   GEODownloadMetadata *v13; // r0
//   GEODownloadMetadata *v14; // r5
//   NSString *v15; // r0
//   GEODownloadMetadata *v16; // r6
//   NSDate *v17; // r0
//   id v18; // r0
//   int v19; // r1
//   GEODownloadMetadata *v20; // r0
//   int v21; // r0
//   id v22; // r5
//   int v23; // r0
//   GEOResources *v24; // r0
//   GEOResources *v25; // r0
//   id v26; // r2

//   v5 = +[GEOResources alloc]();
//   v6 = -[GEOResources initWithData:](v5, self->_responseData);
//   if ( !(unsigned __int8)_isManifestValid(v6) )
//   {
//     v7 = -[GEOResourceManifestServerLocalProxy _manifestURL](self);
//     NSLog(
//       &cfstr_SDErrorParsing.isa,
//       "/SourceCache/GeoServices/GeoServices-457.9/GEOResourceManifestServerLocalProxy.m",
//       1020,
//       v7);
//     v8 = +[NSError alloc]();
//     v9 = GEOErrorDomain();
//     v10 = -[NSError initWithDomain:code:userInfo:](v8, v9, -602, 0);
//     -[GEOResourceManifestServerLocalProxy connection:didFailWithError:](self, a3, v10);
//     -[NSError release](v10);
//     -[GEOResources release](v6);
//     v12 = &selRef__cleanupConnection;
// LABEL_9:
//     objc_msgSend_shim(self, *v12, v11);
//     return;
//   }
//   self->_manifestRetryCount = 0;
//   v13 = +[GEODownloadMetadata alloc]();
//   v14 = -[GEODownloadMetadata init](v13);
//   -[GEOResourceManifestDownload setMetadata:](self->_resourceManifest, v14);
//   -[GEODownloadMetadata release](v14);
//   -[NSLock lock](self->_authTokenLock);
//   -[NSString release](self->_authToken);
//   v15 = -[GEOResources authToken](v6);
//   self->_authToken = -[NSString retain](v15);
//   -[NSLock unlock](self->_authTokenLock);
//   -[GEOResourceManifestDownload setResources:](self->_resourceManifest, v6);
//   -[GEOResources release](v6);
//   v16 = -[GEOResourceManifestDownload metadata](self->_resourceManifest);
//   v17 = +[NSDate date]();
//   v18 = -[NSDate timeIntervalSince1970](v17);
//   -[GEODownloadMetadata setTimestamp:](v16, v18, v19);
//   v20 = -[GEOResourceManifestDownload metadata](self->_resourceManifest);
//   -[GEODownloadMetadata setEtag:](v20, self->_responseETag);
//   -[GEOResourceManifestServerLocalProxy _writeManifestToDisk:](self, self->_resourceManifest);
//   -[GEOResourceManifestServerLocalProxy _cleanupConnection](self);
//   if ( dword_116E80 != -1 )
//     dispatch_once(&dword_116E80, &__block_literal_global690);
//   v21 = GEOGetDefaultInteger(CFSTR("GEOResourceManifestUpdateTimeInterval"), dword_116E7C);
//   -[GEOResourceManifestServerLocalProxy _scheduleUpdateTimerWithTimeInterval:](
//     self,
//     (double)v21);
//   v22 = -[GEOResourceManifestServerLocalProxy _manifestURL](self);
//   v23 = GEOGetDefault(CFSTR("GEOLastResourceManifestURL"));
//   if ( (unsigned __int8)objc_msgSend(v22, "isEqualToString:", v23) )
//   {
//     v12 = &selRef__considerChangingActiveTileGroup;
//     goto LABEL_9;
//   }
//   GEOSetDefault(CFSTR("GEOLastResourceManifestURL"), v22);
//   v24 = -[GEOResourceManifestDownload resources](self->_resourceManifest);
//   if ( -[GEOResources tileGroupsCount](v24) )
//   {
//     v25 = -[GEOResourceManifestDownload resources](self->_resourceManifest);
//     v26 = -[GEOResources tileGroupAtIndex:](v25, 0);
//     -[GEOResourceManifestServerLocalProxy _forceChangeActiveTileGroup:](self, v26);
//   }
// }



// %hook _GEOTileDownloadOp 


// -(void)setUrl:(NSURL*)url {
//     return %orig(addAccessKeyToURL(url));
// }
// %end

// %hook NSURLConnection

// - (instancetype)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
//     NSString *urlString = [[request URL] absoluteString];
    
//     NSLog(@"Original URL (initWithRequest:delegate:startImmediately:): %@", urlString);

//     void *callstack[128];
// 	int frames = backtrace(callstack, 128);
// 	char **symbols = backtrace_symbols(callstack, frames);
// 	NSMutableString *callstackString = [NSMutableString stringWithFormat:@"[MapsX] Callstack for url"];
// 	for (int i = 0; i < frames; i++) {
// 		[callstackString appendFormat:@"%s\n", symbols[i]];
// 	}
// 	NSLog(@"%@", callstackString);
	
// 	free(symbols);
//     return %orig;
// }

// %end




// %end

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
