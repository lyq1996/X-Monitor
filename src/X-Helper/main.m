//
//  main.m
//  X-Helper
//
//  Created by lyq1996 on 2023/1/20.
//

#import "HelperConst.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import <Cocoa/Cocoa.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
DDLogLevel ddlogLevel = DDLogLevelInfo;
#endif

/*
 @brief install helper tool into /Library/PrivilegedHelperTools/com.lyq1996.X-Monitor.helper
 @return YES for success, NO for failed.
 */
BOOL installHelper(void) {
    BOOL result = NO;
    NSError *error = nil;
    AuthorizationRef auth = NULL;
    
    // create pre authorization
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    if (status != errAuthorizationSuccess) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        DDLogError(@"unable to get a empty loading authorization to load helper! error: %@", error);
        return result;
    }
    
    AuthorizationItem authItem = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
                                kAuthorizationFlagInteractionAllowed |
                                kAuthorizationFlagPreAuthorize |
                                kAuthorizationFlagExtendRights;

    status = AuthorizationCopyRights(auth, &authRights, kAuthorizationEmptyEnvironment, flags, NULL);
    if (status != errAuthorizationSuccess) {
        DDLogError(@"unable to get a valid loading authorization to load helper!");
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    } else {
        CFErrorRef cfError;
        
        result = (BOOL)SMJobBless(kSMDomainSystemLaunchd, CFSTR(HELPER_DOMAIN), auth, &cfError);
        if (!result) {
            error = CFBridgingRelease(cfError);
        }
    }
    
    if (!result) {
        DDLogError(@"fail to bless for helper tool, error: %@", error);
    }
    
    AuthorizationFree(auth, kAuthorizationFlagDefaults);
    return result;
}

int main(int argc, const char * argv[]) {
    BOOL result;
    @autoreleasepool {
        result = installHelper();
        DDLogInfo(@"helper install result: %d", result);
    }
    
    if (result) {
        return 0;
    }
    return -1;
}
