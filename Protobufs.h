#import <Foundation/Foundation.h>

@interface PBDataWriter : NSObject
-(void)writeDouble:(double)value forTag:(unsigned short)tag ;
-(void)writeUint64:(unsigned long long)value forTag:(unsigned short)tag ;
-(void)writeSfixed32:(int)value forTag:(unsigned short)tag ;
-(void)writeInt64:(long long)value forTag:(unsigned short)tag ;
-(void)writeBigEndianFixed16:(unsigned short)value ;
-(void)writeUint8:(unsigned char)value ;
-(void)writeBigEndianFixed32:(unsigned)value ;
-(void)writeBigEndianShortThenString:(id)value ;
-(void)writeProtoBuffer:(id)value ;
-(void)writeInt8:(char)value ;
-(void)writeSint64:(long long)value forTag:(unsigned short)tag ;
-(void)writeFixed64:(unsigned long long)value forTag:(unsigned short)tag ;
-(void)writeSfixed64:(long long)value forTag:(unsigned short)tag ;
-(void)writeData:(id)value forTag:(unsigned short)tag ;
-(void)writeUint32:(unsigned)value forTag:(unsigned short)tag ;
-(void)writeTag:(unsigned short)value andType:(unsigned char)tag ;
-(void)writeBareVarint:(unsigned long long)value ;
-(void)writeString:(id)value forTag:(unsigned short)tag ;
-(void)writeBOOL:(char)value forTag:(unsigned short)tag ;
-(void)writeFixed32:(unsigned)value forTag:(unsigned short)tag ;
-(void)writeFloat:(float)value forTag:(unsigned short)tag ;
-(void)writeInt32:(int)value forTag:(unsigned short)tag ;
-(void)writeSint32:(int)value forTag:(unsigned short)tag ;
-(char)writeData:(id)value ;
-(id)data;
@end

@interface PBCodable : NSObject
{
}

- (id)dictionaryRepresentation;
- (void)writeTo:(id)arg1;
- (BOOL)readFrom:(id)arg1;
@property(readonly, nonatomic) NSData *data; // @dynamic data;
- (id)initWithData:(id)arg1;
- (id)init;

@end
@interface PBRequest : PBCodable
{
}

- (Class)responseClass;
- (unsigned int)requestTypeCode;

@end

// yolo, never used this lol
@interface PBDataReader : NSObject {

	unsigned _pos;
	char _error;
	const char* _bytes;
	NSData* _data;
	unsigned _length;
}
@property (assign) unsigned length;                //@synthesize length=_length - In the implementation block
@property (assign) unsigned position;              //@synthesize pos=_pos - In the implementation block
-(id)initWithData:(id)arg1 ;
-(void)setPosition:(unsigned)arg1 ;
-(unsigned)position;
-(unsigned)offset;
-(id)readString;
-(char)isAtEnd;
-(id)readBytes:(unsigned)arg1 ;
-(char)seekToOffset:(unsigned)arg1 ;
-(unsigned)readBigEndianFixed32;
-(unsigned short)readBigEndianFixed16;
-(void)updateData:(id)arg1 ;
-(unsigned long long)readBigEndianFixed64;
-(id)readProtoBuffer;
-(char)readInt8;
-(long long)readVarInt;
-(double)readDouble;
-(int)readInt32;
-(long long)readInt64;
-(int)readSint32;
-(long long)readSint64;
-(unsigned)readFixed32;
-(unsigned long long)readFixed64;
-(int)readSfixed32;
-(long long)readSfixed64;
-(char)readBOOL;
-(id)readData;
// -(char)mark:(SCD_Struct_PB0*)arg1 ;
// -(void)recall:(const SCD_Struct_PB0*)arg1 ;
-(id)readBigEndianShortThenString;
-(unsigned)length;
-(void)dealloc;
-(id)data;
-(void)setLength:(unsigned)arg1 ;
-(char)hasMoreData;
-(void)readTag:(unsigned short*)arg1 andType:(char*)arg2 ;
-(char)hasError;
-(unsigned long long)readUint64;
-(float)readFloat;
-(char)skipValueWithTag:(unsigned short)arg1 andType:(unsigned char)arg2 ;
-(unsigned)readUint32;
@end