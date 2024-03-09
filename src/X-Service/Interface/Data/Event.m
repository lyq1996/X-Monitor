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

+ (nullable Event *)initEvent:(NSString *)eventType {
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
                    [FileProviderMaterializeEvent class], @"notify_file_provider_materialize",
                    [FileProviderUpdateEvent class], @"notify_file_provider_update",
                    [ReadlinkEvent class], @"notify_readlink",
                    [TruncateEvent class], @"notify_truncate",
                    [LookupEvent class], @"notify_lookup",
                    // The following events are available beginning in macOS 10.15.1
                    [ChdirEvent class], @"notify_chdir",
                    [GetAttrlistEvent class], @"notify_getattrlist",
                    [StatEvent class], @"notify_stat",
                    [AccessEvent class], @"notify_access",
                    [ChrootEvent class], @"notify_chroot",
                    [UtimesEvent class], @"notify_utimes",
                    [CloneEvent class], @"notify_clone",
                    [FcntlEvent class], @"notify_fcntl",
                    [GetExtAttrEvent class], @"notify_getextattr",
                    [ListExtAttrEvent class], @"notify_listextattr",
                    [ReaddirEvent class], @"notify_readdir",
                    [DeleteExtAttrEvent class], @"notify_deleteextattr",
                    [FsGetPathEvent class], @"notify_fsgetpath",
                    [DupEvent class], @"notify_dup",
                    [SetTimeEvent class], @"notify_settime",
                    [UipcBindEvent class], @"notify_uipc_bind",
                    [UipcConnectEvent class], @"notify_uipc_connect",
                    // The following events are available beginning in macOS 10.15.4
                    [SetAclEvent class], @"notify_setacl",
                    [PtyGrantEvent class], @"notify_pty_grant",
                    [PtyCloseEvent class], @"notify_pty_close",
                    [ProcCheckEvent class], @"notify_proc_check",
                    // The following events are available beginning in macOS 11.0
                    [SearchFsEvent class], @"notify_searchfs",
                    [ProcSuspendResumeEvent class], @"notify_proc_suspend_resume",
                    [CsInvalidatedEvent class], @"notify_cs_invalidated",
                    [GetTaskNameEvent class], @"notify_get_task_name",
                    [TraceEvent class], @"notify_trace",
                    [RemoteThreadCreateEvent class], @"notify_remote_thread_create",
                    [RemountEvent class], @"notify_remount",
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
                    // The following events are available beginning in macOS 14.0
                    [ProfileAddEvent class], @"notifyProfileAdd",
                    [ProfileRemoveEvent class], @"notifyProfileRemove",
                    [SuEvent class], @"notifySu",
                    [AuthorizationPetitionEvent class], @"notifyAuthorizationPetition",
                    [AuthorizationJudgementEvent class], @"notifyAuthorizationJudgement",
                    [SudoEvent class], @"notifySudo",
                    [OdGroupAddEvent class], @"notifyOdGroupAdd",
                    [OdGroupRemoveEvent class], @"notifyOdGroupRemove",
                    [OdGroupSetEvent class], @"notifyOdGroupSet",
                    [OdModifyPasswordEvent class], @"notifyOdModifyPassword",
                    [OdDisableUserEvent class], @"notifyOdDisableUser",
                    [OdEnableUserEvent class], @"notifyOdEnableUser",
                    [OdAttributeValueAddEvent class], @"notifyOdAttributeValueAdd",
                    [OdAttributeValueRemoveEvent class], @"notifyOdAttributeValueRemove",
                    [OdAttributeSetEvent class], @"notifyOdAttributeSet",
                    [OdCreateUserEvent class], @"notifyOdCreateUser",
                    [OdCreateGroupEvent class], @"notifyOdCreateGroup",
                    [OdDeleteUserEvent class], @"notifyOdDeleteUser",
                    [OdDeleteGroupEvent class], @"notifyOdDeleteGroup",
                    [XpcConnectEvent class], @"notifyXpcConnect",
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
        _eventTime = [decoder decodeObjectForKey:@"eventTime"];
        _pid = [decoder decodeObjectForKey:@"pid"];
        DECODE_PROCESS_PROPERTY(process)
        DECODE_PROCESS_PROPERTY(parent)
        _ppid = [decoder decodeObjectForKey:@"ppid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_eventIdentify forKey:@"eventIdentify"];
    [encoder encodeObject:_eventType forKey:@"eventType"];
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
        _kextIdentifier = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _kextIdentifier];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tKext ID: %@\n", _kextIdentifier];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _kextIdentifier = [decoder decodeObjectForKey:@"kextIdentifier"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_kextIdentifier forKey:@"_kextIdentifier"];
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
    [detailString appendFormat:@"\tDestination File Path: %@\n", _destinationFilePath];
    
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _destinationFilePath = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _destinationFilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tDestination File Path: %@\n", _destinationFilePath];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _destinationFilePath = [decoder decodeObjectForKey:@"destinationFilePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_destinationFilePath forKey:@"destinationFilePath"];
}

