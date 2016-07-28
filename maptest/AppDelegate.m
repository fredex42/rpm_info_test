//
//  AppDelegate.m
//  maptest
//
//  Created by localhome on 27/07/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"
#import "RPMInfo.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
extern int errno;



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    // Insert code here to initialize your application
//    int fd;
//    char *buffer;
//    
//    fd = open("/Users/localhome/Downloads/pluto-3.0-201607251331.rpm",O_RDONLY);
//    buffer = mmap(NULL,7*1024*1024,PROT_READ,MAP_PRIVATE,fd,0);
//    if(!buffer){
//        NSLog(@"error: unable to map file: %d",errno);
//    }
//    
//    struct rpmlead *lead=(struct rpmlead *)malloc(sizeof(struct rpmlead));
//    memcpy(lead,buffer,sizeof(struct rpmlead));
//    NSLog(@"%x",lead->magic[0]);
//    NSLog(@"Major version: %d, minor: %d",lead->major,lead->minor);
//    NSLog(@"%s",lead->name);
//    
//    free(lead);
//    NSLog(@"test");
    NSError *e=nil;
    
    RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/pluto-3.0-201607251331.rpm" error:&e];
    //RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/rpm-4.8.0-55.el6.src.rpm" error:&e];
    //RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/RedHat_Portal_2.0.4/resources/vidispine/xerces-c-3.0.1-20.el6.x86_64.rpm" error:&e];
    
    NSLog(@"Name is %@",[rpm name]);
    NSLog(@"RPM archive version is %d.%d",[rpm majorVersion],[rpm minorVersion]);
    
    RPMSignatureSection *header_section = [rpm header];
    NSLog(@"header at 0x%lx",(unsigned long)header_section);
    
//    for(RPMEntry *e in [header_section entries]){
//        NSLog(@"Got an entry for tag %ld of type %ld with value of %@",[e tag],[e type],[e stringValue]);
//    }
    NSLog(@"Got RPM with size %ld and payload size %ld",[header_section size], [header_section payloadSize]);
    
    
    RPMIndexChunk *index = [rpm index];
    
    RPMEntry *entry=[index entryForTag:TAG_NAME];
    NSLog(@"Name: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_EPOCH];
    NSLog(@"Build time: %@",[entry content]);
    
    entry=[index entryForTag:TAG_ARCH];
    NSLog(@"Architecture: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_RELEASE];
    NSLog(@"Release: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_VERSION];
    NSLog(@"Version: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_NOPATCH];
    NSLog(@"Nopatch: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_BUILDTIME];
    NSLog(@"Build time: %@",[[NSDate alloc] initWithTimeIntervalSince1970:[[entry numberValue] doubleValue]]);
    
    entry=[index entryForTag:TAG_CATEGORY];
    NSLog(@"Category: %@",[entry stringValue]);
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
