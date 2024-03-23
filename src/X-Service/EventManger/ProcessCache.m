//
//  EventCache.m
//  X-Service
//
//  Created by lyq1996 on 2023/3/11.
//

#import <os/lock.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "ProcessCache.h"
#import "ProcUtils.h"

extern DDLogLevel ddLogLevel;

/* 
 cache key:  (NSNumber *)pid
 cache value: (ProcessInfo *)process info

{
  ppid: 1,
  createTime: 1683446185,
  path: "/usr/bin/zsh",
  cmdline: "/usr/bin/zsh",
  csFlag: 570492929,
  signingID: "com.apple.zsh",
  teamID: "",
  stale: YES,
}
*/

@interface Cache : NSObject<NSCopying>

@property (nonatomic, copy, nullable) NSNumber *ppid;
@property (nonatomic, copy, nullable) NSNumber *createTime;
@property (nonatomic, copy, nullable) NSString *path;
@property (nonatomic, copy, nullable) NSString *cmdline;
@property (nonatomic, copy, nullable) NSNumber *csFlag;
@property (nonatomic, copy, nullable) NSString *signingID;
@property (nonatomic, copy, nullable) NSString *teamID;

@end

@implementation Cache

- (instancetype)init {
    self = [super init];
    if (self) {
        _ppid = nil;
        _createTime = nil;
        _path = nil;
        _cmdline = nil;
        _csFlag = nil;
        _signingID = nil;
        _teamID = nil;
    }
    return self;
}

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
    Cache *copy = [[[self class] allocWithZone:zone] init];
    copy.ppid = self.ppid;
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
    NSMutableDictionary<NSNumber *, Cache *> *caches;
    os_unfair_lock cacheLock;
}

@synthesize subscribleEventTypes;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initCaches];
        cacheLock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (void)initCaches {
    caches = [NSMutableDictionary dictionary];
}

- (void)consumeEvent:(Event *)event {
    // process cache is a pseudo consumer,
    // it doesn't consume event really, it just need to ensure exec and fork event is subscribed.
    return;
}

- (void)updateProcCache:(NSNumber *)pid withProcInfo:(Cache *)info {
    [caches setObject:info forKey:pid];
}

- (Cache *)getCache:(NSNumber *)pid {
    return [caches objectForKey:pid];
}

- (void)fillCacheFromAnotherCache:(Cache *)tofill withAnother:(Cache *)another {
    if (tofill.ppid == nil) {
        tofill.ppid = another.ppid;
    }
    if (tofill.path == nil) {
        tofill.path = another.path;
    }
    if (tofill.createTime == nil) {
        tofill.createTime = another.createTime;
    }
    if (tofill.cmdline == nil) {
        tofill.cmdline = another.cmdline;
    }
    if (tofill.csFlag == nil) {
        tofill.csFlag = another.csFlag;
    }
    if (tofill.signingID == nil) {
        tofill.signingID = another.signingID;
    }
    if (tofill.teamID == nil) {
        tofill.teamID = another.teamID;
    }
}

- (void)fillCacheFromPid:(Cache *)tofill withPid:(NSNumber *)pid {
    if (tofill.ppid == nil) {
        tofill.ppid = [ProcUtils getParentPidFromPid:pid];
    }
    if (tofill.path == nil) {
        tofill.path = [ProcUtils getPathFromPid:pid];
    }
    if (tofill.createTime == nil) {
        tofill.createTime = [ProcUtils getCreatetimeFromPid:pid];
    }
    if (tofill.cmdline == nil) {
        tofill.cmdline = [ProcUtils getCmdlineFromPid:pid];
    }
    NSDictionary *codeSigningInfo = [ProcUtils getCodeSigningFromPid:tofill.path];
    if (tofill.csFlag == nil) {
        NSNumber *csFlag = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoFlags];
        if (csFlag != nil) {
            tofill.csFlag = csFlag;
        } else {
            tofill.csFlag = @(-1);
        }
    }
    if (tofill.signingID == nil) {
        NSString *signingID = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoIdentifier];
        if (signingID != nil) {
            tofill.signingID = signingID;
        } else {
            tofill.signingID = @"";
        }
    }
    if (tofill.teamID == nil) {
        NSString *teamID = [codeSigningInfo objectForKey:(__bridge NSString *)kSecCodeInfoTeamIdentifier];
        if (teamID != nil) {
            tofill.teamID = teamID;
        } else {
            tofill.teamID = @"";
        }
    }
}

