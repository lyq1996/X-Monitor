//
//  ESEventHandler.m
//  X-Service
//
//  Created by lyq1996 on 2023/4/22.
//

#import "ESNotifyEventHandler.h"
#import "ESDefination.h"
#import <bsm/libbsm.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>

extern DDLogLevel ddLogLevel;
extern ESEvent ESEvents[];

#define FILL_EVENT_FILE_INFO(EVENT, PREFIX, TARGET) \
    EVENT.PREFIX##FileUID = @(TARGET->stat.st_uid); \
    EVENT.PREFIX##FileGID = @(TARGET->stat.st_gid); \
    EVENT.PREFIX##FileMode = @(TARGET->stat.st_mode); \
    EVENT.PREFIX##FileAccessTime = @(TARGET->stat.st_atimespec.tv_sec); \
    EVENT.PREFIX##FileModifyTime = @(TARGET->stat.st_mtimespec.tv_sec); \
    EVENT.PREFIX##FileCreateTime = @(TARGET->stat.st_ctimespec.tv_sec); \
    EVENT.PREFIX##FilePath = [NSString stringWithUTF8String:[self getString:TARGET->path]];

#define FILL_EVENT_PROCESS_INFO(EVENT, PREFIX, TARGET) \
    EVENT.PREFIX##CreateTime = @(TARGET->start_time.tv_sec); \
    EVENT.PREFIX##Path = [NSString stringWithUTF8String:[self getString:TARGET->executable->path]]; \
    EVENT.PREFIX##CodesignFlag = @(TARGET->codesigning_flags); \
    EVENT.PREFIX##SigningID = [NSString stringWithUTF8String:[self getString:TARGET->signing_id]]; \
    EVENT.PREFIX##TeamID = [NSString stringWithUTF8String:[self getString:TARGET->team_id]];


@implementation BaseEventHandler

- (const char *)getString:(const es_string_token_t)token {
    if (token.length > 0) {
        return token.data;
    }
    return "";
}

- (void)handleCommonEvent:(const es_message_t *)msg withEvent:(Event *)event {
    event.eventIdentify = @((uint64_t)msg);
    event.eventType = ESEvents[msg->event_type].eventName;
    event.eventTime = @(msg->time.tv_sec);
    event.pid = @(audit_token_to_pid(msg->process->audit_token));
    
    FILL_EVENT_PROCESS_INFO(event, process, msg->process)

    event.ppid = @(msg->process->ppid);
    return;
}

