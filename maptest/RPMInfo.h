//
//  RPMInfo.h
//  maptest
//
//  Created by localhome on 27/07/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/stat.h>

struct rpmlead {
    unsigned char magic[4];
    unsigned char major, minor;
    short type;
    short archnum;
    char name[66];
    short osnum;
    short signature_type;
    char reserved[16];
} ;

#define RPM_T_NULL 0
#define RPM_T_CHAR 1
#define RPM_T_INT8 2
#define RPM_T_INT16 3
#define RPM_T_INT32 4
#define RPM_T_INT64 5
#define RPM_T_STRING 6
#define RPM_T_BIN 7
#define RPM_T_STRING_ARRAY 8


//from RPM sources
#define TAG_NAME        1000
#define TAG_VERSION     1001
#define TAG_RELEASE     1002
#define TAG_EPOCH       1003
#define TAG_DESCRIPTION 1005
#define TAG_BUILDTIME   1006
#define TAG_BUILDHOST   1007

#define TAG_LICENSE     1014
#define TAG_PACKAGER    1015
#define TAG_CATEGORY    1016
#define TAG_WEBSITE     1020
#define TAG_BUILDOS     1021
#define TAG_INSTALLSCRIPT   1024

#define TAG_ARCH        1022
#define TAG_FILENAMES   1027
#define TAG_FILESIZES   1028
#define TAG_FILEMODES   1030
#define TAG_FILERDEVS   1033
#define TAG_FILEMTIMES  1034
#define TAG_FILEMD5S    1035
#define TAG_FILELINKTOS 1036
#define TAG_FILEFLAGS   1037
#define TAG_SOURCERPM   1044
#define TAG_FILEVERIFY  1045
#define TAG_NOSOURCE    1051
#define TAG_NOPATCH     1052
#define TAG_DIRINDEXES  1116
#define TAG_BASENAMES   1117
#define TAG_DIRNAMES    1118
#define TAG_compilation  1122
#define TAG_PAYLOADFORMAT 1124
#define TAG_PAYLOADCOMPRESSOR 1125
#define TAG_PAYLOADFLAGS 1126
#define TAG_FILECOLORS  1140
#define TAG_FILEDIGESTALGO 5011

#define SIGTAG_SIZE     1000
#define SIGTAG_MD5      1004
#define SIGTAG_GPG      1005
#define SIGTAG_PAYLOADSIZE 1007
#define SIGTAG_SHA1 269

struct hdr_struct_header {
    unsigned char magic[3];
    uint8 version;
    char reserved[4];
    uint32 entries;
    uint32 length;
};

struct hdr_index_entry {
    uint32 tag;
    uint32 type; //an RPM_T, above
    uint32 offset;
    uint32 count; //this is always 1 for STRING, and >=1 for RPM_T_STRING_ARRAY
};

@interface RPMEntry : NSObject
@property NSUInteger tag;
@property NSUInteger type;
@property NSUInteger offset;
@property NSUInteger count;
@property NSData *content;
@property NSArray *content_array;

//- (BOOL) boolValue;
//- (uint8) smallIntValue;
//- (uint16) intValue;
//- (uint32) longValue;
//- (uint64) longLongValue;
- (NSNumber *)numberValue;
- (NSString *)stringValue;
- (NSData *)binaryValue;
- (NSArray *)arrayValues;
@end

@interface RPMIndexChunk : NSObject
{
    const char *_index,*_store;
    NSMutableDictionary *_tags;
}
@property NSArray *entries;
@property NSUInteger length;

- (id)initFromBuffer:(const char *)buffer offset:(int)offset;
- (BOOL) checkMagic:(struct hdr_struct_header *)h;

- (RPMEntry *) entryForTag:(NSUInteger)tag;
@end

@interface RPMSignatureSection: RPMIndexChunk

- (NSUInteger) size;
- (NSData *)md5;
- (NSData *)gpg;
- (NSUInteger) payloadSize;
- (NSData *) sha1;

@end

@interface RPMInfo : NSObject
{
    //private properties
    int _fd;
    char *_map_buffer;
    struct stat _statinfo;
    struct rpmlead _lead;
}
@property (atomic) BOOL did_error;

- (id) initWithFile:(NSString *)filename error:(NSError **)error;
- (RPMSignatureSection *) header;
- (RPMIndexChunk *) index;

/*
 unsigned char magic[4];
 unsigned char major, minor;
 short type;
 short archnum;
 char name[66];
 short osnum;
 short signature_type;
 char reserved[16];
 */
- (NSUInteger) majorVersion;
- (NSUInteger) minorVersion;
- (NSUInteger) type;
- (NSUInteger) archnum;
- (NSString *) name;
- (NSUInteger) osnum;
- (NSUInteger) signature_type;
@end



