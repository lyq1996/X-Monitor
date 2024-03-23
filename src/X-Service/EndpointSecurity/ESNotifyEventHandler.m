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

#define FILL_FILE_INFO(DICTIONARY, TARGET) \
    [DICTIONARY setValue:@(TARGET->stat.st_uid) forKey:@"FileUID"]; \
    [DICTIONARY setValue:@(TARGET->stat.st_gid) forKey:@"FileGID"]; \
    [DICTIONARY setValue:@(TARGET->stat.st_mode) forKey:@"FileMode"]; \
    [DICTIONARY setValue:@(TARGET->stat.st_atimespec.tv_sec) forKey:@"FileAccessTime"]; \
    [DICTIONARY setValue:@(TARGET->stat.st_mtimespec.tv_sec) forKey:@"FileModifyTime"]; \
    [DICTIONARY setValue:@(TARGET->stat.st_ctimespec.tv_sec) forKey:@"FileCreateTime"]; \
    [DICTIONARY setValue:[NSString stringWithUTF8String:[self getString:TARGET->path]] forKey:@"FilePath"];

#define FILL_PROCESS_INFO(DICTIONARY, TARGET) \
    [DICTIONARY setValue:@(audit_token_to_pid(TARGET->audit_token)) forKey:@"Pid"]; \
    [DICTIONARY setValue:@(TARGET->start_time.tv_sec) forKey:@"ProcessCreateTime"]; \
    [DICTIONARY setValue:[NSString stringWithUTF8String:[self getString:TARGET->executable->path]] forKey:@"ProcessPath"]; \
    [DICTIONARY setValue:@(TARGET->codesigning_flags) forKey:@"ProcessCodesignFlag"]; \
    [DICTIONARY setValue:[NSString stringWithUTF8String:[self getString:TARGET->signing_id]] forKey:@"ProcessSigningID"]; \
    [DICTIONARY setValue:[NSString stringWithUTF8String:[self getString:TARGET->team_id]] forKey:@"ProcessTeamID"];

@implementation BaseEventHandler

- (const char *)getString:(const es_string_token_t)token {
    if (token.length > 0) {
        return token.data;
    }
    return "";
}

- (void)handleCommonEvent:(const es_message_t *)msg withEvent:(Event *)event {
    event.EventIdentify = @((uint64_t)msg);
    event.EventType = ESEvents[msg->event_type].eventName;
    event.EventTime = @(msg->time.tv_sec);
    
    NSMutableDictionary *processInfo = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(processInfo, msg->process)
    event.EventProcess = processInfo;

    NSMutableDictionary *parentProcessInfo = [NSMutableDictionary dictionary];
    [parentProcessInfo setValue:@(msg->process->ppid) forKey:@"Pid"];
    event.EventParentProcess = parentProcessInfo;
    return;
}