@end

@implementation ExchangeDataEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(file1)
        INIT_FILE_PROPERTY(file2)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@<->%@", _file1FilePath, _file2FilePath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tFile1 UID: %@\n", _file1FileUID];
    [detailString appendFormat:@"\tFile1 GID: %@\n", _file1FileGID];
    [detailString appendFormat:@"\tFile1 Mode: %@\n", _file1FileMode];
    [detailString appendFormat:@"\tFile1 Access Time: %@\n", _file1FileAccessTime];
    [detailString appendFormat:@"\tFile1 Modify Time: %@\n", _file1FileModifyTime];
    [detailString appendFormat:@"\tFile1 Create Time: %@\n", _file1FileCreateTime];
    [detailString appendFormat:@"\tFile1 Path: %@\n", _file1FilePath];
    [detailString appendFormat:@"\tFile2 UID: %@\n", _file2FileUID];
    [detailString appendFormat:@"\tFile2 GID: %@\n", _file2FileGID];
    [detailString appendFormat:@"\tFile2 Mode: %@\n", _file2FileMode];
    [detailString appendFormat:@"\tFile2 Access Time: %@\n", _file2FileAccessTime];
    [detailString appendFormat:@"\tFile2 Modify Time: %@\n", _file2FileModifyTime];
    [detailString appendFormat:@"\tFile2 Create Time: %@\n", _file2FileCreateTime];
    [detailString appendFormat:@"\tFile2 Path: %@\n", _file2FilePath];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(file1)
        DECODE_FILE_PROPERTY(file2)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(file1)
    ENCODE_FILE_PROPERTY(file2)
}

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
    [detailString appendFormat:@"\tStatus: %@\n", _status];
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

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_PROCESS_PROPERTY(target)
        _taskType = @"";
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
    [detailString appendFormat:@"\tTask Type: %@\n", _taskType];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_PROCESS_PROPERTY(target)
        _taskType = [decoder decodeObjectForKey:@"taskType"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_PROCESS_PROPERTY(target)
    [encoder encodeObject:_taskType forKey:@"taskType"];
}

@end

@implementation KextUnloadEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _kextIdentifier = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _kextIdentifier];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tKext ID: %@\n", _kextIdentifier];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _kextIdentifier = [decoder decodeObjectForKey:@"kextIdentifier"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_kextIdentifier forKey:@"kextIdentifier"];
}

@end

@implementation LinkEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(source)
        INIT_FILE_PROPERTY(targetDir)
        _targetFileName = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    NSString *link = [_targetDirFilePath stringByAppendingPathComponent:_targetFileName];
    [detailString appendFormat:@"%@ -> %@", link, _sourceFilePath];
    
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
    
    [detailString appendFormat:@"\tTarget File Name: %@\n", _targetFileName];
    [detailString appendFormat:@"\tTarget Dir File UID: %@\n", _targetDirFileUID];
    [detailString appendFormat:@"\tTarget Dir File GID: %@\n", _targetDirFileGID];
    [detailString appendFormat:@"\tTarget Dir File Mode: %@\n", _targetDirFileMode];
    [detailString appendFormat:@"\tTarget Dir File Access Time: %@\n", _targetDirFileAccessTime];
    [detailString appendFormat:@"\tTarget Dir File Modify Time: %@\n", _targetDirFileModifyTime];
    [detailString appendFormat:@"\tTarget Dir File Create Time: %@\n", _targetDirFileCreateTime];
    [detailString appendFormat:@"\tTarget Dir File Path: %@\n", _targetDirFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(source)
        DECODE_FILE_PROPERTY(targetDir)
        _targetFileName = [decoder decodeObjectForKey:@"targetFileName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(source)
    ENCODE_FILE_PROPERTY(targetDir)
    [encoder encodeObject:_targetFileName forKey:@"targetFileName"];
}

@end

@implementation UnmountEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _unmountPath = @"";
        _sourcePath = @"";
        _fsType = @"";
        _fsID = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", _unmountPath];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tUnmount Path: %@\n", _unmountPath];
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
        _unmountPath = [decoder decodeObjectForKey:@"unmountPath"];
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
    [encoder encodeObject:_unmountPath forKey:@"unmountPath"];
    [encoder encodeObject:_sourcePath forKey:@"sourcePath"];
    [encoder encodeObject:_fsType forKey:@"fsType"];
    [encoder encodeObject:_fsID forKey:@"fsID"];
    [encoder encodeObject:_ownerUid forKey:@"ownerUid"];
    [encoder encodeObject:_mountFlags forKey:@"mountFlags"];
    [encoder encodeObject:_totalFiles forKey:@"totalFiles"];
}

