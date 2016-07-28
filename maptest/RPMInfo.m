//
//  RPMInfo.m
//  maptest
//
//  Created by localhome on 27/07/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "RPMInfo.h"
#include <sys/stat.h>

@implementation RPMInfo

extern int errno;
- (id) init
{
    memset(&_lead,0,sizeof(struct rpmlead));
    return self;
}


- (id) initWithFile:(NSString *)filename error:(NSError **)error
{
    self = [super init];
    memset(&_lead,0,sizeof(struct rpmlead));
    memset(&_statinfo,0,sizeof(struct stat));
    _fd=-1;
    _map_buffer = NULL;
    
    const char *fn=[filename cStringUsingEncoding:NSUTF8StringEncoding];
    
    int r = stat(fn,&_statinfo);
    
    if(r==-1){
        if(error!=NULL){
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:r userInfo:nil];
        }
        return self;
    }
    
    _fd = open(fn,O_RDONLY);
    if(_fd==-1){
        if(error!=NULL){
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:r userInfo:nil];
        }
        return self;
    }
    
    _map_buffer = mmap(NULL,_statinfo.st_blocks*_statinfo.st_blksize,PROT_READ,MAP_PRIVATE,_fd,0);
    
    memcpy(&_lead,_map_buffer,sizeof(struct rpmlead));
    
    NSLog(@"RPM info initialised for %@",filename);
    return self;
}

- (RPMSignatureSection *) header
{
    return [[RPMSignatureSection alloc] initFromBuffer:_map_buffer offset:sizeof(struct rpmlead)];
}

- (RPMIndexChunk *) index
{
    RPMSignatureSection *s = [self header];
    NSUInteger offset = sizeof(struct rpmlead)+[s length];
    
    NSLog(@"main index offset is %lu",offset);
    return [[RPMIndexChunk alloc] initFromBuffer:_map_buffer offset:offset];
}

- (BOOL) close:(NSError **)error
{
    int r=-1;
    BOOL status=YES;
    if(_map_buffer!=NULL){
        r=munmap(_map_buffer, _statinfo.st_blocks*_statinfo.st_blksize);
        _map_buffer=NULL;
        if(r==-1){
            if(error!=NULL){
                *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:r userInfo:nil];
            }
            status=NO;
        }
    }
    if(_fd!=-1) close(_fd);
    _fd=-1;
    return status;
}

- (NSUInteger) majorVersion
{
    return _lead.major;
}
- (NSUInteger) minorVersion
{
    return _lead.minor;
}
- (NSUInteger) type
{
    return _lead.type;
}
- (NSUInteger) archnum
{
    return _lead.archnum;
}
- (NSString *) name
{
    return [[NSString alloc ] initWithBytes:_lead.name length:66 encoding:NSUTF8StringEncoding];
}

- (NSUInteger) osnum
{
    return _lead.osnum;
}
- (NSUInteger) signature_type
{
    return _lead.signature_type;
}

@end

@implementation RPMEntry

- (NSInteger) entrySize
{
    switch(_type){
        case RPM_T_NULL:
            return 0;
        case RPM_T_INT8:
            return 1;
        case RPM_T_INT16:
            return 2;
        case RPM_T_INT32:
            return 4;
        case RPM_T_INT64:
            return 8;
        case RPM_T_CHAR:
            return 1;
        case RPM_T_BIN:
            return 1;
        case RPM_T_STRING:
        case RPM_T_STRING_ARRAY:
            return -1;
    }
    return -1;
}

- (NSData *) findIndeterminateContent:(const char *)buffer
{
    //find the next NULL from the pointer buffer, and return an NSData
    NSUInteger n=0;
    for(n=0;n<NSUIntegerMax;++n){
        //NSLog(@"findIndeterminateContent: %d %c",n,buffer[n]);
        if(buffer[n]==0) break;
        ++n;
    }
    return [NSData dataWithBytes:buffer length:n];
}

