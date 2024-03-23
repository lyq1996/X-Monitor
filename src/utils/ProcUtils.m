//
//  ProcUtils.m
//  X-Service
//
//  Created by lyq1996 on 2023/5/11.
//

#import "ProcUtils.h"
#import <libproc.h>
#import <sys/sysctl.h>
#import <time.h>

@implementation ProcUtils

+ (NSNumber *)getSystemBootTime {
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boottime, &len, NULL, 0) == 0) {
        return @(boottime.tv_sec);
    }
    return @(-1);
}

+ (NSNumber *)getParentPidFromPid:(NSNumber *)pid {
    pid_t c_pid = [pid intValue];

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, c_pid};
    struct kinfo_proc info;
    size_t size = sizeof(info);

    if (sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0) == -1) {
        return @(-1);
    }

    return @(info.kp_eproc.e_ppid);
}

+ (NSString *)getPathFromPid:(NSNumber *)pid {
    pid_t c_pid = [pid intValue];
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    if (proc_pidpath(c_pid, pathBuffer, sizeof(pathBuffer)) <= 0) {
        return @"";
    }
    return [NSString stringWithUTF8String:pathBuffer];
}

+ (NSNumber *)getCreatetimeFromPid:(NSNumber *)pid {
    pid_t c_pid = [pid intValue];
    struct proc_bsdinfo info;
    if (proc_pidinfo(c_pid, PROC_PIDTBSDINFO, 0, &info, sizeof(info)) <= 0) {
        return @-1;
    }
    return @(info.pbi_start_tvsec);
}

+ (NSString *)getCmdlineFromPid:(NSNumber *)pid {
    int numArgs = 0;
    size_t argMax = 0;
    char *buffer = NULL;
    char *argBegin = NULL;
    char *argEnd = NULL;
    
    // Get the maximum size of the process arguments buffer
    int mib[2] = {CTL_KERN, KERN_ARGMAX};
    size_t size = sizeof(argMax);
    if (sysctl(mib, 2, &argMax, &size, NULL, 0) != 0 || argMax == 0) {
        return @"";
    }
    
    // Allocate memory for the process arguments buffer
    buffer = calloc(1, argMax);
    if (buffer == NULL) {
        return @"";
    }
    
    // Get the process arguments
    int mibs[3] = {CTL_KERN, KERN_PROCARGS2, [pid intValue]};
    if (sysctl(mibs, 3, buffer, &argMax, NULL, 0) < 0) {
        free(buffer);
        buffer = NULL;
        return @"";
    }
    
    memcpy(&numArgs, buffer, sizeof(int));
    argEnd = &buffer[argMax];
    argBegin = buffer + sizeof(int);
    argBegin += strlen(argBegin) + 1;
    
    // skip unuse arg
    do {
        if (*argBegin != '\0') {
            break;
        }
    } while (++argBegin < argEnd);
    
    // no process args
    if (argBegin == argEnd) {
        free(buffer);
        buffer = NULL;
        return @"";
    }
    
    // Parse the process arguments
    char *currArg = argBegin;
    char *lastArg = argBegin;
    while (currArg < argEnd && numArgs > 0) {
        if (*currArg == '\0') {
            if (lastArg != NULL && lastArg != argBegin) {
                *lastArg = ' ';
            }
            lastArg = currArg;
            numArgs--;
        }
        currArg++;
    }
    
    // Construct the command line string
    NSString *cmdline = [NSString stringWithUTF8String:argBegin];
    
    // Free memory and return result
    free(buffer);
    buffer = NULL;
    return cmdline ? cmdline: @"";
}


+ (nullable NSDictionary *)getCodeSigningFromPid:(NSString *)path {
    if ([path isEqualToString:@""]) {
        return nil;
    }
    
    // create SecStaticCodeRef object
    SecStaticCodeRef staticCodeRef;
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)[NSURL URLWithString:path], kSecCSDefaultFlags, &staticCodeRef);
    if (status != errSecSuccess) {
        NSLog(@"Failed to create static code object with error code: %d", (int)status);
        return nil;
    }

    // get signing info
    CFDictionaryRef signingInformation;
    status = SecCodeCopySigningInformation(staticCodeRef, kSecCSDefaultFlags, &signingInformation);
    if (status != errSecSuccess) {
        NSLog(@"Failed to copy signing information with error code: %d", (int)status);
        return nil;
    }
    
    CFRelease(staticCodeRef);
    return CFBridgingRelease(signingInformation);
}

@end
