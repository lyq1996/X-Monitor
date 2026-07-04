//
//  helper.m
//  helper
//
//  Created by lyq1996 on 2023/1/20.
//

#import "Helper.h"
#import "HelperConst.h"
#import "AppProtocol.h"
#import "SignatureVerifier.h"
#import <IOKit/kext/KextManager.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>
#import <libproc.h>

extern DDLogLevel ddLogLevel;

@implementation Helper {
    NSXPCListener *listener;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

    // Verify peer using custom signature
    pid_t remotePid = newConnection.processIdentifier;
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    if (proc_pidpath(remotePid, pathBuffer, sizeof(pathBuffer)) > 0) {
        NSString *peerPath = [NSString stringWithUTF8String:pathBuffer];
        DDLogInfo(@"verifying peer pid=%d path=%@", remotePid, peerPath);
        if (![SignatureVerifier verifyMachOAtPath:peerPath]) {
            DDLogError(@"deny process: %d, custom signature verification failed for path: %@", remotePid, peerPath);
            return NO;
        }
        DDLogInfo(@"peer pid=%d custom signature verified OK", remotePid);
    } else {
        DDLogError(@"deny process: %d, cannot get process path", remotePid);
        return NO;
    }

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
    newConnection.exportedObject = self;
    
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppProtocol)];

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

@end