@end

@implementation IOKitOpenEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        _userClientType = @(0);
        _userClientClass = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"class: %@", _userClientClass];
    
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];

    [detailString appendFormat:@"Event Details: {\n"];
    [detailString appendFormat:@"\tUser Client Type: %@\n", _userClientType];
    [detailString appendFormat:@"\tUser Client Class: %@\n", _userClientClass];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _userClientType = [decoder decodeObjectForKey:@"userClientType"];
        _userClientClass = [decoder decodeObjectForKey:@"userClientClass"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_userClientType forKey:@"userClientType"];
    [encoder encodeObject:_userClientClass forKey:@"userClientClass"];
}
@end

@implementation SetAttrlistEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        _bitmapCount = @(0);
        _commonAttr = @(0);
        _volAttr = @(0);
        _dirAttr = @(0);
        _fileAttr = @(0);
        _forkAttr = @(0);
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
    [detailString appendFormat:@"\tBitMap Count: %@\n", _bitmapCount];
    [detailString appendFormat:@"\tCommon Attribute Count: %@\n", _commonAttr];
    [detailString appendFormat:@"\tVolume Attribute Group: %@\n", _volAttr];
    [detailString appendFormat:@"\tDirectory Attribute Group: %@\n", _dirAttr];
    [detailString appendFormat:@"\tFile Attribute Group : %@\n", _fileAttr];
    [detailString appendFormat:@"\tFork Attribute Group: %@\n", _forkAttr];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        _bitmapCount = [decoder decodeObjectForKey:@"bitmapCount"];
        _commonAttr = [decoder decodeObjectForKey:@"commonAttr"];
        _volAttr = [decoder decodeObjectForKey:@"volAttr"];
        _dirAttr = [decoder decodeObjectForKey:@"dirAttr"];
        _fileAttr = [decoder decodeObjectForKey:@"fileAttr"];
        _forkAttr = [decoder decodeObjectForKey:@"forkAttr"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    [encoder encodeObject:_bitmapCount forKey:@"bitmapCount"];
    [encoder encodeObject:_commonAttr forKey:@"commonAttr"];
    [encoder encodeObject:_volAttr forKey:@"volAttr"];
    [encoder encodeObject:_dirAttr forKey:@"dirAttr"];
    [encoder encodeObject:_fileAttr forKey:@"fileAttr"];
    [encoder encodeObject:_forkAttr forKey:@"forkAttr"];
}

@end

@implementation SetExtAttrEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        _extAttr = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@ %@", _targetFilePath, _extAttr];
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
    [detailString appendFormat:@"\tExtend Attribute: %@\n", _extAttr];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        _extAttr = [decoder decodeObjectForKey:@"extAttr"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    [encoder encodeObject:_extAttr forKey:@"extAttr"];
}

@end

@implementation SetFlagsEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        _flags = @(0);
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
    [detailString appendFormat:@"\tNew Flags: %@\n", _flags];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        _flags = [decoder decodeObjectForKey:@"flags"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    [encoder encodeObject:_flags forKey:@"flags"];
}

@end

@implementation SetModeEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        _mode = @(0);
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
    [detailString appendFormat:@"\tNew Mode: %@\n", _mode];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        _mode = [decoder decodeObjectForKey:@"mode"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    [encoder encodeObject:_mode forKey:@"mode"];
}

@end

@implementation SetOwnerEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(target)
        _uid = @(0);
        _gid = @(0);
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
    [detailString appendFormat:@"\tNew UID: %@\n", _uid];
    [detailString appendFormat:@"\tNew GID: %@\n", _gid];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(target)
        _uid = [decoder decodeObjectForKey:@"uid"];
        _gid = [decoder decodeObjectForKey:@"gid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(target)
    [encoder encodeObject:_uid forKey:@"uid"];
    [encoder encodeObject:_gid forKey:@"gid"];
}

@end

@implementation WriteEvent

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

