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
    NSError *e=nil;
    
    RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/pluto-3.0-201607251331.rpm" error:&e];
    //RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/rpm-4.8.0-55.el6.src.rpm" error:&e];
    //RPMInfo *rpm = [[RPMInfo alloc] initWithFile:@"/Users/localhome/Downloads/RedHat_Portal_2.0.4/resources/vidispine/xerces-c-3.0.1-20.el6.x86_64.rpm" error:&e];
    
    NSLog(@"Name is %@",[rpm name]);
    NSLog(@"RPM archive version is %d.%d",[rpm majorVersion],[rpm minorVersion]);
    
    RPMSignatureSection *header_section = [rpm header];
    NSLog(@"header at 0x%lx",(unsigned long)header_section);
    
    NSLog(@"Got RPM with size %ld and payload size %ld",[header_section size], [header_section payloadSize]);
    
    
    RPMIndexChunk *index = [rpm index];
    
    NSMutableArray *infoarray = [NSMutableArray array];
    
    RPMEntry *entry=[index entryForTag:TAG_NAME];
    NSLog(@"Name: %@",[entry stringValue]);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry stringValue], @"value", @"Name", @"key", nil]];
    
    entry=[index entryForTag:TAG_ARCH];
    NSLog(@"Architecture: %@",[entry stringValue]);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry stringValue], @"value", @"Architecture", @"key", nil]];
    
    entry=[index entryForTag:TAG_RELEASE];
    NSLog(@"Release: %@",[entry stringValue]);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry stringValue], @"value", @"Release", @"key", nil]];
    
    entry=[index entryForTag:TAG_VERSION];
    NSLog(@"Version: %@",[entry stringValue]);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry stringValue], @"value", @"Version", @"key", nil]];
    
    entry=[index entryForTag:TAG_NOPATCH];
    NSLog(@"Nopatch: %@",[entry stringValue]);
    entry=[index entryForTag:TAG_BUILDTIME];
    NSDate *bt=[[NSDate alloc] initWithTimeIntervalSince1970:[[entry numberValue] doubleValue]];
    NSLog(@"Build time: %@",bt);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:bt, @"value", @"Build time", @"key", nil]];
    
    entry=[index entryForTag:TAG_CATEGORY];
    NSLog(@"Category: %@",[entry stringValue]);
    [infoarray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entry stringValue], @"value", @"Category", @"key", nil]];
   
    
    [self setRpminfo:infoarray];
    
    [rpm close:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
