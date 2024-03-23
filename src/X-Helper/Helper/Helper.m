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
