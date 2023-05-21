//
//  Event.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/12.
//

#import "Event.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <objc/runtime.h>

extern DDLogLevel ddLogLevel;

#define INIT_PROCESS_PROPERTY(PREFIX) \
    _##PREFIX##CreateTime = @(-1); \
    _##PREFIX##Path = @""; \
    _##PREFIX##Cmdline = @""; \
    _##PREFIX##CodesignFlag = @(-1); \
    _##PREFIX##SigningID = @""; \
    _##PREFIX##TeamID = @"";

#define INIT_FILE_PROPERTY(PREFIX) \
    _##PREFIX##FileUID = @(-1); \
    _##PREFIX##FileGID = @(-1); \
    _##PREFIX##FileMode = @(-1); \
    _##PREFIX##FileAccessTime = @(-1); \
    _##PREFIX##FileModifyTime = @(-1); \
    _##PREFIX##FileCreateTime = @(-1); \
    _##PREFIX##FilePath = @"";

#define DECODE_PROCESS_PROPERTY(PREFIX) \
    _##PREFIX##CreateTime = [decoder decodeObjectForKey:@#PREFIX"CreateTime"]; \
    _##PREFIX##Path = [decoder decodeObjectForKey:@#PREFIX"Path"]; \
    _##PREFIX##Cmdline = [decoder decodeObjectForKey:@#PREFIX"Cmdline"]; \
    _##PREFIX##CodesignFlag = [decoder decodeObjectForKey:@#PREFIX"CodesignFlag"]; \
    _##PREFIX##SigningID = [decoder decodeObjectForKey:@#PREFIX"SigningID"]; \
    _##PREFIX##TeamID = [decoder decodeObjectForKey:@#PREFIX"TeamID"];

#define DECODE_FILE_PROPERTY(PREFIX) \
    _##PREFIX##FileUID = [decoder decodeObjectForKey:@#PREFIX"FileUID"]; \
    _##PREFIX##FileGID = [decoder decodeObjectForKey:@#PREFIX"FileGID"]; \
    _##PREFIX##FileMode = [decoder decodeObjectForKey:@#PREFIX"FileMode"]; \
    _##PREFIX##FileAccessTime = [decoder decodeObjectForKey:@#PREFIX"FileAccessTime"]; \
    _##PREFIX##FileModifyTime = [decoder decodeObjectForKey:@#PREFIX"FileModifyTime"]; \
    _##PREFIX##FileCreateTime = [decoder decodeObjectForKey:@#PREFIX"FileCreateTime"]; \
    _##PREFIX##FilePath = [decoder decodeObjectForKey:@#PREFIX"FilePath"]; \