- (Event *)handleEvent:(const es_message_t *)msg {
    // should override
    Event *event = [[Event alloc] init];
    [self handleCommonEvent:msg withEvent:event];
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXEC

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetProcessInfo = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(targetProcessInfo, msg->event.exec.target)

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
    [targetProcessInfo setValue:cmdline forKey:@"ProcessCmdline"];
    [eventInfo setValue:targetProcessInfo forKey:@"TargetProcess"];
    
    NSMutableDictionary *targetFileInfo = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFileInfo, msg->event.exec.target->executable)
    [eventInfo setValue:targetFileInfo forKey:@"TargetFileInfo"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_OPEN

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFileInfo = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFileInfo, msg->event.open.file)
    [eventInfo setValue:targetFileInfo forKey:@"TargetFileInfo"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FORK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:@(audit_token_to_pid(msg->event.fork.child->audit_token)) forKey:@"ChildPid"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CLOSE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:[NSString stringWithUTF8String:[super getString:msg->event.close.target->path]] forKey:@"TargetFilePath"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CREATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableString *destination = [NSMutableString stringWithUTF8String:[self getString:msg->event.create.destination.new_path.dir->path]];
    [destination appendString:[NSString stringWithUTF8String:[self getString:msg->event.create.destination.new_path.filename]]];
    [eventInfo setValue:destination forKey:@"TargetFilePath"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *file1Info = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(file1Info, msg->event.exchangedata.file1)
    [eventInfo setValue:file1Info forKey:@"File1"];
    
    NSMutableDictionary *file2Info = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(file2Info, msg->event.exchangedata.file2)
    [eventInfo setValue:file2Info forKey:@"File1"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_EXIT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:@(msg->event.exit.stat) forKey:@"Status"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GET_TASK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetProcessInfo = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(targetProcessInfo, msg->event.get_task.target)
    [eventInfo setValue:targetProcessInfo forKey:@"TargetProcess"];

    if (msg->version >= 5) {
        switch (msg->event.get_task.type) {
            case ES_GET_TASK_TYPE_TASK_FOR_PID:
                [eventInfo setValue:@"ES_GET_TASK_TYPE_TASK_FOR_PID" forKey:@"TaskType"];
                break;
            
            case ES_GET_TASK_TYPE_EXPOSE_TASK:
                [eventInfo setValue:@"ES_GET_TASK_TYPE_EXPOSE_TASK" forKey:@"TaskType"];
                break;
            
            case ES_GET_TASK_TYPE_IDENTITY_TOKEN:
                [eventInfo setValue:@"ES_GET_TASK_TYPE_IDENTITY_TOKEN" forKey:@"TaskType"];
                break;
                
            default:
                [eventInfo setValue:@"" forKey:@"TaskType"];
                break;
        }
    }
    else {
        [eventInfo setValue:@"" forKey:@"TaskType"];
    }
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_KEXTLOAD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.kextload.identifier]] forKey:@"KextIdentifier"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_KEXTUNLOAD

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.kextunload.identifier]] forKey:@"KextIdentifier"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LINK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.link.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];
    
    NSMutableDictionary *targetDir = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetDir, msg->event.link.target_dir)
    [eventInfo setValue:targetDir forKey:@"TargetDirectory"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.link.target_filename]] forKey:@"TargetFileName"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MMAP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.mmap.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MPROTECT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:@(msg->event.mprotect.protection) forKey:@"Protection"];
    [eventInfo setValue:@(msg->event.mprotect.address) forKey:@"Address"];
    [eventInfo setValue:@(msg->event.mprotect.size) forKey:@"Size"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_MOUNT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:[NSString stringWithFormat:@"%d %d", msg->event.mount.statfs->f_fsid.val[0], msg->event.mount.statfs->f_fsid.val[1]] forKey:@"FileSystemID"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.mount.statfs->f_fstypename] forKey:@"FileSystemType"];
    [eventInfo setValue:@(msg->event.mount.statfs->f_owner) forKey:@"OwnerUID"];
    [eventInfo setValue:@(msg->event.mount.statfs->f_flags) forKey:@"MountFlags"];
    [eventInfo setValue:@(msg->event.mount.statfs->f_files) forKey:@"TotalFiles"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.mount.statfs->f_mntonname] forKey:@"MountPath"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.mount.statfs->f_mntfromname] forKey:@"SourcePath"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UNMOUNT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:[NSString stringWithFormat:@"%d %d", msg->event.unmount.statfs->f_fsid.val[0], msg->event.mount.statfs->f_fsid.val[1]] forKey:@"FileSystemID"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.unmount.statfs->f_fstypename] forKey:@"FileSystemType"];
    [eventInfo setValue:@(msg->event.unmount.statfs->f_owner) forKey:@"OwnerUID"];
    [eventInfo setValue:@(msg->event.unmount.statfs->f_flags) forKey:@"MountFlags"];
    [eventInfo setValue:@(msg->event.unmount.statfs->f_files) forKey:@"TotalFiles"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.unmount.statfs->f_mntonname] forKey:@"MountPath"];
    [eventInfo setValue:[NSString stringWithUTF8String:msg->event.unmount.statfs->f_mntfromname] forKey:@"SourcePath"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_IOKIT_OPEN

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    [eventInfo setValue:@(msg->event.iokit_open.user_client_type) forKey:@"UserClientType"];
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.iokit_open.user_client_class]] forKey:@"UserClientClass"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_RENAME

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.rename.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];
    
    NSMutableString *destination = [NSMutableString stringWithUTF8String:[self getString:msg->event.rename.destination.new_path.dir->path]];
    [destination appendString:[NSString stringWithUTF8String:[self getString:msg->event.rename.destination.new_path.filename]]];
    [eventInfo setValue:destination forKey:@"TargetFilePath"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETATTRLIST

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setattrlist.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.bitmapcount) forKey:@"BitmapCount"];
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.commonattr) forKey:@"CommonAttr"];
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.volattr) forKey:@"VolAttr"];
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.dirattr) forKey:@"DirAttr"];
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.fileattr) forKey:@"FileAttr"];
    [eventInfo setValue:@(msg->event.setattrlist.attrlist.forkattr) forKey:@"ForkAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setextattr.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.setextattr.extattr]] forKey:@"ExtAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETFLAGS

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setflags.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.setflags.flags) forKey:@"Flags"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETMODE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setmode.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.setmode.mode) forKey:@"Mode"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETOWNER

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setowner.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.setowner.uid) forKey:@"UID"];
    [eventInfo setValue:@(msg->event.setowner.gid) forKey:@"UID"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SIGNAL

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetProcess = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(targetProcess, msg->event.signal.target)
    [eventInfo setValue:targetProcess forKey:@"TargetProcess"];
    
    [eventInfo setValue:@(msg->event.signal.sig) forKey:@"Signal"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UNLINK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.unlink.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    NSMutableDictionary *parentDir = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(parentDir, msg->event.unlink.parent_dir)
    [eventInfo setValue:parentDir forKey:@"ParentDirectory"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_WRITE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.write.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *instigatorProcess = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(instigatorProcess, msg->event.file_provider_materialize.instigator)
    [eventInfo setValue:instigatorProcess forKey:@"InstigatorProcess"];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.file_provider_materialize.source)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.file_provider_materialize.target)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.file_provider_update.target_path]] forKey:@"TargetFilePath"];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.file_provider_update.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_READLINK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.readlink.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_TRUNCATE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.truncate.target)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LOOKUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetDir = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetDir, msg->event.lookup.source_dir)
    [eventInfo setValue:targetDir forKey:@"TargetDirectory"];

    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.lookup.relative_target]] forKey:@"TargetFilePath"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CHDIR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.chdir.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GETATTRLIST

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.getattrlist.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.bitmapcount) forKey:@"BitmapCount"];
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.commonattr) forKey:@"CommonAttr"];
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.volattr) forKey:@"VolAttr"];
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.dirattr) forKey:@"DirAttr"];
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.fileattr) forKey:@"FileAttr"];
    [eventInfo setValue:@(msg->event.getattrlist.attrlist.forkattr) forKey:@"ForkAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_STAT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.stat.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_ACCESS

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.access.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.access.mode) forKey:@"Mode"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CHROOT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.chroot.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UTIMES

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];
    
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.utimes.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.utimes.atime.tv_sec) forKey:@"FileAccessTime"];
    [eventInfo setValue:@(msg->event.utimes.mtime.tv_sec) forKey:@"FileModifyTime"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_CLONE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *sourceFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(sourceFile, msg->event.clone.source)
    [eventInfo setValue:sourceFile forKey:@"SourceFile"];
    
    NSMutableDictionary *targetDir = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetDir, msg->event.clone.target_dir)
    [eventInfo setValue:targetDir forKey:@"TargetDirectory"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.clone.target_name]] forKey:@"TargetFileName"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FCNTL

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.fcntl.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.fcntl.cmd) forKey:@"CMD"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_GETEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.getextattr.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.getextattr.extattr]] forKey:@"ExtAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_LISTEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.listextattr.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_READDIR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.readdir.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.deleteextattr.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.deleteextattr.extattr]] forKey:@"ExtAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_FSGETPATH

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.fsgetpath.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_DUP

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.dup.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    event.EventInfo = eventInfo;
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

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *targetDir = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetDir, msg->event.uipc_bind.dir)
    [eventInfo setValue:targetDir forKey:@"TargetDirectory"];
    
    [eventInfo setValue:[NSString stringWithUTF8String:[self getString:msg->event.uipc_bind.filename]] forKey:@"TargetFileName"];
    [eventInfo setValue:@(msg->event.uipc_bind.mode) forKey:@"Mode"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.uipc_connect.file)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.uipc_connect.domain) forKey:@"Domain"];
    [eventInfo setValue:@(msg->event.uipc_connect.type) forKey:@"Type"];
    [eventInfo setValue:@(msg->event.uipc_connect.protocol) forKey:@"Protocol"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SETACL

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.setacl.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    if (msg->event.setacl.set_or_clear == ES_SET) {
        [eventInfo setValue:@(1) forKey:@"SetOrClear"];
    } else {
        [eventInfo setValue:@(0) forKey:@"SetOrClear"];
    }
    
    acl_t acl = acl_dup(msg->event.setacl.acl.set);
    char *aclStr = acl_to_text(acl, NULL);
    if (aclStr != NULL) {
        [eventInfo setValue:[NSString stringWithUTF8String:aclStr] forKey:@"ACL"];
    }
    
    free(aclStr);
    acl_free(acl);
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PTY_GRANT

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:@(msg->event.pty_grant.dev) forKey:@"Device"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PTY_CLOSE

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    [eventInfo setValue:@(msg->event.pty_close.dev) forKey:@"Device"];
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROC_CHECK

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetProcess = [NSMutableDictionary dictionary];
    if (msg->event.proc_check.target) {
        FILL_PROCESS_INFO(targetProcess, msg->event.proc_check.target)
    }
    [eventInfo setValue:targetProcess forKey:@"TargetProcess"];
    
    [eventInfo setValue:@(msg->event.proc_check.flavor) forKey:@"Flavor"];
    
    switch (msg->event.proc_check.type) {
        case ES_PROC_CHECK_TYPE_LISTPIDS:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_LISTPIDS" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_PIDINFO:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_PIDINFO" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_PIDFDINFO:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_PIDFDINFO" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_KERNMSGBUF:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_KERNMSGBUF" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_SETCONTROL:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_SETCONTROL" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_PIDFILEPORTINFO:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_PIDFILEPORTINFO" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_TERMINATE:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_TERMINATE" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_DIRTYCONTROL:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_DIRTYCONTROL" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_PIDRUSAGE:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_PIDRUSAGE" forKey:@"CheckType"];
            break;
        case ES_PROC_CHECK_TYPE_UDATA_INFO:
            [eventInfo setValue:@"ES_PROC_CHECK_TYPE_UDATA_INFO" forKey:@"CheckType"];
            break;
        default:
            [eventInfo setValue:@"" forKey:@"CheckType"];
            break;
    }
    
    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_SEARCHFS

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetFile = [NSMutableDictionary dictionary];
    FILL_FILE_INFO(targetFile, msg->event.searchfs.target)
    [eventInfo setValue:targetFile forKey:@"TargetFile"];
    
    [eventInfo setValue:@(msg->event.searchfs.attrlist.bitmapcount) forKey:@"BitmapCount"];
    [eventInfo setValue:@(msg->event.searchfs.attrlist.commonattr) forKey:@"CommonAttr"];
    [eventInfo setValue:@(msg->event.searchfs.attrlist.volattr) forKey:@"VolAttr"];
    [eventInfo setValue:@(msg->event.searchfs.attrlist.dirattr) forKey:@"DirAttr"];
    [eventInfo setValue:@(msg->event.searchfs.attrlist.fileattr) forKey:@"FileAttr"];
    [eventInfo setValue:@(msg->event.searchfs.attrlist.forkattr) forKey:@"ForkAttr"];

    event.EventInfo = eventInfo;
    return event;
}

