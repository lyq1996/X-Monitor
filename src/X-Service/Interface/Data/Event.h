//
//  Event.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define GEN_PROCESS_PROPERTY(PREFIX) \
    @property (nonatomic, copy) NSNumber *PREFIX##CreateTime; \
    @property (nonatomic, copy) NSString *PREFIX##Path; \
    @property (nonatomic, copy) NSString *PREFIX##Cmdline; \
    @property (nonatomic, copy) NSNumber *PREFIX##CodesignFlag; \
    @property (nonatomic, copy) NSString *PREFIX##SigningID; \
    @property (nonatomic, copy) NSString *PREFIX##TeamID;

#define GEN_FILE_PROPERTY(PREFIX) \
    @property (nonatomic, copy) NSNumber *PREFIX##FileUID; \
    @property (nonatomic, copy) NSNumber *PREFIX##FileGID; \
    @property (nonatomic, copy) NSNumber *PREFIX##FileMode; \
    @property (nonatomic, copy) NSNumber *PREFIX##FileAccessTime; \
    @property (nonatomic, copy) NSNumber *PREFIX##FileModifyTime; \
    @property (nonatomic, copy) NSNumber *PREFIX##FileCreateTime; \
    @property (nonatomic, copy) NSString *PREFIX##FilePath; \


@interface Event : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSNumber *eventIdentify;
@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSNumber *eventTime;
@property (nonatomic, copy) NSNumber *pid;
GEN_PROCESS_PROPERTY(process)
@property (nonatomic, copy) NSNumber *ppid;
GEN_PROCESS_PROPERTY(parent)

- (NSString *)shortInfo;
- (NSString *)detailInfo;
- (NSString *)jsonInfo;

- (instancetype)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end

@interface EventFactory : NSObject

+ (nullable Event *)initEvent:(NSString *)eventType;
+ (NSSet *)getAllClasses;

@end

#define DEFINE_DERIVE_EVENT_CLASS_START(CLASS_NAME) \
    @interface CLASS_NAME : Event <NSSecureCoding> \
    - (instancetype)initWithCoder:(NSCoder *)decoder; \
    - (void)encodeWithCoder:(NSCoder *)encode;

#define DEFINE_DERIVE_EVENT_CLASS_END \
    @end