#define ENCODE_PROCESS_PROPERTY(PREFIX) \
    [encoder encodeObject:_##PREFIX##CreateTime forKey:@#PREFIX"CreateTime"]; \
    [encoder encodeObject:_##PREFIX##Path forKey:@#PREFIX"Path"]; \
    [encoder encodeObject:_##PREFIX##Cmdline forKey:@#PREFIX"Cmdline"]; \
    [encoder encodeObject:_##PREFIX##CodesignFlag forKey:@#PREFIX"CodesignFlag"]; \
    [encoder encodeObject:_##PREFIX##SigningID forKey:@#PREFIX"SigningID"]; \
    [encoder encodeObject:_##PREFIX##TeamID forKey:@#PREFIX"TeamID"];

#define ENCODE_FILE_PROPERTY(PREFIX) \
    [encoder encodeObject:_##PREFIX##FileUID forKey:@#PREFIX"FileUID"]; \
    [encoder encodeObject:_##PREFIX##FileGID forKey:@#PREFIX"FileGID"]; \
    [encoder encodeObject:_##PREFIX##FileMode forKey:@#PREFIX"FileMode"]; \
    [encoder encodeObject:_##PREFIX##FileAccessTime forKey:@#PREFIX"FileAccessTime"]; \
    [encoder encodeObject:_##PREFIX##FileModifyTime forKey:@#PREFIX"FileModifyTime"]; \
    [encoder encodeObject:_##PREFIX##FileCreateTime forKey:@#PREFIX"FileCreateTime"]; \
    [encoder encodeObject:_##PREFIX##FilePath forKey:@#PREFIX"FilePath"];

@implementation EventFactory

static NSDictionary *eventClasses;
static NSSet *eventClassesSet;

+ (Event *)initEvent:(NSString *)eventType {
    Class eventClass = [eventClasses objectForKey:eventType];
    if (!eventClass) {
        return nil;
    }
    return [[eventClass alloc] init];
}

+ (NSSet *)getAllClasses {
    return eventClassesSet;
}

+ (void)load {
    eventClasses = [NSDictionary dictionaryWithObjectsAndKeys:
                    [ExecEvent class], @"auth_exec",
                    [OpenEvent class], @"auth_open",
                    [KextLoadEvent class], @"auth_kextload",
                    [MmapEvent class], @"auth_mmap",
                    [MprotectEvent class], @"auth_mprotect",
                    [MountEvent class], @"auth_mount",
                    [RenameEvent class], @"auth_rename",
                    [SignalEvent class], @"auth_signal",
                    [UnlinkEvent class], @"auth_unlink",
                    [ExecEvent class], @"notify_exec",
                    [OpenEvent class], @"notify_open",
                    [ForkEvent class], @"notify_fork",
                    [CloseEvent class], @"notify_close",
                    [CreateEvent class], @"notify_create",
                    [ExchangeDataEvent class], @"notify_exchangedata",
                    [ExitEvent class], @"notify_exit",
                    [GetTaskEvent class], @"notify_get_task",
                    [KextLoadEvent class], @"notify_kextload",
                    [KextUnloadEvent class], @"notify_kextunload",
                    [LinkEvent class], @"notify_link",
                    [MmapEvent class], @"notify_mmap",
                    [MprotectEvent class], @"notify_mprotect",
                    [MountEvent class], @"notify_mount",
                    [UnmountEvent class], @"notify_unmount",
                    [IOKitOpenEvent class], @"notify_iokit_open",
                    [RenameEvent class], @"notify_rename",
                    [SetAttrlistEvent class], @"notify_setattrlist",
                    [SetExtAttrEvent class], @"notify_setextattr",
                    [SetFlagsEvent class], @"notify_setflags",
                    [SetModeEvent class], @"notify_setmode",
                    [SetOwnerEvent class], @"notify_setowner",
                    [SignalEvent class], @"notify_signal",
                    [UnlinkEvent class], @"notify_unlink",
                    [WriteEvent class], @"notify_write",
                    [FileProviderMaterializeEvent class], @"auth_file_provider_materialize",
                    [FileProviderMaterializeEvent class], @"notify_file_provider_materialize",
                    [FileProviderUpdateEvent class], @"auth_file_provider_update",
                    [FileProviderUpdateEvent class], @"notify_file_provider_update",
                    [ReadlinkEvent class], @"auth_readlink",
                    [ReadlinkEvent class], @"notify_readlink",
                    [TruncateEvent class], @"auth_truncate",
                    [TruncateEvent class], @"notify_truncate",
                    [LinkEvent class], @"auth_link",
                    [LookupEvent class], @"notify_lookup",
                    [CreateEvent class], @"auth_create",
                    [SetAttrlistEvent class], @"auth_setattrlist",
                    [SetExtAttrEvent class], @"auth_setextattr",
                    [SetFlagsEvent class], @"auth_setflags",
                    [SetModeEvent class], @"auth_setmode",
                    [SetOwnerEvent class], @"auth_setowner",
                    // The following events are available beginning in macOS 10.15.1
                    [ChdirEvent class], @"auth_chdir",
                    [ChdirEvent class], @"notify_chdir",
                    [GetAttrlistEvent class], @"auth_getattrlist",
                    [GetAttrlistEvent class], @"notify_getattrlist",
                    [StatEvent class], @"notify_stat",
                    [AccessEvent class], @"notify_access",
                    [ChrootEvent class], @"auth_chroot",
                    [ChrootEvent class], @"notify_chroot",
                    [UtimesEvent class], @"auth_utimes",
                    [UtimesEvent class], @"notify_utimes",
                    [CloneEvent class], @"auth_clone",
                    [CloneEvent class], @"notify_clone",
                    [FcntlEvent class], @"notify_fcntl",
                    [GetExtAttrEvent class], @"auth_getextattr",
                    [GetExtAttrEvent class], @"notify_getextattr",
                    [ListExtAttrEvent class], @"auth_listextattr",
                    [ListExtAttrEvent class], @"notify_listextattr",
                    [ReaddirEvent class], @"auth_readdir",
                    [ReaddirEvent class], @"notify_readdir",
                    [DeleteExtAttrEvent class], @"auth_deleteextattr",
                    [DeleteExtAttrEvent class], @"notify_deleteextattr",
                    [FsGetPathEvent class], @"auth_fsgetpath",
                    [FsGetPathEvent class], @"notify_fsgetpath",
                    [DupEvent class], @"notify_dup",
                    [SetTimeEvent class], @"auth_settime",
                    [SetTimeEvent class], @"notify_settime",
                    [UipcBindEvent class], @"notify_uipc_bind",
                    [UipcBindEvent class], @"auth_uipc_bind",
                    [UipcConnectEvent class], @"notify_uipc_connect",
                    [UipcConnectEvent class], @"auth_uipc_connect",
                    [ExchangeDataEvent class], @"auth_exchangedata",
                    // The following events are available beginning in macOS 10.15.4
                    [SetAclEvent class], @"auth_setacl",
                    [SetAclEvent class], @"notify_setacl",
                    [PtyGrantEvent class], @"notify_pty_grant",
                    [PtyCloseEvent class], @"notify_pty_close",
                    [ProcCheckEvent class], @"auth_proc_check",
                    [ProcCheckEvent class], @"notify_proc_check",
                    [GetTaskEvent class], @"auth_get_task",
                    [SearchFsEvent class], @"auth_searchfs",
                    // The following events are available beginning in macOS 11.0
                    [SearchFsEvent class], @"notify_searchfs",
                    [FcntlEvent class], @"auth_fcntl",
                    [IOKitOpenEvent class], @"auth_iokit_open",
                    [ProcSuspendResumeEvent class], @"auth_proc_suspend_resume",
                    [ProcSuspendResumeEvent class], @"notify_proc_suspend_resume",
                    [CsInvalidatedEvent class], @"notify_cs_invalidated",
                    [GetTaskNameEvent class], @"notify_get_task_name",
                    [TraceEvent class], @"notify_trace",
                    [RemoteThreadCreateEvent class], @"notify_remote_thread_create",
                    [RemountEvent class], @"auth_remount",
                    [RemountEvent class], @"notify_remount",
                    [GetTaskReadEvent class], @"auth_get_task_read",
                    // The following events are available beginning in macOS 11.3
                    [GetTaskReadEvent class], @"notify_get_task_read",
                    [GetTaskInspectEvent class], @"notify_get_task_inspect",
                    // The following events are available beginning in macOS 12.0
                    [SetUidEvent class], @"notify_setuid",
                    [SetGidEvent class], @"notify_setgid",
                    [SetEuidEvent class], @"notify_seteuid",
                    [SetEgidEvent class], @"notify_setegid",
                    [SetReuidEvent class], @"notify_setreuid",
                    [SetRegidEvent class], @"notify_setregid",
                    [CopyFileEvent class], @"auth_copyfile",
                    [CopyFileEvent class], @"notify_copyfile",
                    // The following events are available beginning in macOS 13.0
                    [AuthenticationEvent class], @"notify_authentication",
                    [XpMalwareDetectedEvent class], @"notify_xp_malware_detected",
                    [XpMalwareRemediatedEvent class], @"notify_xp_malware_remediated",
                    [LwSessionLoginEvent class], @"notify_lw_session_login",
                    [LwSessionLogoutEvent class], @"notify_lw_session_logout",
                    [LwSessionLockEvent class], @"notify_lw_session_lock",
                    [LwSessionUnlockEvent class], @"notify_lw_session_unlock",
                    [ScreensharingAttachEvent class], @"notify_screensharing_attach",
                    [ScreensharingDetachEvent class], @"notify_screensharing_detach",
                    [OpensshLoginEvent class], @"notify_openssh_login",
                    [OpensshLogoutEvent class], @"notify_openssh_logout",
                    [LoginLoginEvent class], @"notify_login_login",
                    [LoginLogoutEvent class], @"notify_login_logout",
                    [BtmLaunchItemAddEvent class], @"notify_btm_launch_item_add",
                    [BtmLaunchItemRemoveEvent class], @"notify_btm_launch_item_remove",
                    nil];
    eventClassesSet = [NSSet setWithArray:[eventClasses allValues]];
}

@end

#pragma mark Base Event

@implementation Event

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventIdentify = @(-1);
        _eventType = @"";
        _needDiscision = @(-1);
        _eventTime = @(-1);
        _pid = @(-1);
        INIT_PROCESS_PROPERTY(process)
        _ppid = @(-1);
        INIT_PROCESS_PROPERTY(parent)

    }
    return self;
}

- (NSString *)shortInfo {
    // must override
    return @"";
}

- (NSString *)detailInfo {
    // must override
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"Event ID: %@\n", _eventIdentify];
    [detailString appendFormat:@"Event Type: %@\n", _eventType];
    [detailString appendFormat:@"Need Decision: %@\n", _needDiscision];
    [detailString appendFormat:@"Event Time: %@\n", _eventTime];
    [detailString appendFormat:@"Process ID: %@\n", _pid];
    [detailString appendFormat:@"Process Create Time: %@\n", _processCreateTime];
    [detailString appendFormat:@"Process Path: %@\n", _processPath];
    [detailString appendFormat:@"Process Cmdline: %@\n", _processCmdline];
    [detailString appendFormat:@"Process Codesign Flag: 0x%X\n", [_processCodesignFlag unsignedIntValue]];
    [detailString appendFormat:@"Process Signing ID: %@\n", _processSigningID];
    [detailString appendFormat:@"Process Team ID: %@\n", _processTeamID];
    
    [detailString appendFormat:@"Parent Process ID: %@\n", _ppid];
    [detailString appendFormat:@"Parent Process Create Time: %@\n", _parentCreateTime];
    [detailString appendFormat:@"Parent Process Path: %@\n", _parentPath];
    [detailString appendFormat:@"Parent Process Cmdline: %@\n", _parentCmdline];
    [detailString appendFormat:@"Parent Process Codesign Flag: 0x%X\n", [_parentCodesignFlag unsignedIntValue]];
    [detailString appendFormat:@"Parent Process Signing ID: %@\n", _parentSigningID];
    [detailString appendFormat:@"Parent Process Team ID: %@\n", _parentTeamID];
    return detailString;
}

- (NSDictionary *)handleDictionary {
    NSMutableDictionary *baseProperties = [NSMutableDictionary dictionary];
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([self superclass], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:propertyName];
        id value = [self valueForKey:key];
        if (value) {
            [baseProperties setObject:value forKey:key];
        } else {
            continue;
        }
    }
    free(properties);
    
    NSMutableDictionary *DerivedPerties = [NSMutableDictionary dictionary];
    properties = class_copyPropertyList([self class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:propertyName];
        id value = [self valueForKey:key];
        if (value && ![baseProperties objectForKey:key]) {
            [DerivedPerties setObject:value forKey:key];
        } else {
            continue;
        }
    }
    
    [baseProperties setObject:DerivedPerties forKey:@"properties"];
    
    free(properties);
    return baseProperties;
    
}

- (NSString *)jsonInfo {
    NSDictionary *dictionary = [self handleDictionary];
    NSError *error = nil;
    NSData *eventJson = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingWithoutEscapingSlashes error:&error];
    if (error) {
        DDLogError(@"Error converting event object to JSON: %@", error.localizedDescription);
        return @"";
    }
    else {
        return [[NSString alloc] initWithData:eventJson encoding:NSUTF8StringEncoding];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _eventIdentify = [decoder decodeObjectForKey:@"eventIdentify"];
        _eventType = [decoder decodeObjectForKey:@"eventType"];
        _needDiscision = [decoder decodeObjectForKey:@"needDiscision"];
        _eventTime = [decoder decodeObjectForKey:@"eventTime"];
        _pid = [decoder decodeObjectForKey:@"pid"];
        DECODE_PROCESS_PROPERTY(process)
        DECODE_PROCESS_PROPERTY(parent)
        _ppid = [decoder decodeObjectForKey:@"pid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_eventIdentify forKey:@"eventIdentify"];
    [encoder encodeObject:_eventType forKey:@"eventType"];
    [encoder encodeObject:_needDiscision forKey:@"needDiscision"];
    [encoder encodeObject:_eventTime forKey:@"eventTime"];
    [encoder encodeObject:_pid forKey:@"pid"];
    ENCODE_PROCESS_PROPERTY(process)
    [encoder encodeObject:_ppid forKey:@"ppid"];
    ENCODE_PROCESS_PROPERTY(parent)
}

@end

@implementation ExecEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_PROCESS_PROPERTY(target)
        INIT_FILE_PROPERTY(target)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _targetPath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];
    
    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tTarget Process Create Time: %@\n", _targetCreateTime];
    [detailString appendFormat:@"\tTarget Process Path: %@\n", _targetPath];
    [detailString appendFormat:@"\tTarget Process Cmdline: %@\n", _targetCmdline];
    [detailString appendFormat:@"\tTarget Process Codesign Flag: 0x%X\n", [_targetCodesignFlag unsignedIntValue]];
    [detailString appendFormat:@"\tTarget Process Signing ID: %@\n", _targetSigningID];
    [detailString appendFormat:@"\tTarget Process Team ID: %@\n", _targetTeamID];
    
    [detailString appendFormat:@"\tTarget File UID: %@\n", _targetFileUID];
    [detailString appendFormat:@"\tTarget File GID: %@\n", _targetFileGID];
    [detailString appendFormat:@"\tTarget File Mode: %@\n", _targetFileMode];
    [detailString appendFormat:@"\tTarget File Access Time: %@\n", _targetFileAccessTime];
    [detailString appendFormat:@"\tTarget File Modify Time: %@\n", _targetFileModifyTime];
    [detailString appendFormat:@"\tTarget File Create Time: %@\n", _targetFileCreateTime];
    [detailString appendFormat:@"\tTarget File Path: %@\n", _targetFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_PROCESS_PROPERTY(target)
        DECODE_FILE_PROPERTY(target)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_PROCESS_PROPERTY(target)
    ENCODE_FILE_PROPERTY(target)
}

@end

@implementation OpenEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _targetFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tTarget File UID: %@\n", _targetFileUID];
    [detailString appendFormat:@"\tTarget File GID: %@\n", _targetFileGID];
    [detailString appendFormat:@"\tTarget File Mode: %@\n", _targetFileMode];
    [detailString appendFormat:@"\tTarget File Access Time: %@\n", _targetFileAccessTime];
    [detailString appendFormat:@"\tTarget File Modify Time: %@\n", _targetFileModifyTime];
    [detailString appendFormat:@"\tTarget File Create Time: %@\n", _targetFileCreateTime];
    [detailString appendFormat:@"\tTarget File Path: %@\n", _targetFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
}

@end

@implementation KextLoadEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _kextFilePath = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _kextFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tKext Path: %@\n", _kextFilePath];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _kextFilePath = [decoder decodeObjectForKey:@"kextFilePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_kextFilePath forKey:@"kextFilePath"];
}

@end

@implementation MmapEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(source)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _sourceFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tSource File UID: %@\n", _sourceFileUID];
    [detailString appendFormat:@"\tSource File GID: %@\n", _sourceFileGID];
    [detailString appendFormat:@"\tSource File Mode: %@\n", _sourceFileMode];
    [detailString appendFormat:@"\tSource File Access Time: %@\n", _sourceFileAccessTime];
    [detailString appendFormat:@"\tSource File Modify Time: %@\n", _sourceFileModifyTime];
    [detailString appendFormat:@"\tSource File Create Time: %@\n", _sourceFileCreateTime];
    [detailString appendFormat:@"\tSource File Path: %@\n", _sourceFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(source)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(source)
}

@end

@implementation MprotectEvent

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%p", _address.pointerValue];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tAddress: %p\n", _address.pointerValue];
    [detailString appendFormat:@"\tSize: %@\n", _size];
    [detailString appendFormat:@"\tProtection: %@\n", _protection];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _address = [decoder decodeObjectForKey:@"address"];
        _size = [decoder decodeObjectForKey:@"size"];
        _protection = [decoder decodeObjectForKey:@"protection"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_address forKey:@"address"];
    [encoder encodeObject:_size forKey:@"size"];
    [encoder encodeObject:_protection forKey:@"protection"];
}

@end

@implementation MountEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _mountPath = @"";
        _sourcePath = @"";
        _fsType = @"";
        _fsID = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _mountPath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tMount Path: %@\n", _mountPath];
    [detailString appendFormat:@"\tSource Path: %@\n", _sourcePath];
    [detailString appendFormat:@"\tFile System Type: %@\n", _fsType];
    [detailString appendFormat:@"\tFile System ID: %@\n", _fsID];
    [detailString appendFormat:@"\tOwner UID: %@\n", _ownerUid];
    [detailString appendFormat:@"\tMount Flags: %@\n", _mountFlags];
    [detailString appendFormat:@"\tTotal Files: %@\n", _totalFiles];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _mountPath = [decoder decodeObjectForKey:@"mountPath"];
        _sourcePath = [decoder decodeObjectForKey:@"sourcePath"];
        _fsType = [decoder decodeObjectForKey:@"fsType"];
        _fsID = [decoder decodeObjectForKey:@"fsID"];
        _ownerUid = [decoder decodeObjectForKey:@"ownerUid"];
        _mountFlags = [decoder decodeObjectForKey:@"mountFlags"];
        _totalFiles = [decoder decodeObjectForKey:@"totalFiles"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_mountPath forKey:@"mountPath"];
    [encoder encodeObject:_sourcePath forKey:@"sourcePath"];
    [encoder encodeObject:_fsType forKey:@"fsType"];
    [encoder encodeObject:_fsID forKey:@"fsID"];
    [encoder encodeObject:_ownerUid forKey:@"ownerUid"];
    [encoder encodeObject:_mountFlags forKey:@"mountFlags"];
    [encoder encodeObject:_totalFiles forKey:@"totalFiles"];
}

@end

@implementation RenameEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(source)
        _destinationFilePath = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@ -> %@", _sourceFilePath, _destinationFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tSource File UID: %@\n", _sourceFileUID];
    [detailString appendFormat:@"\tSource File GID: %@\n", _sourceFileGID];
    [detailString appendFormat:@"\tSource File Mode: %@\n", _sourceFileMode];
    [detailString appendFormat:@"\tSource File Access Time: %@\n", _sourceFileAccessTime];
    [detailString appendFormat:@"\tSource File Modify Time: %@\n", _sourceFileModifyTime];
    [detailString appendFormat:@"\tSource File Create Time: %@\n", _sourceFileCreateTime];
    [detailString appendFormat:@"\tSource File Path: %@\n", _sourceFilePath];
    [detailString appendFormat:@"\tDestination File Path: %@", _destinationFilePath];
    
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(source)
        _destinationFilePath = [decoder decodeObjectForKey:@"destinationFilePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(source)
    [encoder encodeObject:_destinationFilePath forKey:@"destinationFilePath"];
}

@end

@implementation SignalEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_PROCESS_PROPERTY(target)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _signal];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];
    
    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tTarget Process Create Time: %@\n", _targetCreateTime];
    [detailString appendFormat:@"\tTarget Process Path: %@\n", _targetPath];
    [detailString appendFormat:@"\tTarget Process Cmdline: %@\n", _targetCmdline];
    [detailString appendFormat:@"\tTarget Process Codesign Flag: 0x%X\n", [_targetCodesignFlag unsignedIntValue]];
    [detailString appendFormat:@"\tTarget Process Signing ID: %@\n", _targetSigningID];
    [detailString appendFormat:@"\tTarget Process Team ID: %@\n", _targetTeamID];
    
    [detailString appendFormat:@"\tSignal: %@\n", _signal];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_PROCESS_PROPERTY(target)
        _signal= [decoder decodeObjectForKey:@"signal"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_PROCESS_PROPERTY(target)
    [encoder encodeObject:_signal forKey:@"signal"];
}

@end

@implementation UnlinkEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        INIT_FILE_PROPERTY(parentDir)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _targetFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tTarget File UID: %@\n", _targetFileUID];
    [detailString appendFormat:@"\tTarget File GID: %@\n", _targetFileGID];
    [detailString appendFormat:@"\tTarget File Mode: %@\n", _targetFileMode];
    [detailString appendFormat:@"\tTarget File Access Time: %@\n", _targetFileAccessTime];
    [detailString appendFormat:@"\tTarget File Modify Time: %@\n", _targetFileModifyTime];
    [detailString appendFormat:@"\tTarget File Create Time: %@\n", _targetFileCreateTime];
    [detailString appendFormat:@"\tTarget File Path: %@\n", _targetFilePath];
    [detailString appendFormat:@"\tParent Dir File UID: %@\n", _parentDirFileUID];
    [detailString appendFormat:@"\tParent Dir File GID: %@\n", _parentDirFileGID];
    [detailString appendFormat:@"\tParent Dir File Mode: %@\n", _parentDirFileMode];
    [detailString appendFormat:@"\tParent Dir File Access Time: %@\n", _parentDirFileAccessTime];
    [detailString appendFormat:@"\tParent Dir File Modify Time: %@\n", _parentDirFileModifyTime];
    [detailString appendFormat:@"\tParent Dir File Create Time: %@\n", _parentDirFileCreateTime];
    [detailString appendFormat:@"\tParent Dir File Path: %@\n", _parentDirFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        DECODE_FILE_PROPERTY(parentDir)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    ENCODE_FILE_PROPERTY(parentDir)
}

@end

@implementation ForkEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _childPid = @(-1);
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _childPid];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tChild Pid: %@\n", _childPid];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _childPid = [decoder decodeObjectForKey:@"childPid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_childPid forKey:@"childPid"];
}