@implementation FileProviderMaterializeEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_PROCESS_PROPERTY(instigator)
        INIT_FILE_PROPERTY(source)
        INIT_FILE_PROPERTY(target)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@ -> %@", _sourceFilePath, _targetFilePath];
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];
    
    [detailString appendFormat:@"Event Details: {\n"];
    
    [detailString appendFormat:@"\tInstigator Process Create Time: %@\n", _instigatorCreateTime];
    [detailString appendFormat:@"\tInstigator Process Path: %@\n", _instigatorPath];
    [detailString appendFormat:@"\tInstigator Process Cmdline: %@\n", _instigatorCmdline];
    [detailString appendFormat:@"\tInstigator Process Codesign Flag: 0x%X\n", [_instigatorCodesignFlag unsignedIntValue]];
    [detailString appendFormat:@"\tInstigator Process Signing ID: %@\n", _instigatorSigningID];
    [detailString appendFormat:@"\tInstigator Process Team ID: %@\n", _instigatorTeamID];
    
    [detailString appendFormat:@"\tSource File UID: %@\n", _sourceFileUID];
    [detailString appendFormat:@"\tSource File GID: %@\n", _sourceFileGID];
    [detailString appendFormat:@"\tSource File Mode: %@\n", _sourceFileMode];
    [detailString appendFormat:@"\tSource File Access Time: %@\n", _sourceFileAccessTime];
    [detailString appendFormat:@"\tSource File Modify Time: %@\n", _sourceFileModifyTime];
    [detailString appendFormat:@"\tSource File Create Time: %@\n", _sourceFileCreateTime];
    [detailString appendFormat:@"\tSource File Path: %@\n", _sourceFilePath];
    
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
        DECODE_PROCESS_PROPERTY(instigator)
        DECODE_FILE_PROPERTY(source)
        DECODE_FILE_PROPERTY(target)
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_PROCESS_PROPERTY(instigator)
    ENCODE_FILE_PROPERTY(source)
    ENCODE_FILE_PROPERTY(target)
}

@end

@implementation FileProviderUpdateEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(source)
        _targetFilePath = @"";
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@ -> %@", _sourceFilePath, _targetFilePath];
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

    [detailString appendFormat:@"\tTarget File Path: %@\n", _targetFilePath];
    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(source)
        _targetFilePath = [decoder decodeObjectForKey:@"targetFilePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(source)
    [encoder encodeObject:_targetFilePath forKey:@"targetFilePath"];
}

@end

@implementation ReadlinkEvent

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

@implementation TruncateEvent

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

@implementation LookupEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        INIT_FILE_PROPERTY(sourceDir)
    }
    return self;
}

- (NSString *)shortInfo {
    NSMutableString *detailString = [NSMutableString string];
    [detailString appendFormat:@"%@", [_sourceDirFilePath stringByAppendingPathComponent:_relativeTargetFilePath]];
    return detailString;
}

- (NSString *)detailInfo {
    NSMutableString *detailString = [[super detailInfo] mutableCopy];
    
    [detailString appendFormat:@"Event Details: {\n"];

    [detailString appendFormat:@"\tSource Dir File UID: %@\n", _sourceDirFileUID];
    [detailString appendFormat:@"\tSource Dir GID: %@\n", _sourceDirFileGID];
    [detailString appendFormat:@"\tSource Dir Mode: %@\n", _sourceDirFileMode];
    [detailString appendFormat:@"\tSource Dir Access Time: %@\n", _sourceDirFileAccessTime];
    [detailString appendFormat:@"\tSource Dir Modify Time: %@\n", _sourceDirFileModifyTime];
    [detailString appendFormat:@"\tSource Dir Create Time: %@\n", _sourceDirFileCreateTime];
    [detailString appendFormat:@"\tSource Dir Path: %@\n", _sourceDirFilePath];

    [detailString appendFormat:@"\tReleative Target File Path: %@\n", _relativeTargetFilePath];

    [detailString appendFormat:@"}"];

    return detailString;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        DECODE_FILE_PROPERTY(sourceDir)
        _relativeTargetFilePath = [decoder decodeObjectForKey:@"relativeTargetFilePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    ENCODE_FILE_PROPERTY(sourceDir)
    [encoder encodeObject:_relativeTargetFilePath forKey:@"relativeTargetFilePath"];
}

@end

@implementation ChdirEvent

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

@implementation ProfileAddEvent

@end

@implementation ProfileRemoveEvent

@end

@implementation SuEvent

@end

@implementation AuthorizationPetitionEvent

@end

@implementation AuthorizationJudgementEvent

@end

@implementation SudoEvent

@end

@implementation OdGroupAddEvent

@end

@implementation OdGroupRemoveEvent

@end

@implementation OdGroupSetEvent

@end

@implementation OdModifyPasswordEvent

@end

@implementation OdDisableUserEvent

@end

@implementation OdEnableUserEvent

@end

@implementation OdAttributeValueAddEvent

@end

@implementation OdAttributeValueRemoveEvent

@end

@implementation OdAttributeSetEvent

@end

@implementation OdCreateUserEvent

@end

@implementation OdCreateGroupEvent

@end

@implementation OdDeleteUserEvent

@end

@implementation OdDeleteGroupEvent

@end

@implementation XpcConnectEvent

@end