- (NSArray *) findIndeterminateContentArray:(const char *)buffer count:(NSUInteger)count
{
    NSUInteger n=0;
    NSMutableArray *rtn=[NSMutableArray arrayWithCapacity:count];
    const char *ptr=buffer;
    
    for(n=0;n<count;++n){
        NSData *d=[self findIndeterminateContent:ptr];
        NSString *s=[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        if(s!=nil) [rtn addObject:s];
        ptr+=[d length];
    }
    return rtn;
}

- (id) initFromIndex:(struct hdr_index_entry *)index_entry store:(const char *)store
{
    NSLog(@"RPMEntry::initFromIndex");
    _tag=ntohl(index_entry->tag);
    _type=ntohl(index_entry->type);
    _offset=ntohl(index_entry->offset);
    _count=ntohl(index_entry->count);
    
    _content=nil;
    _content_array=nil;
    
    //NSLog(@"RPMEntry::initFromIndex: store offset is %ld from start of index",store-(const char *)index_entry);
    
    //NSLog(@"RPMEntry::initFromIndex: Got tag %ld, type 0x%lx at offset 0x%lx with count of %lu",(unsigned long)_tag,_type,_offset,_count);
    //NSLog(@"RPMEntry::initFromIndex: entry size is %ld", [self entrySize]);
    
    if([self entrySize]>0){
        //NSLog(@"normal allocation");
        _content = [NSData dataWithBytes:(const void *)&store[_offset] length:_count * [self entrySize]];
    } else {
        if(_type==RPM_T_STRING_ARRAY){
            _content_array = [self findIndeterminateContentArray:(const char *)&store[_offset] count:_count];
        } else {
            _content = [self findIndeterminateContent:(const char *)&store[_offset]];
        }
    }
    return self;
}

- (NSNumber *)numberValue
{
    const char tempc;
    const uint16 tempi;
    const uint32 templ;
    const uint64 templl;
    
    switch([self type]){
        case RPM_T_INT8:
        case RPM_T_CHAR:
            [_content getBytes:(void *)&tempc length:1];
            return [NSNumber numberWithChar:tempc];
        case RPM_T_INT16:
            [_content getBytes:(void *)&tempi length:2];
            return [NSNumber numberWithInt:ntohs(tempi)];
        case RPM_T_INT32:
            [_content getBytes:(void *)&templ length:4];
            return [NSNumber numberWithLong:ntohl(templ)];
        case RPM_T_INT64:
            [_content getBytes:(void *)&templl length:8];
            return [NSNumber numberWithLongLong:ntohll(templl)];
        default:
            break;
    }
    return nil;
}

- (NSString *)stringValue
{
    NSString *tmp=nil;
    const char temp;
    NSNumber *tempNumber;
    
    switch([self type]){
        case RPM_T_CHAR:
            [_content getBytes:(void *)&temp length:1];
            return [[NSString alloc] initWithFormat:@"%c",temp];
        case RPM_T_STRING:
            tmp = [[NSString alloc] initWithData:_content encoding:NSUTF8StringEncoding];
            return tmp;
        default: //if it's a number type, convert that into a string
            tempNumber = [self numberValue];
            if(tempNumber==nil) break;
            return [tempNumber stringValue];
    }
    return nil;
}

- (NSData *)binaryValue
{
    return [NSData dataWithData:_content];
}

- (NSArray *)arrayValues
{
    return [NSArray arrayWithArray:_content_array];
}

-(NSString*)hexRepresentationWithSpaces:(BOOL)spaces
{
    const unsigned char* bytes = (const unsigned char*)[_content bytes];
    NSUInteger nbBytes = [_content length];
    //If spaces is true, insert a space every this many input bytes (twice this many output characters).
    static const NSUInteger spaceEveryThisManyBytes = 4UL;
    //If spaces is true, insert a line-break instead of a space every this many spaces.
    static const NSUInteger lineBreakEveryThisManySpaces = 4UL;
    const NSUInteger lineBreakEveryThisManyBytes = spaceEveryThisManyBytes * lineBreakEveryThisManySpaces;
    NSUInteger strLen = 2*nbBytes + (spaces ? nbBytes/spaceEveryThisManyBytes : 0);
    
    NSMutableString* hex = [[NSMutableString alloc] initWithCapacity:strLen];
    for(NSUInteger i=0; i<nbBytes; ) {
        [hex appendFormat:@"%02X", bytes[i]];
        //We need to increment here so that the every-n-bytes computations are right.
        ++i;
        
        if (spaces) {
            if (i % lineBreakEveryThisManyBytes == 0) [hex appendString:@"\n"];
            else if (i % spaceEveryThisManyBytes == 0) [hex appendString:@" "];
        }
    }
    return hex;
}

@end
@implementation RPMIndexChunk

- (BOOL) checkMagic:(struct hdr_struct_header *)h
{
    if(h->magic[0]==0x8e && h->magic[1]==0xad && h->magic[2]==0xe8) return YES;
    return NO;
}

- (id)initFromBuffer:(const char *)buffer offset:(int)offset
{
    struct hdr_struct_header *head=(struct hdr_struct_header *)&buffer[offset];
    NSLog(@"header start is at offset %ld",(char *)head-buffer);
    NSLog(@"size of header struct is %ld",sizeof(struct hdr_struct_header));
    struct hdr_index_entry *index_start = (struct hdr_index_entry *)((char *)head + sizeof(struct hdr_struct_header));
    NSLog(@"index start is at offset %ld",(char *)index_start-buffer);
    
    _tags = [NSMutableDictionary dictionary];
    
    _index = (const char *)index_start;
    _store = (const char *)((const char *)index_start + (ntohl(head->entries)*sizeof(struct hdr_index_entry)));
    _length = ntohl(head->length)+(_store-(const char *)head)+4;
    
    if(! [self checkMagic:head]){
        NSLog(@"RPMIndexChunk::initFromBuffer: ERROR: magic number check failed");
        return self;
    }
    
    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:ntohl(head->entries)];
    
    /*    unsigned char magic[3];
     uint8 version;
     char reserved[4];
     uint32 entries;
     uint32 length;*/
    
    NSLog(@"RPMIndexChunk::initFromBuffer: got index chunk of version %d, with %u entries and a length of %u bytes",
          head->version,
          ntohl(head->entries),
          ntohl(head->length));
    
    struct hdr_index_entry *index_ptr=index_start;
    
    NSLog(@"Store is at offset %ld",(char *)_store - buffer);
    for(int n=0;n<ntohl(head->entries);++n){
        RPMEntry *e=[[RPMEntry alloc] initFromIndex:index_ptr store:_store];
        if(e!=nil) [entries addObject:e];
        NSString *tagname = [NSString stringWithFormat:@"%ld",[e tag]];
        [_tags setValue:e forKey:tagname];
        NSLog(@"%lu: %@",[e tag],[e stringValue]);
        index_ptr += 1;
    }
    [self setEntries:entries];
    return self;
}

- (RPMEntry *) entryForTag:(NSUInteger)tag
{
    return [_tags valueForKey:[NSString stringWithFormat:@"%ld",tag]];
}

@end

@implementation RPMSignatureSection
- (NSUInteger) size
{
    RPMEntry *data=[self entryForTag:SIGTAG_SIZE];
    NSNumber *n=[data numberValue];
    return [n integerValue];
}

- (NSData *)md5
{
    RPMEntry *data=[self entryForTag:SIGTAG_MD5];
    return [data content];
}

- (NSData *)gpg
{
    RPMEntry *data=[self entryForTag:SIGTAG_GPG];
    return [data content];
}
- (NSUInteger) payloadSize
{
    RPMEntry *data=[self entryForTag:SIGTAG_PAYLOADSIZE];
    NSNumber *n=[data numberValue];
    return [n integerValue];
}

- (NSData *) sha1;
{
    RPMEntry *data=[self entryForTag:SIGTAG_SHA1];
    return [data content];
}

@end