@end

@implementation CloseEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _targetFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tTarget File UID: %@\n", _targetFileUID];
    [detailString appendFormat:@"\tTarget File GID: %@\n", _targetFileGID];
    [detailString appendFormat:@"\tTarget File Mode: %@\n", _targetFileMode];
    [detailString appendFormat:@"\tTarget File Access Time: %@\n", _targetFileAccessTime];
    [detailString appendFormat:@"\tTarget File Modify Time: %@\n", _targetFileModifyTime];
    [detailString appendFormat:@"\tTarget File Create Time: %@\n", _targetFileCreateTime];
    [detailString appendFormat:@"\tTarget File Path: %@\n", _targetFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
}

@end

@implementation CreateEvent

@end

@implementation ExchangeDataEvent

@end

@implementation ExitEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = @(-1);
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _status];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tStatus %@\n", _status];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _status = [decoder decodeObjectForKey:@"status"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_status forKey:@"status"];
}

@end

@implementation GetTaskEvent

@end

@implementation KextUnloadEvent

@end

@implementation LinkEvent

@end

@implementation UnmountEvent

@end

@implementation IOKitOpenEvent

@end

@implementation SetAttrlistEvent

@end

@implementation SetExtAttrEvent

@end

@implementation SetFlagsEvent

@end

