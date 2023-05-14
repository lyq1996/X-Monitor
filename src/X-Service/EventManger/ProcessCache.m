//
//  EventCache.m
//  X-Service
//
//  Created by lyq1996 on 2023/3/11.
//

#import "ProcessCache.h"
#import "NSMutableDictionary+Event.h"
#import "ProcUtils.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;


/*
 cache key:  (NSNumber *)pid
 cache value: (ProcessInfo *)process info

{
  1683446185,
  "/usr/bin/zsh",
  "/usr/bin/zsh",
  570492929,
  "com.apple.zsh",
  "",
}
*/

@interface ProcessInfo : NSObject <NSCopying>

@property (nonatomic, copy) NSNumber *createTime;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *cmdline;
@property (nonatomic, copy) NSNumber *csFlag;
@property (nonatomic, copy) NSString *signingID;
@property (nonatomic, copy) NSString *teamID;

@end

@implementation ProcessInfo

- (NSString *)description {
    return [NSString stringWithFormat:@"createTime: %@, path: %@, cmdline: %@, csFlag: 0x%ux, signingID: %@, teamID: %@",
            self.createTime,
            self.path,
            self.cmdline,
            [self.csFlag unsignedIntValue],
            self.signingID,
            self.teamID];
}

- (id)copyWithZone:(NSZone *)zone {
    ProcessInfo *copy = [[[self class] allocWithZone:zone] init];
    copy.createTime = self.createTime;
    copy.path = self.path;
    copy.cmdline = self.cmdline;
    copy.csFlag = self.csFlag;
    copy.signingID = self.signingID;
    copy.teamID = self.teamID;
    return copy;
}

@end

@implementation ProcessCache {
    NSMutableDictionary<NSNumber *, ProcessInfo *> *caches;
}

@synthesize subscribleEventTypes;

- (instancetype)init {
    self = [super init];
    if (self) {
        caches = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)consumeEvent:(Event *)event {
    // process cache is a pseudo consumer,
    // it doesn't consume event really, it just need to ensure exec and fork event is subscribed.
    return;
}

- (void)updateProcCache:(NSNumber *)pid withProcInfo:(ProcessInfo *)info {
    @synchronized (caches) {
        [caches setObject:info forKey:pid];
    }
}

- (BOOL)fillProcessInfo:(ProcessInfo *)info withPid:(NSNumber *)pid {

    ProcessInfo *cacheInfo = nil;
    @synchronized (caches) {
        cacheInfo = [[caches objectForKey:pid] copy];
    }

    if (cacheInfo != nil) {
        DDLogDebug(@"cache hit, pid: %@, process info: %@", pid, cacheInfo);
        
        if ([info.path isEqualToString:@""]) {
            info.path = cacheInfo.path;
        }
        if ([info.createTime isEqualToNumber:@-1]) {
            info.createTime = cacheInfo.createTime;
        }
        if ([info.cmdline isEqualToString:@""]) {
            info.cmdline = cacheInfo.cmdline;
        }
        if ([info.csFlag isEqualToNumber:@-1]) {
            info.csFlag = cacheInfo.csFlag;
        }
        if ([info.signingID isEqualToString:@""]) {
            info.signingID = cacheInfo.signingID;
        }
        if ([info.teamID isEqualToString:@""]) {
            info.teamID = cacheInfo.teamID;
        }
        
        return YES;
    }
    else {
        DDLogDebug(@"cache not hit, pid: %@ not found", pid);
        // update process cache
        if ([info.path isEqualToString:@""]) {
            info.path = [ProcUtils getPathFromPid:pid];
        }
        if ([info.createTime isEqualToNumber:@-1]) {
            info.createTime = [ProcUtils getCreatetimeFromPid:pid];
        }
        if ([info.cmdline isEqualToString:@""]) {
            info.cmdline = [ProcUtils getCmdlineFromPid:pid];
        }
        NSDictionary *codeSigningInfo = [ProcUtils getCodeSigningFromPid:info.path];
        if ([info.csFlag isEqualToNumber:@-1]) {
            NSNumber *csFlag = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoFlags];
            if (csFlag != nil) {
                info.csFlag = csFlag;
            }
        }
        if ([info.signingID isEqualToString:@""]) {
            NSString *signingID = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoIdentifier];
            if (signingID != nil) {
                info.signingID = signingID;
            }
        }
        if ([info.teamID isEqualToString:@""]) {
            NSString *teamID = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoTeamIdentifier];
            if (teamID != nil) {
                info.teamID = teamID;
            }
        }
        
        cacheInfo = [info copy];
        [self updateProcCache:pid withProcInfo:cacheInfo];
        
        return NO;
    }
}