DEFINE_DERIVE_EVENT_CLASS_START(ExecEvent)
GEN_PROCESS_PROPERTY(target)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OpenEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(KextLoadEvent)
@property (nonatomic, copy) NSString *kextIdentifier;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(MmapEvent)
GEN_FILE_PROPERTY(source)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(MprotectEvent)
@property (nonatomic, copy) NSNumber *protection;
@property (nonatomic, copy) NSNumber *address;
@property (nonatomic, copy) NSNumber *size;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(MountEvent)
@property (nonatomic, copy) NSString *mountPath;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *fsType;
@property (nonatomic, copy) NSNumber *ownerUid;
@property (nonatomic, copy) NSNumber *mountFlags;
@property (nonatomic, copy) NSNumber *totalFiles;
@property (nonatomic, copy) NSString *fsID;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(RenameEvent)
GEN_FILE_PROPERTY(source)
@property (nonatomic, copy) NSString *destinationFilePath;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SignalEvent)
@property (nonatomic, copy) NSNumber *signal;
GEN_PROCESS_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(UnlinkEvent)
GEN_FILE_PROPERTY(target)
GEN_FILE_PROPERTY(parentDir)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ForkEvent)
@property (nonatomic, copy) NSNumber *childPid;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(CloseEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(CreateEvent)
@property (nonatomic, copy) NSString *destinationFilePath;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ExchangeDataEvent)
GEN_FILE_PROPERTY(file1)
GEN_FILE_PROPERTY(file2)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ExitEvent)
@property (nonatomic, copy) NSNumber *status;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetTaskEvent)
GEN_PROCESS_PROPERTY(target)
@property (nonatomic, copy) NSString *taskType;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(KextUnloadEvent)
@property (nonatomic, copy) NSString *kextIdentifier;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LinkEvent)
GEN_FILE_PROPERTY(source)
GEN_FILE_PROPERTY(targetDir)
@property (nonatomic, copy) NSString *targetFileName;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(UnmountEvent)
@property (nonatomic, copy) NSString *unmountPath;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *fsType;
@property (nonatomic, copy) NSNumber *ownerUid;
@property (nonatomic, copy) NSNumber *mountFlags;
@property (nonatomic, copy) NSNumber *totalFiles;
@property (nonatomic, copy) NSString *fsID;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(IOKitOpenEvent)
@property (nonatomic, copy) NSNumber *userClientType;
@property (nonatomic, copy) NSString *userClientClass;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetAttrlistEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSNumber *bitmapCount;
@property (nonatomic, copy) NSNumber *commonAttr;
@property (nonatomic, copy) NSNumber *volAttr;
@property (nonatomic, copy) NSNumber *dirAttr;
@property (nonatomic, copy) NSNumber *fileAttr;
@property (nonatomic, copy) NSNumber *forkAttr;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetExtAttrEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSString *extAttr;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetFlagsEvent)
@property (nonatomic, copy) NSNumber *flags;
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetModeEvent)
@property (nonatomic, copy) NSNumber *mode;
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetOwnerEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSNumber *uid;
@property (nonatomic, copy) NSNumber *gid;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(WriteEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(FileProviderMaterializeEvent)
GEN_PROCESS_PROPERTY(instigator)
GEN_FILE_PROPERTY(source)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(FileProviderUpdateEvent)
GEN_FILE_PROPERTY(source)
@property (nonatomic, copy) NSString *targetFilePath;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ReadlinkEvent)
GEN_FILE_PROPERTY(source)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(TruncateEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LookupEvent)
GEN_FILE_PROPERTY(sourceDir)
@property (nonatomic, copy) NSString *relativeTargetFilePath;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ChdirEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetAttrlistEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSNumber *bitmapCount;
@property (nonatomic, copy) NSNumber *commonAttr;
@property (nonatomic, copy) NSNumber *volAttr;
@property (nonatomic, copy) NSNumber *dirAttr;
@property (nonatomic, copy) NSNumber *fileAttr;
@property (nonatomic, copy) NSNumber *forkAttr;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(StatEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(AccessEvent)
@property (nonatomic, copy) NSNumber *mode;
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ChrootEvent)
GEN_FILE_PROPERTY(target)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(UtimesEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSNumber *aTime;
@property (nonatomic, copy) NSNumber *mTime;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(CloneEvent)
GEN_FILE_PROPERTY(source)
GEN_FILE_PROPERTY(targetDir)
@property (nonatomic, copy) NSString *targetFileName;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(FcntlEvent)
GEN_FILE_PROPERTY(target)
@property (nonatomic, copy) NSNumber *fcntlCmd;
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetExtAttrEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ListExtAttrEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ReaddirEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(DeleteExtAttrEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(FsGetPathEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(DupEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetTimeEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(UipcBindEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(UipcConnectEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetAclEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(PtyGrantEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(PtyCloseEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ProcCheckEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SearchFsEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ProcSuspendResumeEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(CsInvalidatedEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetTaskNameEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(TraceEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(RemoteThreadCreateEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(RemountEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetTaskReadEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(GetTaskInspectEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetUidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetGidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetEuidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetEgidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetReuidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SetRegidEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(CopyFileEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(AuthenticationEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(XpMalwareDetectedEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(XpMalwareRemediatedEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LwSessionLoginEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LwSessionLogoutEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LwSessionLockEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LwSessionUnlockEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ScreensharingAttachEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ScreensharingDetachEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OpensshLoginEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OpensshLogoutEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LoginLoginEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(LoginLogoutEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(BtmLaunchItemAddEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(BtmLaunchItemRemoveEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ProfileAddEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(ProfileRemoveEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SuEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(AuthorizationPetitionEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(AuthorizationJudgementEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(SudoEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdGroupAddEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdGroupRemoveEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdGroupSetEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdModifyPasswordEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdDisableUserEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdEnableUserEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdAttributeValueAddEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdAttributeValueRemoveEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdAttributeSetEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdCreateUserEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdCreateGroupEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdDeleteUserEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(OdDeleteGroupEvent)
DEFINE_DERIVE_EVENT_CLASS_END

DEFINE_DERIVE_EVENT_CLASS_START(XpcConnectEvent)
DEFINE_DERIVE_EVENT_CLASS_END

NS_ASSUME_NONNULL_END
