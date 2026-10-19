#import <Foundation/Foundation.h>


@interface GEOAttribution : NSObject {

	NSString* _badge;
	NSString* _logo;
	NSString* _name;
	NSString* _url;
}
@property (nonatomic,readonly) char hasBadge; 
@property (nonatomic,retain) NSString * badge;              //@synthesize badge=_badge - In the implementation block
@property (nonatomic,readonly) char hasLogo; 
@property (nonatomic,retain) NSString * logo;               //@synthesize logo=_logo - In the implementation block
@property (nonatomic,readonly) char hasName; 
@property (nonatomic,retain) NSString * name;               //@synthesize name=_name - In the implementation block
@property (nonatomic,readonly) char hasUrl; 
@property (nonatomic,retain) NSString * url;                //@synthesize url=_url - In the implementation block
-(id)dictionaryRepresentation;
-(NSString *)url;
-(void)setUrl:(NSString *)arg1 ;
-(char)hasBadge;
-(NSString *)badge;
-(char)hasLogo;
-(NSString *)logo;
-(char)hasUrl;
-(void)setBadge:(NSString *)arg1 ;
-(void)setLogo:(NSString *)arg1 ;
-(char)readFrom:(id)arg1 ;
-(void)dealloc;
-(char)isEqual:(id)arg1 ;
-(unsigned)hash;
-(id)description;
-(NSString *)name;
-(void)setName:(NSString *)arg1 ;
-(void)writeTo:(id)arg1 ;
-(void)copyTo:(id)arg1 ;
-(char)hasName;
@end


%hook GEOActiveTileGroup 
-(id)attributionAtIndex:(int)index {
    GEOAttribution *attribution = [[%c(GEOAttribution) alloc] init];
    [attribution setName:@"TomTom"];
    [attribution setLogo:@"tomtom-2@2x.png"];
    [attribution setUrl:@"https://gspe21-ssl.ls.apple.com/html/attribution.html"];// may change but ehhS
    return attribution;
}

-(id)attributions {
    GEOAttribution *attribution = [[%c(GEOAttribution) alloc] init];
    [attribution setName:@"TomTom"];
    [attribution setLogo:@"tomtom-2@2x.png"];
    [attribution setUrl:@"https://gspe21-ssl.ls.apple.com/html/attribution.html"];// may change but ehhS
    return [@[attribution] mutableCopy];
}

%end

%hook GEOResources

-(NSMutableArray*)attributions
{
    GEOAttribution *attribution = [[%c(GEOAttribution) alloc] init];
    [attribution setName:@"TomTom"];
    [attribution setLogo:@"tomtom-2@2x.png"];
    [attribution setUrl:@"https://gspe21-ssl.ls.apple.com/html/attribution.html"];// may change but ehhS
    return [@[attribution] mutableCopy];
}

%end

// extracted from ye ols 
// "2": "tomtom-2@2x.png",
// "3": "TomTom",
// "4": "https://gspe21-ssl.ls.apple.com/html/attribution-98.html"