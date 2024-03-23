//
//  ESDefination.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/7.
//

#ifndef ESDefination_h
#define ESDefination_h
#import "ESNotifyEventHandler.h"

#define kESProducerNotifyQueue      "com.lyq1996.X-Service.ESnotifyQueue"
#define kESProducerName             @"Endpoint Security Producer";

typedef struct {
    // event type
    NSString *eventName;
    // is auth event
    BOOL isAuthEvent;
    // event handler create block
    BaseEventHandler *(^createEventHandle)(es_client_t *, const es_message_t *);
} ESEvent;


#define GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE) \
    ^(es_client_t *client, const es_message_t *event) { \
        return [[EventHandler_##ES_EVENT_TYPE alloc] init]; \
    }

// Place this variable in to the "__DATA_CONST, __const" section
// to avoid multiple definations of ESEvents across difference source files.
__attribute__((section("__DATA_CONST, __const"))) static const ESEvent ESEvents[] = {
    [ES_EVENT_TYPE_AUTH_EXEC] = {
        @"auth_exec",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_OPEN] = {
        @"auth_open",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_KEXTLOAD] = {
        @"auth_kextload",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_MMAP] = {
        @"auth_mmap",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_MPROTECT] = {
        @"auth_mprotect",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_MOUNT] = {
        @"auth_mount",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_RENAME] = {
        @"auth_rename",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SIGNAL] = {
        @"auth_signal",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_UNLINK] = {
        @"auth_unlink",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_EXEC] = {
        @"notify_exec",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_EXEC),
    },
    [ES_EVENT_TYPE_NOTIFY_OPEN] = {
        @"notify_open",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OPEN),
    },
    [ES_EVENT_TYPE_NOTIFY_FORK] = {
        @"notify_fork",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FORK),
    },
    [ES_EVENT_TYPE_NOTIFY_CLOSE] = {
        @"notify_close",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CLOSE),
    },
    [ES_EVENT_TYPE_NOTIFY_CREATE] = {
        @"notify_create",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CREATE),
    },
    [ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA] = {
        @"notify_exchangedata",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA),
    },
    [ES_EVENT_TYPE_NOTIFY_EXIT] = {
        @"notify_exit",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_EXIT),
    },
    [ES_EVENT_TYPE_NOTIFY_GET_TASK] = {
        @"notify_get_task",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GET_TASK),
    },
    [ES_EVENT_TYPE_NOTIFY_KEXTLOAD] = {
        @"notify_kextload",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_KEXTLOAD),
    },
    [ES_EVENT_TYPE_NOTIFY_KEXTUNLOAD] = {
        @"notify_kextunload",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_KEXTUNLOAD),
    },
    [ES_EVENT_TYPE_NOTIFY_LINK] = {
        @"notify_link",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LINK),
    },
    [ES_EVENT_TYPE_NOTIFY_MMAP] = {
        @"notify_mmap",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_MMAP),
    },
    [ES_EVENT_TYPE_NOTIFY_MPROTECT] = {
        @"notify_mprotect",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_MPROTECT),
    },
    [ES_EVENT_TYPE_NOTIFY_MOUNT] = {
        @"notify_mount",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_MOUNT),
    },
    [ES_EVENT_TYPE_NOTIFY_UNMOUNT] = {
        @"notify_unmount",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UNMOUNT),
    },
    [ES_EVENT_TYPE_NOTIFY_IOKIT_OPEN] = {
        @"notify_iokit_open",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_IOKIT_OPEN),
    },
    [ES_EVENT_TYPE_NOTIFY_RENAME] = {
        @"notify_rename",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_RENAME),
    },
    [ES_EVENT_TYPE_NOTIFY_SETATTRLIST] = {
        @"notify_setattrlist",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETATTRLIST),
    },
    [ES_EVENT_TYPE_NOTIFY_SETEXTATTR] = {
        @"notify_setextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETEXTATTR),
    },
    [ES_EVENT_TYPE_NOTIFY_SETFLAGS] = {
        @"notify_setflags",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETFLAGS),
    },
    [ES_EVENT_TYPE_NOTIFY_SETMODE] = {
        @"notify_setmode",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETMODE),
    },
    [ES_EVENT_TYPE_NOTIFY_SETOWNER] = {
        @"notify_setowner",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETOWNER),
    },
    [ES_EVENT_TYPE_NOTIFY_SIGNAL] = {
        @"notify_signal",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SIGNAL),
    },
    [ES_EVENT_TYPE_NOTIFY_UNLINK] = {
        @"notify_unlink",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UNLINK),
    },
    [ES_EVENT_TYPE_NOTIFY_WRITE] = {
        @"notify_write",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_WRITE),
    },
    [ES_EVENT_TYPE_AUTH_FILE_PROVIDER_MATERIALIZE] = {
        @"auth_file_provider_materialize",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE] = {
        @"notify_file_provider_materialize",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE),
    },
    [ES_EVENT_TYPE_AUTH_FILE_PROVIDER_UPDATE] = {
        @"auth_file_provider_update",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE] = {
        @"notify_file_provider_update",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE),
    },
    [ES_EVENT_TYPE_AUTH_READLINK] = {
        @"auth_readlink",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_READLINK] = {
        @"notify_readlink",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_READLINK),
    },
    [ES_EVENT_TYPE_AUTH_TRUNCATE] = {
        @"auth_truncate",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_TRUNCATE] = {
        @"notify_truncate",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_TRUNCATE),
    },
    [ES_EVENT_TYPE_AUTH_LINK] = {
        @"auth_link",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_LOOKUP] = {
        @"notify_lookup",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LOOKUP),
    },
    [ES_EVENT_TYPE_AUTH_CREATE] = {
        @"auth_create",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SETATTRLIST] = {
        @"auth_setattrlist",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SETEXTATTR] = {
        @"auth_setextattr",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SETFLAGS] = {
        @"auth_setflags",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SETMODE] = {
        @"auth_setmode",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SETOWNER] = {
        @"auth_setowner",
        YES,
        NULL,
    },
    // The following events are available beginning in macOS 10.15.1
    [ES_EVENT_TYPE_AUTH_CHDIR] = {
        @"auth_chdir",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_CHDIR] = {
        @"notify_chdir",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CHDIR),
    },
    [ES_EVENT_TYPE_AUTH_GETATTRLIST] = {
        @"auth_getattrlist",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_GETATTRLIST] = {
        @"notify_getattrlist",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GETATTRLIST),
    },
    [ES_EVENT_TYPE_NOTIFY_STAT] = {
        @"notify_stat",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_STAT),
    },
    [ES_EVENT_TYPE_NOTIFY_ACCESS] = {
        @"notify_access",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_ACCESS),
    },
    [ES_EVENT_TYPE_AUTH_CHROOT] = {
        @"auth_chroot",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_CHROOT] = {
        @"notify_chroot",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CHROOT),
    },
    [ES_EVENT_TYPE_AUTH_UTIMES] = {
        @"auth_utimes",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_UTIMES] = {
        @"notify_utimes",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UTIMES),
    },
    [ES_EVENT_TYPE_AUTH_CLONE] = {
        @"auth_clone",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_CLONE] = {
        @"notify_clone",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CLONE),
    },
    [ES_EVENT_TYPE_NOTIFY_FCNTL] = {
        @"notify_fcntl",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FCNTL),
    },
    [ES_EVENT_TYPE_AUTH_GETEXTATTR] = {
        @"auth_getextattr",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_GETEXTATTR] = {
        @"notify_getextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GETEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_LISTEXTATTR] = {
        @"auth_listextattr",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_LISTEXTATTR] = {
        @"notify_listextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LISTEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_READDIR] = {
        @"auth_readdir",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_READDIR] = {
        @"notify_readdir",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_READDIR),
    },
    [ES_EVENT_TYPE_AUTH_DELETEEXTATTR] = {
        @"auth_deleteextattr",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR] = {
        @"notify_deleteextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_FSGETPATH] = {
        @"auth_fsgetpath",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_FSGETPATH] = {
        @"notify_fsgetpath",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FSGETPATH),
    },
    [ES_EVENT_TYPE_NOTIFY_DUP] = {
        @"notify_dup",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_DUP),
    },
    [ES_EVENT_TYPE_AUTH_SETTIME] = {
        @"auth_settime",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_SETTIME] = {
        @"notify_settime",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETTIME),
    },
    [ES_EVENT_TYPE_NOTIFY_UIPC_BIND] = {
        @"notify_uipc_bind",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UIPC_BIND),
    },
    [ES_EVENT_TYPE_AUTH_UIPC_BIND] = {
        @"auth_uipc_bind",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT] = {
        @"notify_uipc_connect",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT),
    },
    [ES_EVENT_TYPE_AUTH_UIPC_CONNECT] = {
        @"auth_uipc_connect",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_EXCHANGEDATA] = {
        @"auth_exchangedata",
        YES,
        NULL,
    },
    // The following events are available beginning in macOS 10.15.4
    [ES_EVENT_TYPE_AUTH_SETACL] = {
        @"auth_setacl",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_SETACL] = {
        @"notify_setacl",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETACL),
    },
    [ES_EVENT_TYPE_NOTIFY_PTY_GRANT] = {
        @"notify_pty_grant",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PTY_GRANT),
    },
    [ES_EVENT_TYPE_NOTIFY_PTY_CLOSE] = {
        @"notify_pty_close",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PTY_CLOSE),
    },
    [ES_EVENT_TYPE_AUTH_PROC_CHECK] = {
        @"auth_proc_check",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_PROC_CHECK] = {
        @"notify_proc_check",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PROC_CHECK),
    },
    [ES_EVENT_TYPE_AUTH_GET_TASK] = {
        @"auth_get_task",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_SEARCHFS] = {
        @"auth_searchfs",
        YES,
        NULL,
    },
    // The following events are available beginning in macOS 11.0
    [ES_EVENT_TYPE_NOTIFY_SEARCHFS] = {
        @"notify_searchfs",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SEARCHFS),
    },
    [ES_EVENT_TYPE_AUTH_FCNTL] = {
        @"auth_fcntl",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_IOKIT_OPEN] = {
        @"auth_iokit_open",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_AUTH_PROC_SUSPEND_RESUME] = {
        @"auth_proc_suspend_resume",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_PROC_SUSPEND_RESUME] = {
        @"notify_proc_suspend_resume",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PROC_SUSPEND_RESUME),
    },
    [ES_EVENT_TYPE_NOTIFY_CS_INVALIDATED] = {
        @"notify_cs_invalidated",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CS_INVALIDATED),
    },
    [ES_EVENT_TYPE_NOTIFY_GET_TASK_NAME] = {
        @"notify_get_task_name",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GET_TASK_NAME),
    },
    [ES_EVENT_TYPE_NOTIFY_TRACE] = {
        @"notify_trace",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_TRACE),
    },
    [ES_EVENT_TYPE_NOTIFY_REMOTE_THREAD_CREATE] = {
        @"notify_remote_thread_create",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_REMOTE_THREAD_CREATE),
    },
    [ES_EVENT_TYPE_AUTH_REMOUNT] = {
        @"auth_remount",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_REMOUNT] = {
        @"notify_remount",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_REMOUNT),
    },
    [ES_EVENT_TYPE_AUTH_GET_TASK_READ] = {
        @"auth_get_task_read",
        YES,
        NULL,
    },
    // The following events are available beginning in macOS 11.3
    [ES_EVENT_TYPE_NOTIFY_GET_TASK_READ] = {
        @"notify_get_task_read",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GET_TASK_READ),
    },
    [ES_EVENT_TYPE_NOTIFY_GET_TASK_INSPECT] = {
        @"notify_get_task_inspect",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GET_TASK_INSPECT),
    },
    // The following events are available beginning in macOS 12.0
    [ES_EVENT_TYPE_NOTIFY_SETUID] = {
        @"notify_setuid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETUID),
    },
    [ES_EVENT_TYPE_NOTIFY_SETGID] = {
        @"notify_setgid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETGID),
    },
    [ES_EVENT_TYPE_NOTIFY_SETEUID] = {
        @"notify_seteuid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETEUID),
    },
    [ES_EVENT_TYPE_NOTIFY_SETEGID] = {
        @"notify_setegid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETEGID),
    },
    [ES_EVENT_TYPE_NOTIFY_SETREUID] = {
        @"notify_setreuid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETREUID),
    },
    [ES_EVENT_TYPE_NOTIFY_SETREGID] = {
        @"notify_setregid",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SETREGID),
    },
    [ES_EVENT_TYPE_AUTH_COPYFILE] = {
        @"auth_copyfile",
        YES,
        NULL,
    },
    [ES_EVENT_TYPE_NOTIFY_COPYFILE] = {
        @"notify_copyfile",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_COPYFILE),
    },
    // The following events are available beginning in macOS 13.0
    [ES_EVENT_TYPE_NOTIFY_AUTHENTICATION] = {
        @"notify_authentication",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_AUTHENTICATION),
    },
    [ES_EVENT_TYPE_NOTIFY_XP_MALWARE_DETECTED] = {
        @"notify_xp_malware_detected",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_XP_MALWARE_DETECTED),
    },
    [ES_EVENT_TYPE_NOTIFY_XP_MALWARE_REMEDIATED] = {
        @"notify_xp_malware_remediated",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_XP_MALWARE_REMEDIATED),
    },
    [ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGIN] = {
        @"notify_lw_session_login",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGIN),
    },
    [ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGOUT] = {
        @"notify_lw_session_logout",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOGOUT),
    },
    [ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOCK] = {
        @"notify_lw_session_lock",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LW_SESSION_LOCK),
    },
    [ES_EVENT_TYPE_NOTIFY_LW_SESSION_UNLOCK] = {
        @"notify_lw_session_unlock",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LW_SESSION_UNLOCK),
    },
    [ES_EVENT_TYPE_NOTIFY_SCREENSHARING_ATTACH] = {
        @"notify_screensharing_attach",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SCREENSHARING_ATTACH),
    },
    [ES_EVENT_TYPE_NOTIFY_SCREENSHARING_DETACH] = {
        @"notify_screensharing_detach",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SCREENSHARING_DETACH),
    },
    [ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGIN] = {
        @"notify_openssh_login",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGIN),
    },
    [ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGOUT] = {
        @"notify_openssh_logout",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OPENSSH_LOGOUT),
    },
    [ES_EVENT_TYPE_NOTIFY_LOGIN_LOGIN] = {
        @"notify_login_login",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LOGIN_LOGIN),
    },
    [ES_EVENT_TYPE_NOTIFY_LOGIN_LOGOUT] = {
        @"notify_login_logout",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LOGIN_LOGOUT),
    },
    [ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_ADD] = {
        @"notify_btm_launch_item_add",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_ADD),
    },
    [ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_REMOVE] = {
        @"notify_btm_launch_item_remove",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_REMOVE),
    },
    // The following events are available beginning in macOS 14.0
    [ES_EVENT_TYPE_NOTIFY_PROFILE_ADD] = {
        @"notify_profile_add",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PROFILE_ADD),
    },
    [ES_EVENT_TYPE_NOTIFY_PROFILE_REMOVE] = {
        @"notify_profile_remove",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PROFILE_REMOVE),
    },
    [ES_EVENT_TYPE_NOTIFY_SU] = {
        @"notify_su",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SU),
    },
    [ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_PETITION] = {
        @"notify_authorization_petition",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_PETITION),
    },
    [ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_JUDGEMENT] = {
        @"notify_authorization_judgement",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_AUTHORIZATION_JUDGEMENT),
    },
    [ES_EVENT_TYPE_NOTIFY_SUDO] = {
        @"notify_sudo",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_SUDO),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_GROUP_ADD] = {
        @"notify_od_group_add",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_GROUP_ADD),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_GROUP_REMOVE] = {
        @"notify_od_group_remove",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_GROUP_REMOVE),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_GROUP_SET] = {
        @"notify_od_group_set",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_GROUP_SET),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_MODIFY_PASSWORD] = {
        @"notify_od_modify_password",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_MODIFY_PASSWORD),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_DISABLE_USER] = {
        @"notify_od_disable_user",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_DISABLE_USER),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_ENABLE_USER] = {
        @"notify_od_enable_user",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_ENABLE_USER),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_ADD] = {
        @"notify_od_attribute_value_add",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_ADD),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_REMOVE] = {
        @"notify_od_attribute_value_remove",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_VALUE_REMOVE),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_SET] = {
        @"notify_od_attribute_set",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_ATTRIBUTE_SET),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_CREATE_USER] = {
        @"notify_od_create_user",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_CREATE_USER),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_CREATE_GROUP] = {
        @"notify_od_create_group",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_CREATE_GROUP),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_DELETE_USER] = {
        @"notify_od_delete_user",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_DELETE_USER),
    },
    [ES_EVENT_TYPE_NOTIFY_OD_DELETE_GROUP] = {
        @"notify_od_delete_group",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_OD_DELETE_GROUP),
    },
    [ES_EVENT_TYPE_NOTIFY_XPC_CONNECT] = {
        @"notify_xpc_connect",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_XPC_CONNECT),
    },
};


#endif /* ESDefination_h */