- (NSDictionary *)fillProcessInfoFromCache:(Cache *)cache withInfo:(NSDictionary *)processInfo {
    NSMutableDictionary *newInfo = [NSMutableDictionary dictionaryWithDictionary:processInfo];
    if ([newInfo objectForKey:@"ProcessPath"] == nil) {
        [newInfo setObject:cache.path forKey:@"ProcessPath"];
    }
    if ([newInfo objectForKey:@"ProcessCreateTime"] == nil) {
        [newInfo setObject:cache.createTime forKey:@"ProcessCreateTime"];
    }
    if ([newInfo objectForKey:@"ProcessCodesignFlag"] == nil) {
        [newInfo setObject:cache.csFlag forKey:@"ProcessCodesignFlag"];
    }
    if ([newInfo objectForKey:@"ProcessSigningID"] == nil) {
        [newInfo setObject:cache.signingID forKey:@"ProcessSigningID"];
    }
    if ([newInfo objectForKey:@"ProcessCmdline"] == nil) {
        [newInfo setObject:cache.cmdline forKey:@"ProcessCmdline"];
    }
    if ([newInfo objectForKey:@"ProcessTeamID"] == nil) {
        [newInfo setObject:cache.teamID forKey:@"ProcessTeamID"];
    }

    return newInfo;
}

- (void)updateCacheFromExec:(NSDictionary *)eventInfo
                    withPid:(NSNumber *)pid
              withParentPid:(NSNumber *)ppid {

    NSDictionary *processInfo = [eventInfo objectForKey:@"TargetProcess"];

    Cache *cache = [self getCache:pid];
    if (cache == nil) {
        cache = [[Cache alloc] init];
    }
    
    cache.path = [processInfo valueForKey:@"ProcessPath"];
    cache.createTime = [processInfo valueForKey:@"ProcessCreateTime"];
    cache.cmdline = [processInfo valueForKey:@"ProcessCmdline"];
    cache.csFlag = [processInfo valueForKey:@"ProcessCodesignFlag"];
    cache.signingID = [processInfo valueForKey:@"ProcessSigningID"];
    cache.teamID = [processInfo valueForKey:@"ProcessTeamID"];
    cache.ppid = ppid;

    DDLogDebug(@"update pid: %@, info: %@ to cache", pid, cache);
    [self updateProcCache:pid withProcInfo:cache];
}

- (void)updateCacheFromFork:(NSDictionary *)processInfo
              withEventInfo:(NSDictionary *)eventInfo
                    withPid:(NSNumber *)pid
              withParentPid:(NSNumber *)ppid{
    
    NSNumber *childPid = [eventInfo objectForKey:@"ChildPid"];
    if (childPid == nil) {
        DDLogError(@"update cache from fork failed, no child pid in event info");
        return;
    }
    

    Cache *cache = [self getCache:childPid];
    if (cache == nil) {
        cache = [[Cache alloc] init];
    }
    
    cache.path = [processInfo valueForKey:@"ProcessPath"];
    cache.createTime = [processInfo valueForKey:@"ProcessCreateTime"];
    cache.cmdline =  [processInfo valueForKey:@"ProcessCmdline"];
    cache.csFlag = [processInfo valueForKey:@"ProcessCodesignFlag"];
    cache.signingID = [processInfo valueForKey:@"ProcessSigningID"];
    cache.teamID = [processInfo valueForKey:@"ProcessTeamID"];
    cache.ppid = pid;

    DDLogDebug(@"update pid: %@, info: %@ to cache", childPid, cache);

    Cache *parentCache = [self getCache:pid];
    if (parentCache != nil) {
        [self fillCacheFromAnotherCache:cache withAnother:parentCache];
    } else {
        // parent pid not in cache, use pid to get missing info
        [self fillCacheFromPid:cache withPid:childPid];
    }

    // update child process cache
    [self updateProcCache:childPid withProcInfo:cache];
    
    if (parentCache == nil) {
        // parent not hit the cache, update parent into cache also.
        // ppid need to be changed to parent ppid.
        parentCache = [cache copy];
        parentCache.ppid = ppid;
        [self updateProcCache:pid withProcInfo:parentCache];
    }
}