@implementation SetModeEvent

@end

@implementation SetOwnerEvent

@end

@implementation WriteEvent

@end

@implementation FileProviderMaterializeEvent

@end

@implementation FileProviderUpdateEvent

@end

@implementation ReadlinkEvent

@end

@implementation TruncateEvent

@end

@implementation LookupEvent

@end

@implementation ChdirEvent

@end

@implementation GetAttrlistEvent

@end

@implementation StatEvent

@end

@implementation AccessEvent

@end

@implementation ChrootEvent

@end

@implementation UtimesEvent

@end

@implementation CloneEvent

@end

@implementation FcntlEvent

@end

@implementation GetExtAttrEvent

@end

@implementation ListExtAttrEvent

@end

@implementation ReaddirEvent

@end

@implementation DeleteExtAttrEvent

@end

@implementation FsGetPathEvent

@end

@implementation DupEvent

@end

@implementation SetTimeEvent

@end

@implementation UipcBindEvent

@end

@implementation UipcConnectEvent

@end

@implementation SetAclEvent

@end

@implementation PtyGrantEvent

@end

@implementation PtyCloseEvent

@end

@implementation ProcCheckEvent

@end

@implementation SearchFsEvent

@end

@implementation ProcSuspendResumeEvent

@end

@implementation CsInvalidatedEvent

