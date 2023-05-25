//
//  HelperManager.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/18.
//

#import "HelperManager.h"
#import "HelperConst.h"
#import "HelperProtocol.h"
#import "AppProtocol.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

extern DDLogLevel ddLogLevel;

@implementation HelperManager {
    
}

/*
 @brief check whether helper tool is already install, and tool's versoin+build should equal to current X-Helper version+build.
 @return YES for should, NO for not should.
 */
BOOL shouldInstallerHelper(void) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@HELPER_PATH] &&
        [[NSFileManager defaultManager] fileExistsAtPath:@HELPER_PLIST]) {
        // check helper tool version from helper plist
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:@HELPER_PLIST];
        NSString *currentShortVer = [plist objectForKey:@"CFBundleShortVersionString"];
        NSString *currentBuildNum = [plist objectForKey:(NSString*)kCFBundleVersionKey];
        if (currentShortVer == nil || currentBuildNum == nil) {
            DDLogWarn(@"empty version or build number from helper plist");
            return YES;
        }

        DDLogDebug(@"check current version with bundle's version");
        NSString *bundle = [[[NSBundle mainBundle] resourcePath]stringByAppendingString:@"/X-Helper.app"];
        
        NSBundle *helperBundle = [NSBundle bundleWithPath:bundle];
        NSString *shortVer = [helperBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *buildNum = [helperBundle objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
        
        return !((currentShortVer == shortVer) && (currentBuildNum == buildNum));
    }
    
    DDLogDebug(@"no plist or no binary in destnation path");
    return YES;
}

/*
 @brief create connection to helper binary
 @return connection
 @note Receiving a non-nil result from this init method does not mean the service name is valid or the service has been launched. The init method simply constructs the local object.
 */
- (NSXPCConnection *)createConnection {
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@HELPER_DOMAIN options:NSXPCConnectionPrivileged];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppProtocol)];
    connection.exportedObject = self;

    [connection resume];
    return connection;
}

/*
 @brief get helper
 */
- (nullable id<HelperProtocol>)getHelper:(void (^)(NSError *))handle {
    if (shouldInstallerHelper()) {
        // call X-Helper application to install helper tool
        NSString *helperBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/X-Helper.app"];
        NSString *helperBin = [[NSBundle bundleWithPath:helperBundle] executablePath];
        NSTask *installTask = [[NSTask alloc] init];
        installTask.launchPath = helperBin;
        [installTask launch];
        [installTask waitUntilExit];
        int status = [installTask terminationStatus];

        if (status != 0) {
            DDLogError(@"install helper failed");
            return nil;
        }
        
        DDLogError(@"install helper success");
    }
    
    NSXPCConnection *connection = [self createConnection];
    
    // sync remote object proxy
    id<HelperProtocol> helper = [connection synchronousRemoteObjectProxyWithErrorHandler:handle];

    return helper;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        ;
    }
    return self;
}

@end