- (void)handleKernelTask {
    Cache *cache = [self getCache:@(0)];
    if (cache) {
        return;
    }
    
    // add kernel task into cache
    DDLogDebug(@"generate kernel task process cache");
    cache = [[Cache alloc] init];
    cache.path = @"kernel_task";
    cache.createTime = [ProcUtils getSystemBootTime];
    cache.cmdline = @"kernel_task";
    cache.csFlag = @(-1);
    cache.signingID = @"";
    cache.teamID = @"";
    cache.ppid = @(0);
    
    [self updateProcCache:@(0) withProcInfo:cache];
}

- (void)fillEventFromCache:(Event *)event {
    NSString *eventType = event.EventType;
    NSDictionary *processInfo = event.EventProcess;
    NSDictionary *parentProcessInfo = event.EventParentProcess;
    NSDictionary *eventInfo = event.EventInfo;
    
    // pid and ppid must not nil in dictionary,
    // if pid can not be fetched, it will be @(-1).
    NSNumber *pid = [processInfo valueForKey:@"Pid"];
    NSNumber *ppid = [parentProcessInfo valueForKey:@"Pid"];
    
    // 1. update child process cache using fork event.
    // In pid reuse scenario, it's necessary to determine which PIDs have started
    // or exited and update the cache accordingly using exit or fork events.
    // Here I choose fork event, because because fork events can delay the performance cost.
    if ([eventType isEqualToString:@"notify_fork"]) {
        [self updateCacheFromFork:processInfo withEventInfo:eventInfo withPid:pid withParentPid:ppid];
    }

    // 2: using cache to fill process info.
    if ([pid isEqualToNumber:@(-1)]) {
        DDLogWarn(@"pid is nil, skip fill event from cache!");
    } else {
        Cache *cache = [self getCache:pid];
        if (cache == nil) {
            // cache not hit
            cache = [[Cache alloc] init];
            cache.path = [processInfo valueForKey:@"ProcessPath"];
            cache.createTime = [processInfo valueForKey:@"ProcessCreateTime"];
            cache.cmdline = [processInfo valueForKey:@"ProcessCmdline"];
            cache.csFlag = [processInfo valueForKey:@"ProcessCodesignFlag"];
            cache.signingID = [processInfo valueForKey:@"ProcessSigningID"];
            cache.teamID = [processInfo valueForKey:@"ProcessTeamID"];
            if (![ppid isEqualToNumber:@(-1)]) {
                cache.ppid = ppid;
            } else {
                cache.ppid = nil;
            }
            
            [self fillCacheFromPid:cache withPid:pid];
            [self updateProcCache:pid withProcInfo:cache];
        }
        
        NSDictionary *newProcessInfo = [self fillProcessInfoFromCache:cache withInfo:processInfo];
        event.EventProcess = newProcessInfo;
        
        // parent pid could be -1, get it from cache.
        if ([ppid isEqualToNumber:@(-1)]) {
            ppid = cache.ppid;
            [parentProcessInfo setValue:ppid forKey:@"Pid"];
        }
    }
    
    // 3: using cache to fill parent process info.
    if ([ppid isEqualToNumber:@(-1)]) {
        DDLogWarn(@"ppid is nil, skip fill event from cache!");
    }
    else {
        if ([ppid isEqualToNumber:@(0)]) {
            [self handleKernelTask];
        }
        
        Cache *cache = [self getCache:ppid];
        if (cache == nil) {
            // cache not hit
            cache = [[Cache alloc] init];
            cache.path = [parentProcessInfo valueForKey:@"ProcessPath"];
            cache.createTime = [parentProcessInfo valueForKey:@"ProcessCreateTime"];
            cache.cmdline = [parentProcessInfo valueForKey:@"ProcessCmdline"];
            cache.csFlag = [parentProcessInfo valueForKey:@"ProcessCodesignFlag"];
            cache.signingID = [parentProcessInfo valueForKey:@"ProcessSigningID"];
            cache.teamID = [parentProcessInfo valueForKey:@"ProcessTeamID"];
            cache.ppid = nil;
            
            [self fillCacheFromPid:cache withPid:ppid];
            [self updateProcCache:ppid withProcInfo:cache];
        }
        
        NSDictionary *newProcessInfo = [self fillProcessInfoFromCache:cache withInfo:parentProcessInfo];
        event.EventParentProcess = newProcessInfo;
    }

    // 4: if the event is execute event, target process info can be fetched here,
    if ([eventType isEqualToString:@"notify_exec"]) {
        [self updateCacheFromFork:processInfo withEventInfo:eventInfo withPid:pid withParentPid:ppid];
    }
}

- (void)clearCache {
    // mark all cache as staled.
    [caches removeAllObjects];
}

@end
