#import "GEOXShieldMap.h"
#include <Foundation/Foundation.h>

@implementation MapMessage
- (BOOL)readFrom:(PBDataReader *)reader {
    while ([reader hasMoreData] && ![reader hasError]) {
        uint32_t fullTag = [reader readUint32];
        uint32_t tag = fullTag >> 3;
        
        switch (tag) {
            case 1: 
                self.currentId = [reader readUint64]; 
                break;
            case 2: 
                self.oldId = [reader readUint64]; 
                break;
            default:
                break;
        }
    }
    return ![reader hasError];
}
@end

@implementation IgnoreMessage
- (BOOL)readFrom:(PBDataReader *)reader {
    while ([reader hasMoreData] && ![reader hasError]) {
        uint32_t fullTag = [reader readUint32];
        uint32_t tag = fullTag >> 3;
        
        switch (tag) {
            case 1: 
                self.id = [reader readUint64]; 
                break;
            default: 
                break;
        }
    }
    return ![reader hasError];
}
@end

@implementation PackMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        _shields = [[NSMutableArray alloc] init];
        _icons = [[NSMutableArray alloc] init];
        _ignoreShields = [[NSMutableArray alloc] init];
        _ignoreIcons = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)readFrom:(PBDataReader *)reader {
    while ([reader hasMoreData] && ![reader hasError]) {        
        uint32_t fullTag = [reader readUint32];
        uint32_t wireType = fullTag & 7;
        uint32_t tag = fullTag >> 3;
        
        switch (tag) {
            case 1:
                self.info = [reader readString];
                break;
                
            case 2:
                self.version = [reader readUint32];
                break;
                
            case 3: { // repeated MapMessage shields = 3;
                if (wireType == 2) {
                    // readData automatically parses the Varint length, captures that exact slice,
                    // and perfectly advances the main reader cursor past it.
                    NSData *subData = [reader readData];
                    if (subData) {
                        PBDataReader *subReader = [[PBDataReader alloc] initWithData:subData];
                        MapMessage *msg = [[MapMessage alloc] init];
                        
                        [msg readFrom:subReader];
                        [self.shields addObject:msg];
                        // ARC automatically releases msg and subReader here cleanly!
                    }
                }
                break;
            }
                
            case 4: { // repeated MapMessage icons = 4;
                if (wireType == 2) {
                    NSData *subData = [reader readData];
                    if (subData) {
                        PBDataReader *subReader = [[PBDataReader alloc] initWithData:subData];
                        MapMessage *msg = [[MapMessage alloc] init];
                        [msg readFrom:subReader];
                        [self.icons addObject:msg];
                    }
                }
                break;
            }
                
            case 5: { // repeated IgnoreMessage ignoreShields = 5;
                if (wireType == 2) {
                    NSData *subData = [reader readData];
                    if (subData) {
                        PBDataReader *subReader = [[PBDataReader alloc] initWithData:subData];
                        IgnoreMessage *msg = [[IgnoreMessage alloc] init];
                        [msg readFrom:subReader];
                        [self.ignoreShields addObject:msg];
                    }
                }
                break;
            }
                
            case 6: { // repeated IgnoreMessage ignoreIcons = 6;
                if (wireType == 2) {
                    NSData *subData = [reader readData];
                    if (subData) {
                        PBDataReader *subReader = [[PBDataReader alloc] initWithData:subData];
                        IgnoreMessage *msg = [[IgnoreMessage alloc] init];
                        [msg readFrom:subReader];
                        [self.ignoreIcons addObject:msg];
                    }
                }
                break;
            }
                
            default:
                break;
        }
    }
    return ![reader hasError];
}

@end