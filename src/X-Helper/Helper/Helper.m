//
//  helper.m
//  helper
//
//  Created by lyq1996 on 2023/1/20.
//

#import "Helper.h"
#import "HelperConst.h"
#import "AppProtocol.h"
#import <IOKit/kext/KextManager.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>

extern DDLogLevel ddLogLevel;

@implementation Helper {
    NSXPCListener *listener;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

   // [TODO] The X-Monitor app has no signature, we have to find another way to verify the peer.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppProtocol)];
    
    // we don't need save connection, beacuse we don't need call to app exported interface

    newConnection.invalidationHandler = ^(){
        DDLogInfo(@"the connection is invalid");
    };

    newConnection.interruptionHandler = ^() {
        DDLogInfo(@"the connection is interrupt");
    };
    
    [newConnection resume];
    return YES;
}

- (void)run {
    [listener resume];
    dispatch_main();
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        listener = [[NSXPCListener alloc] initWithMachServiceName:@HELPER_DOMAIN];
        listener.delegate = self;
    }
    return self;
}

- (void)installKernelExtension:(NSURL *)kextURL kextID:(NSString *)identifier reply:(void (^)(int))block {

    DDLogInfo(@"trying to install kernel extension: %@", kextURL);

    // TODO check if the kext was already install
    NSString *dest = [NSString stringWithFormat:@"/tmp/%@", identifier];

    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error;
    if ([manager fileExistsAtPath:dest] && ![manager removeItemAtPath:dest error:&error]) {
        DDLogError(@"error remove exist kext %@", [error localizedDescription]);
        // TODO error code
        block(-1);
        return;
    }
    
    if (![manager copyItemAtURL:kextURL toURL:[NSURL fileURLWithPath:dest] error:&error]) {
        DDLogError(@"error copy kext to %@, %@", dest, [error localizedDescription]);
        // TODO error code
        block(-1);
        return;
    }
    
    NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"root",NSFileOwnerAccountName,
                              @"wheel",NSFileGroupOwnerAccountName,
                              nil];

    if (![manager setAttributes:attrib ofItemAtPath:dest error:&error]) {
        DDLogError(@"error settings permission %@", [error localizedDescription]);
        block(-1);
        return;;
    }

    NSDirectoryEnumerator *dirEnum = [manager enumeratorAtPath:dest];
    NSString *file;
    while (file = [dirEnum nextObject]) {
        if (![manager setAttributes:attrib ofItemAtPath:[dest stringByAppendingPathComponent:file] error:&error]) {
            DDLogError(@"error settings permission %@", [error localizedDescription]);
            block(-1);
            return;;
        }
    }
    
    OSReturn result = KextManagerLoadKextWithURL((__bridge CFURLRef)[NSURL URLWithString:dest], NULL);
    
    block(result);
}

@end