@end

@implementation EventHandler_ES_EVENT_TYPE_NOTIFY_PROC_SUSPEND_RESUME

- (Event *)handleEvent:(const es_message_t *)msg {
    Event *event = [super handleEvent:msg];

    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];

    NSMutableDictionary *targetProcess = [NSMutableDictionary dictionary];
    FILL_PROCESS_INFO(targetProcess, msg->event.proc_suspend_resume.target)
    [eventInfo setValue:targetProcess forKey:@"TargetProcess"];

    switch (msg->event.proc_suspend_resume.type) {
        case ES_PROC_SUSPEND_RESUME_TYPE_SUSPEND:
            [eventInfo setValue:@"ES_PROC_SUSPEND_RESUME_TYPE_SUSPEND" forKey:@"ResumeType"];
            break;
        case ES_PROC_SUSPEND_RESUME_TYPE_RESUME:
            [eventInfo setValue:@"ES_PROC_SUSPEND_RESUME_TYPE_RESUME" forKey:@"ResumeType"];
            break;
        case ES_PROC_SUSPEND_RESUME_TYPE_SHUTDOWN_SOCKETS:
            [eventInfo setValue:@"ES_PROC_SUSPEND_RESUME_TYPE_SHUTDOWN_SOCKETS" forKey:@"ResumeType"];
            break;
        default:
            [eventInfo setValue:@"" forKey:@"ResumeType"];
            break;
    }

    event.EventInfo = eventInfo;
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