- (Event *)handleEvent:(const es_message_t *)msg {
    // should override
    Event *event = [EventFactory initEvent:ESEvents[msg->event_type].eventName];
    [self handleCommonEvent:msg withEvent:event];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXEC

- (Event *)handleEvent:(const es_message_t *)msg {
    ExecEvent *event = (ExecEvent *)[super handleEvent:msg];
    
    FILL_EVENT_FILE_INFO(event, target, msg->event.exec.target->executable)
    FILL_EVENT_PROCESS_INFO(event, target, msg->event.exec.target)
    
    NSString *cmdline = [NSString string];
    int argv_count = es_exec_arg_count(&msg->event.exec);
    for(int i=0; i<argv_count; ++i) {
        es_string_token_t argv_token = es_exec_arg(&msg->event.exec, i);
        NSString *argv = [NSString stringWithUTF8String:[self getString:argv_token]];
        cmdline = [cmdline stringByAppendingString:argv];
        if (i != argv_count - 1) {
            cmdline = [cmdline stringByAppendingString:@" "];
        }
    }
    event.targetCmdline = cmdline;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OPEN

- (Event *)handleEvent:(const es_message_t *)msg {
    OpenEvent *event = (OpenEvent *)[super handleEvent:msg];
    
    FILL_EVENT_FILE_INFO(event, target, msg->event.open.file)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FORK

- (Event *)handleEvent:(const es_message_t *)msg {
    ForkEvent *event = (ForkEvent *)[super handleEvent:msg];
    
    event.childPid = @(audit_token_to_pid(msg->event.fork.child->audit_token));
    
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CLOSE

- (Event *)handleEvent:(const es_message_t *)msg {
    CloseEvent *event = (CloseEvent *)[super handleEvent:msg];
    event.targetFilePath = [NSString stringWithUTF8String:[super getString:msg->event.close.target->path]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CREATE

- (Event *)handleEvent:(const es_message_t *)msg {
    CreateEvent *event = (CreateEvent *)[super handleEvent:msg];
    
    NSMutableString *destination = [NSMutableString stringWithUTF8String:[self getString:msg->event.create.destination.new_path.dir->path]];
    [destination appendString:[NSString stringWithUTF8String:[self getString:msg->event.create.destination.new_path.filename]]];
    event.destinationFilePath = destination;
    
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA

- (Event *)handleEvent:(const es_message_t *)msg {
    ExchangeDataEvent *event = (ExchangeDataEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, file1, msg->event.exchangedata.file1)
    FILL_EVENT_FILE_INFO(event, file2, msg->event.exchangedata.file2)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXIT

- (Event *)handleEvent:(const es_message_t *)msg {
    ExitEvent *event = (ExitEvent *)[super handleEvent:msg];

    event.status = @(msg->event.exit.stat);
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GET_TASK

- (Event *)handleEvent:(const es_message_t *)msg {
    GetTaskEvent *event = (GetTaskEvent *)[super handleEvent:msg];
    FILL_EVENT_PROCESS_INFO(event, target, msg->event.get_task.target)
    if (msg->version >= 5) {
        switch (msg->event.get_task.type) {
            case ES_GET_TASK_TYPE_TASK_FOR_PID:
                event.taskType = @"ES_GET_TASK_TYPE_TASK_FOR_PID";
                break;
            
            case ES_GET_TASK_TYPE_EXPOSE_TASK:
                event.taskType = @"ES_GET_TASK_TYPE_EXPOSE_TASK";
                break;
            
            case ES_GET_TASK_TYPE_IDENTITY_TOKEN:
                event.taskType = @"ES_GET_TASK_TYPE_IDENTITY_TOKEN";
                break;
                
            default:
                event.taskType = @"";
                break;
        }
    }
    else {
        event.taskType = @"";
    }
    
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_KEXTLOAD

- (Event *)handleEvent:(const es_message_t *)msg {
    KextLoadEvent *event = (KextLoadEvent *)[super handleEvent:msg];
    event.kextIdentifier = [NSString stringWithUTF8String:[self getString:msg->event.kextload.identifier]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_KEXTUNLOAD

- (Event *)handleEvent:(const es_message_t *)msg {
    KextUnloadEvent *event = (KextUnloadEvent *)[super handleEvent:msg];
    event.kextIdentifier = [NSString stringWithUTF8String:[self getString:msg->event.kextload.identifier]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LINK

- (Event *)handleEvent:(const es_message_t *)msg {
    LinkEvent *event = (LinkEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, source, msg->event.link.source)
    FILL_EVENT_FILE_INFO(event, targetDir, msg->event.link.target_dir)
    event.targetFileName = [NSString stringWithUTF8String:[self getString:msg->event.link.target_filename]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MMAP

- (Event *)handleEvent:(const es_message_t *)msg {
    MmapEvent *event = (MmapEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, source, msg->event.mmap.source)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MPROTECT

- (Event *)handleEvent:(const es_message_t *)msg {
    MprotectEvent *event = (MprotectEvent *)[super handleEvent:msg];
    event.protection = [NSNumber numberWithInt:msg->event.mprotect.protection];
    event.address = [NSNumber numberWithUnsignedLongLong:msg->event.mprotect.address];
    event.size = [NSNumber numberWithUnsignedLongLong:msg->event.mprotect.size];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MOUNT

- (Event *)handleEvent:(const es_message_t *)msg {
    MountEvent *event = (MountEvent *)[super handleEvent:msg];
    event.fsID = [NSString stringWithFormat:@"%d %d", msg->event.mount.statfs->f_fsid.val[0], msg->event.mount.statfs->f_fsid.val[1]];
    event.fsType = [NSString stringWithUTF8String:msg->event.mount.statfs->f_fstypename];
    event.ownerUid = [NSNumber numberWithUnsignedInt:msg->event.mount.statfs->f_owner];
    event.mountFlags = [NSNumber numberWithUnsignedInt:msg->event.mount.statfs->f_flags];
    event.totalFiles = [NSNumber numberWithUnsignedLongLong:msg->event.mount.statfs->f_files];
    event.mountPath = [NSString stringWithUTF8String:msg->event.mount.statfs->f_mntonname];
    event.sourcePath = [NSString stringWithUTF8String:msg->event.mount.statfs->f_mntfromname];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UNMOUNT

- (Event *)handleEvent:(const es_message_t *)msg {
    UnmountEvent *event = (UnmountEvent *)[super handleEvent:msg];
    event.fsID = [NSString stringWithFormat:@"%d %d", msg->event.mount.statfs->f_fsid.val[0], msg->event.unmount.statfs->f_fsid.val[1]];
    event.fsType = [NSString stringWithUTF8String:msg->event.unmount.statfs->f_fstypename];
    event.ownerUid = [NSNumber numberWithUnsignedInt:msg->event.unmount.statfs->f_owner];
    event.mountFlags = [NSNumber numberWithUnsignedInt:msg->event.unmount.statfs->f_flags];
    event.totalFiles = [NSNumber numberWithUnsignedLongLong:msg->event.unmount.statfs->f_files];
    event.unmountPath = [NSString stringWithUTF8String:msg->event.unmount.statfs->f_mntonname];
    event.sourcePath = [NSString stringWithUTF8String:msg->event.unmount.statfs->f_mntfromname];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_IOKIT_OPEN

- (Event *)handleEvent:(const es_message_t *)msg {
    IOKitOpenEvent *event = (IOKitOpenEvent *)[super handleEvent:msg];
    event.userClientType = [NSNumber numberWithInt:msg->event.iokit_open.user_client_type];
    event.userClientClass = [NSString stringWithUTF8String:[self getString:msg->event.iokit_open.user_client_class]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_RENAME

- (Event *)handleEvent:(const es_message_t *)msg {
    RenameEvent *event = (RenameEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, source, msg->event.rename.source)
    
    NSMutableString *destination = [NSMutableString stringWithUTF8String:[self getString:msg->event.rename.destination.new_path.dir->path]];
    [destination appendString:[NSString stringWithUTF8String:[self getString:msg->event.rename.destination.new_path.filename]]];
    
    event.destinationFilePath = destination;
    
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETATTRLIST

- (Event *)handleEvent:(const es_message_t *)msg {
    SetAttrlistEvent *event = (SetAttrlistEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.setattrlist.target)
    event.bitmapCount = [NSNumber numberWithShort:msg->event.setattrlist.attrlist.bitmapcount];
    event.commonAttr = [NSNumber numberWithInt:msg->event.setattrlist.attrlist.commonattr];
    event.volAttr = [NSNumber numberWithInt:msg->event.setattrlist.attrlist.volattr];
    event.dirAttr = [NSNumber numberWithInt:msg->event.setattrlist.attrlist.dirattr];
    event.fileAttr = [NSNumber numberWithInt:msg->event.setattrlist.attrlist.fileattr];
    event.forkAttr = [NSNumber numberWithInt:msg->event.setattrlist.attrlist.forkattr];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    SetExtAttrEvent *event = (SetExtAttrEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.setextattr.target)
    event.extAttr = [NSString stringWithUTF8String:[self getString:msg->event.setextattr.extattr]];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETFLAGS

- (Event *)handleEvent:(const es_message_t *)msg {
    SetFlagsEvent *event = (SetFlagsEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.setflags.target)
    event.flags = [NSNumber numberWithInt:msg->event.setflags.flags];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETMODE

- (Event *)handleEvent:(const es_message_t *)msg {
    SetModeEvent *event = (SetModeEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.setmode.target)
    event.mode = [NSNumber numberWithInt:msg->event.setmode.mode];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETOWNER

- (Event *)handleEvent:(const es_message_t *)msg {
    SetOwnerEvent *event = (SetOwnerEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.setowner.target)
    event.uid = [NSNumber numberWithInt:msg->event.setowner.uid];
    event.gid = [NSNumber numberWithInt:msg->event.setowner.gid];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SIGNAL

- (Event *)handleEvent:(const es_message_t *)msg {
    SignalEvent *event = (SignalEvent *)[super handleEvent:msg];
    event.signal = [NSNumber numberWithInt:msg->event.signal.sig];
    FILL_EVENT_PROCESS_INFO(event, target, msg->event.signal.target)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UNLINK

- (Event *)handleEvent:(const es_message_t *)msg {
    UnlinkEvent *event = (UnlinkEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.unlink.target)
    FILL_EVENT_FILE_INFO(event, parentDir, msg->event.unlink.parent_dir)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_WRITE

- (Event *)handleEvent:(const es_message_t *)msg {
    WriteEvent *event = (WriteEvent *)[super handleEvent:msg];
    FILL_EVENT_FILE_INFO(event, target, msg->event.write.target)
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_READLINK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_TRUNCATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LOOKUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CHDIR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GETATTRLIST

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_STAT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_ACCESS

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CHROOT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UTIMES

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CLONE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FCNTL

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GETEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LISTEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_READDIR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FSGETPATH

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_DUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETTIME

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UIPC_BIND

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETACL

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PTY_GRANT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PTY_CLOSE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROC_CHECK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SEARCHFS

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROC_SUSPEND_RESUME

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CS_INVALIDATED

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GET_TASK_NAME

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_TRACE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_REMOTE_THREAD_CREATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_REMOUNT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GET_TASK_READ

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GET_TASK_INSPECT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETUID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETGID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETEUID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETEGID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETREUID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETREGID

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_COPYFILE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_AUTHENTICATION

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_XP_MALWARE_DETECTED

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_XP_MALWARE_REMEDIATED

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGIN

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGOUT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOCK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LW_SESSION_UNLOCK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SCREENSHARING_ATTACH

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SCREENSHARING_DETACH

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGIN

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGOUT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LOGIN_LOGIN

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LOGIN_LOGOUT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_ADD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_REMOVE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROFILE_ADD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROFILE_REMOVE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SU

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_PETITION

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_JUDGEMENT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SUDO

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_GROUP_ADD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_GROUP_REMOVE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_GROUP_SET

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_MODIFY_PASSWORD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_DISABLE_USER

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_ENABLE_USER

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_ADD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_REMOVE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_SET

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_CREATE_USER

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_CREATE_GROUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_DELETE_USER

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OD_DELETE_GROUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_XPC_CONNECT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    return event;
}

@end