#define FILL_EVENT_INFO(PREFIX) \
if ([event.PREFIX##Path isEqualToString:@""]) { \
    event.PREFIX##Path = info.path; \
} \
if ([event.PREFIX##CreateTime isEqualToNumber:@-1]) { \
    event.PREFIX##CreateTime = info.createTime; \
} \
if ([event.PREFIX##Cmdline isEqualToString:@""]) { \
    event.PREFIX##Cmdline = info.cmdline; \
} \
if ([event.PREFIX##CodesignFlag isEqualToNumber:@-1]) { \
    event.PREFIX##CodesignFlag = info.csFlag; \
} \
if ([event.PREFIX##SigningID isEqualToString:@""]) { \
    event.PREFIX##SigningID = info.signingID; \
} \
if ([event.parentTeamID isEqualToString:@""]) { \
    event.PREFIX##TeamID = info.teamID; \
}

- (void)fillEventUseProcInfo:(Event *)event withProcInfo:(ProcessInfo *)info withIsParent:(BOOL)isParent{
    if (isParent) {
        FILL_EVENT_INFO(parent)
    }
    else {
        FILL_EVENT_INFO(process)
    }
}

- (void)updateCacheUsingForkEvent:(Event *)event {
    // update cache use properties from a fork event
    NSString *eventType = event.eventType;
    if ([eventType isEqualToString:@"notify_fork"]) {
        ProcessInfo *info = [[ProcessInfo alloc] init];
        info.path = event.processPath;
        info.createTime = event.processCreateTime;
        info.cmdline = event.processCmdline;
        info.csFlag = event.processCodesignFlag;
        info.signingID = event.processSigningID;
        info.teamID = event.processTeamID;
        
        NSNumber *pid = ((ForkEvent *)event).childPid;
        NSNumber *ppid = event.pid;
        
        BOOL cacheHit = [self fillProcessInfo:info withPid:ppid];
        DDLogDebug(@"update pid: %@, info: %@ to cache", pid, info);
        // update child process cache
        [self updateProcCache:pid withProcInfo:info];
        // if parent pid is not in cache, update it also
        if (!cacheHit) {
            [self updateProcCache:ppid withProcInfo:info];
        }
    }
}

- (void)updateCacheUsingExecEvent:(Event *)event {
    // update cache use properties from an execve event
    NSString *eventType = event.eventType;
    if ([eventType isEqualToString:@"notify_exec"]) {
        ProcessInfo *info = [[ProcessInfo alloc] init];
        info.path = ((ExecEvent *)event).targetPath;
        info.createTime = ((ExecEvent *)event).targetCreateTime;
        info.cmdline = ((ExecEvent *)event).targetCmdline;
        info.csFlag = ((ExecEvent *)event).targetCodesignFlag;
        info.signingID = ((ExecEvent *)event).targetSigningID;
        info.teamID = ((ExecEvent *)event).targetTeamID;
        
        NSNumber *pid = event.pid;
        DDLogDebug(@"update pid: %@, info: %@ to cache", pid, info);
        [self updateProcCache:pid withProcInfo:info];
    }
}

- (void)fillEventFromCache:(Event *)event {
    [self updateCacheUsingForkEvent:event];
    
    NSNumber *pid = event.pid;
    if ([pid isEqualToNumber:@-1]) {
        DDLogWarn(@"pid is -1, skip fill event from cache!");
    }
    else {
        ProcessInfo *info = [[ProcessInfo alloc] init];
        info.path = event.processPath;
        info.createTime = event.processCreateTime;
        info.cmdline = event.processCmdline;
        info.csFlag = event.processCodesignFlag;
        info.signingID = event.processSigningID;
        info.teamID = event.processTeamID;
        [self fillProcessInfo:info withPid:pid];
        [self fillEventUseProcInfo:event withProcInfo:info withIsParent:NO];
    }
    
    NSNumber *ppid = event.ppid;
    if ([ppid isEqualToNumber:@-1]) {
        DDLogWarn(@"ppid is -1, skip fill event from cache!");
    }
    else if ([ppid isEqualToNumber:@0]) {
        DDLogDebug(@"ppid is kernel_task, skip fill event from cache!");
    }
    else {
        ProcessInfo *info = [[ProcessInfo alloc] init];
        info.path = event.parentPath;
        info.createTime = event.parentCreateTime;
        info.cmdline = event.parentCmdline;
        info.csFlag = event.parentCodesignFlag;
        info.signingID = event.parentSigningID;
        info.teamID = event.parentTeamID;
        [self fillProcessInfo:info withPid:ppid];
        [self fillEventUseProcInfo:event withProcInfo:info withIsParent:YES];
    }
    
    [self updateCacheUsingExecEvent:event];
}

- (void)clearCache {
    @synchronized (caches) {
        [caches removeAllObjects];
    }
}

@end