@end

@implementation GetTaskNameEvent

@end

@implementation TraceEvent

@end

@implementation RemoteThreadCreateEvent

@end

@implementation RemountEvent

@end

@implementation GetTaskReadEvent

@end

@implementation GetTaskInspectEvent

@end

@implementation SetUidEvent

@end

@implementation SetGidEvent

@end

@implementation SetEuidEvent

@end

@implementation SetEgidEvent

@end

@implementation SetReuidEvent

@end

@implementation SetRegidEvent

@end

@implementation CopyFileEvent

@end

@implementation AuthenticationEvent

@end

@implementation XpMalwareDetectedEvent

@end

@implementation XpMalwareRemediatedEvent

@end

@implementation LwSessionLoginEvent

@end

@implementation LwSessionLogoutEvent

@end

@implementation LwSessionLockEvent

@end

@implementation LwSessionUnlockEvent

@end

@implementation ScreensharingAttachEvent

@end

@implementation ScreensharingDetachEvent

@end

@implementation OpensshLoginEvent

@end

@implementation OpensshLogoutEvent

@end

@implementation LoginLoginEvent

@end

@implementation LoginLogoutEvent

@end

@implementation BtmLaunchItemAddEvent

@end

@implementation BtmLaunchItemRemoveEvent

@end

