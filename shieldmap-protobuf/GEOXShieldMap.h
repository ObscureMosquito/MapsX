#import <Foundation/Foundation.h>
#import "../Protobufs.h"

// --- Map Message ---
@interface MapMessage : NSObject

@property (nonatomic, assign) uint64_t currentId;
@property (nonatomic, assign) uint64_t oldId;

- (BOOL)readFrom:(PBDataReader *)reader;
@end

// --- Ignore Message ---
@interface IgnoreMessage : NSObject

@property (nonatomic, assign) uint64_t id;

- (BOOL)readFrom:(PBDataReader *)reader;
@end

// --- Pack Message ---
@interface PackMessage : NSObject

@property (nonatomic, retain) NSString *info;
@property (nonatomic, assign) uint32_t version;
@property (nonatomic, retain) NSMutableArray *shields;
@property (nonatomic, retain) NSMutableArray *icons;
@property (nonatomic, retain) NSMutableArray *ignoreShields;
@property (nonatomic, retain) NSMutableArray *ignoreIcons;

- (BOOL)readFrom:(PBDataReader *)reader;
@end