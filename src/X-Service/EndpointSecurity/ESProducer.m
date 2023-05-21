//
//  ESProducer.m
//  X-Service
//
//  Created by lyq1996 on 2023/4/4.
//

#import "ESProducer.h"
#import "ESEventHandler.h"
#import "ESDefination.h"
#import "Event.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import <bsm/libbsm.h>

extern DDLogLevel ddLogLevel;

#define GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE) \
    ^(es_client_t *client, const es_message_t *event) { \
        return [[EventHandler_##ES_EVENT_TYPE alloc] init]; \
    }


@implementation ESProducer {
    es_client_t *notifyClient;
    dispatch_queue_t notifyEventQueue;
}

@synthesize producerName;
@synthesize producerStatus;
@synthesize producerStatusString;
@synthesize supportedEventTypes;
@synthesize delegate;
@synthesize errorDelegate;

- (instancetype)initProducerWithDelegate:(id<ProducerDelegate>)producerDelegate withErrorManager:(id<ProducerErrorDelegate>)producerErrorDelegate {

    self = [super init];
    if (self) {
        delegate = producerDelegate;
        errorDelegate = producerErrorDelegate;
        producerName = kESProducerName;
        producerStatus = X_PRODUCER_STOPPED;
        producerStatusString = ProducerStatus2String[producerStatus];
        notifyEventQueue = dispatch_queue_create(kESProducerNotifyQueue, NULL);
        [self initSupportEventType];
        [self initES];
    }
    return self;
}

- (void)initSupportEventType {
    int maxEventType = ES_EVENT_TYPE_AUTH_SETOWNER;
    if (@available(macOS 10.15.1, *)) {
        maxEventType = ES_EVENT_TYPE_AUTH_EXCHANGEDATA;
    }
    if (@available(macOS 10.15.4, *)) {
        maxEventType = ES_EVENT_TYPE_AUTH_SEARCHFS;
    }
    if (@available(macOS 11.0, *)) {
        maxEventType = ES_EVENT_TYPE_AUTH_GET_TASK_READ;
    }
    if (@available(macOS 11.3, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_GET_TASK_INSPECT;
    }
    if (@available(macOS 13.0, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_REMOVE;
    }
    
    NSSet *currentSupportedEventTypes = [NSSet setWithArray:@[
        @"notify_exit",
        @"notify_exec",
        @"notify_fork",
        @"notify_open",
        @"notify_unlink",
        @"notify_rename",
        @"notify_kextload",
        @"notify_close",
        @"notify_mount",
        @"notify_signal",
        @"notify_mmap",
        @"notify_mprotect",
    ]];
    
    NSMutableArray *tmpSupportedEventTypes = [NSMutableArray array];
    for (int i=0; i<maxEventType; ++i) {
#pragma mark [TODO] support auth event
        if (ESEvents[i].isAuthEvent) {
            continue;
        }
        
#pragma mark [TODO] support more event
        if (![currentSupportedEventTypes containsObject:ESEvents[i].eventName]) {
            continue;
        }
        
        [tmpSupportedEventTypes addObject:ESEvents[i].eventName];
    }
    supportedEventTypes = [NSArray arrayWithArray:tmpSupportedEventTypes];
}


- (void)initES {
    es_new_client_result_t ret;
    
    ret = es_new_client(&notifyClient, ^(es_client_t *client, const es_message_t *event){
        
        if (client == NULL || event == NULL) {
            return;
        }
        
        if (@available(macOS 11.0, *)) {
            es_retain_message(event);
        }
        else {
            event = (es_message_t *)es_copy_message(event);
        }
        dispatch_async(self->notifyEventQueue, ^(){
            es_event_type_t type = event->event_type;
            BaseEventHandler *eventHandler = ESEvents[type].createEventHandle(client, event);
            Event *notifyEvent = [eventHandler handleEvent:event];
            if (@available(macOS 11.0, *)) {
                es_release_message(event);
            }
            else {
                es_free_message((es_message_t *)event);
            }
            [self->delegate handleEvent:notifyEvent];
        });
        
    });
    if (ret != ES_NEW_CLIENT_RESULT_SUCCESS) {
        DDLogError(@"create notify client failed, reason: (es_new_client_result_t)%d", ret);
        abort();
    }
}

- (void)updateEvent:(es_client_t *)client withEventType:(NSArray<NSString *> *)eventTypes isAuthEvent:(BOOL)isAuthEvent {
    
    size_t count = 0;
    es_event_type_t *subscriptions = NULL;
    es_return_t ret = es_subscriptions(client, &count, &subscriptions);
    if (ret != ES_RETURN_SUCCESS) {
        DDLogError(@"get current notify es subscriptions failed");
        return;
    }
    
    int unsubscribedCount = 0;
    es_event_type_t *unsubscribedEventTypes = malloc(ES_EVENT_TYPE_LAST * sizeof(es_event_type_t));
    if (unsubscribedEventTypes == NULL) {
        DDLogError(@"malloc un subscriptions failed");
        return;
    }
    
    int subscribedCount = 0;
    es_event_type_t *subscribedEventTypes = malloc(ES_EVENT_TYPE_LAST * sizeof(es_event_type_t));
    if (subscribedEventTypes == NULL) {
        free(unsubscribedEventTypes);
        unsubscribedEventTypes = NULL;
        DDLogError(@"malloc subscriptions failed");
        return;
    }
    
    // find unsubscribe event
    for (int i = 0; i < count; ++i) {
        const ESEvent *esEvent = &ESEvents[subscriptions[i]];
        NSString *eventName = esEvent->eventName;
        if (isAuthEvent == esEvent->isAuthEvent && ![eventTypes containsObject:eventName]) {
            unsubscribedEventTypes[unsubscribedCount++] = subscriptions[i];
            DDLogDebug(@"unsub auth/notify: %d, type: %@", isAuthEvent, eventName);
        }
    }
    
    // find subscribe event
    NSMutableSet *currentEvent = [NSMutableSet set];
    for (int i = 0; i < count; ++i) {
        const ESEvent *esEvent = &ESEvents[subscriptions[i]];
        [currentEvent addObject:esEvent->eventName];
    }
    for (NSString *eventName in eventTypes) {
        if (![currentEvent containsObject:eventName]) {
            for (int i = 0; i < sizeof(ESEvents)/sizeof(ESEvent); ++i) {
                const ESEvent *esEvent = &ESEvents[i];
                if (isAuthEvent == esEvent->isAuthEvent && [eventName isEqualToString:esEvent->eventName]) {
                    subscribedEventTypes[subscribedCount++] = i;
                    DDLogDebug(@"sub auth/notify: %d, type: %@", isAuthEvent, eventName);
                }
            }
        }
    }
    
    es_unsubscribe(client, unsubscribedEventTypes, unsubscribedCount);
    es_subscribe(client, subscribedEventTypes, subscribedCount);
    
    free(unsubscribedEventTypes);
    unsubscribedEventTypes = NULL;
    free(subscribedEventTypes);
    subscribedEventTypes = NULL;
}

- (void)subscribleEventType:(NSArray<NSString *> *)eventTypes {
    DDLogInfo(@"update subscribed: %@", eventTypes);
            
    if (eventTypes == nil || eventTypes.count == 0) {
        // delete es client and stop producer
        es_unsubscribe_all(notifyClient);
#pragma mark [TODO] support auth event
        
        producerStatus = X_PRODUCER_STOPPED;
        producerStatusString = ProducerStatus2String[producerStatus];
        return;
    }
    
    [self updateEvent:notifyClient withEventType:eventTypes isAuthEvent:NO];
    producerStatus = X_PRODUCER_STARTED;
    producerStatusString = ProducerStatus2String[X_PRODUCER_STARTED];
    return;
}

- (BOOL)allowEvent:(nonnull void *)handle {
    return YES;
}


- (BOOL)denyEvent:(nonnull void *)handle {
    return YES;
}

const ESEvent ESEvents[] = {
    [ES_EVENT_TYPE_AUTH_EXEC] = {
        @"auth_exec",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_EXEC),
    },
    [ES_EVENT_TYPE_AUTH_OPEN] = {
        @"auth_open",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_OPEN),
    },
    [ES_EVENT_TYPE_AUTH_KEXTLOAD] = {
        @"auth_kextload",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_KEXTLOAD),
    },
    [ES_EVENT_TYPE_AUTH_MMAP] = {
        @"auth_mmap",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_MMAP),
    },
    [ES_EVENT_TYPE_AUTH_MPROTECT] = {
        @"auth_mprotect",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_MPROTECT),
    },
    [ES_EVENT_TYPE_AUTH_MOUNT] = {
        @"auth_mount",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_MOUNT),
    },
    [ES_EVENT_TYPE_AUTH_RENAME] = {
        @"auth_rename",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_RENAME),
    },
    [ES_EVENT_TYPE_AUTH_SIGNAL] = {
        @"auth_signal",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SIGNAL),
    },
    [ES_EVENT_TYPE_AUTH_UNLINK] = {
        @"auth_unlink",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_UNLINK),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_FILE_PROVIDER_MATERIALIZE),
    },
    [ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE] = {
        @"notify_file_provider_materialize",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_MATERIALIZE),
    },
    [ES_EVENT_TYPE_AUTH_FILE_PROVIDER_UPDATE] = {
        @"auth_file_provider_update",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_FILE_PROVIDER_UPDATE),
    },
    [ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE] = {
        @"notify_file_provider_update",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_FILE_PROVIDER_UPDATE),
    },
    [ES_EVENT_TYPE_AUTH_READLINK] = {
        @"auth_readlink",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_READLINK),
    },
    [ES_EVENT_TYPE_NOTIFY_READLINK] = {
        @"notify_readlink",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_READLINK),
    },
    [ES_EVENT_TYPE_AUTH_TRUNCATE] = {
        @"auth_truncate",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_TRUNCATE),
    },
    [ES_EVENT_TYPE_NOTIFY_TRUNCATE] = {
        @"notify_truncate",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_TRUNCATE),
    },
    [ES_EVENT_TYPE_AUTH_LINK] = {
        @"auth_link",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_LINK),
    },
    [ES_EVENT_TYPE_NOTIFY_LOOKUP] = {
        @"notify_lookup",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LOOKUP),
    },
    [ES_EVENT_TYPE_AUTH_CREATE] = {
        @"auth_create",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_CREATE),
    },
    [ES_EVENT_TYPE_AUTH_SETATTRLIST] = {
        @"auth_setattrlist",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETATTRLIST),
    },
    [ES_EVENT_TYPE_AUTH_SETEXTATTR] = {
        @"auth_setextattr",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_SETFLAGS] = {
        @"auth_setflags",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETFLAGS),
    },
    [ES_EVENT_TYPE_AUTH_SETMODE] = {
        @"auth_setmode",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETMODE),
    },
    [ES_EVENT_TYPE_AUTH_SETOWNER] = {
        @"auth_setowner",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETOWNER),
    },
    // The following events are available beginning in macOS 10.15.1
    [ES_EVENT_TYPE_AUTH_CHDIR] = {
        @"auth_chdir",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_CHDIR),
    },
    [ES_EVENT_TYPE_NOTIFY_CHDIR] = {
        @"notify_chdir",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CHDIR),
    },
    [ES_EVENT_TYPE_AUTH_GETATTRLIST] = {
        @"auth_getattrlist",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_GETATTRLIST),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_CHROOT),
    },
    [ES_EVENT_TYPE_NOTIFY_CHROOT] = {
        @"notify_chroot",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_CHROOT),
    },
    [ES_EVENT_TYPE_AUTH_UTIMES] = {
        @"auth_utimes",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_UTIMES),
    },
    [ES_EVENT_TYPE_NOTIFY_UTIMES] = {
        @"notify_utimes",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UTIMES),
    },
    [ES_EVENT_TYPE_AUTH_CLONE] = {
        @"auth_clone",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_CLONE),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_GETEXTATTR),
    },
    [ES_EVENT_TYPE_NOTIFY_GETEXTATTR] = {
        @"notify_getextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_GETEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_LISTEXTATTR] = {
        @"auth_listextattr",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_LISTEXTATTR),
    },
    [ES_EVENT_TYPE_NOTIFY_LISTEXTATTR] = {
        @"notify_listextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_LISTEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_READDIR] = {
        @"auth_readdir",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_READDIR),
    },
    [ES_EVENT_TYPE_NOTIFY_READDIR] = {
        @"notify_readdir",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_READDIR),
    },
    [ES_EVENT_TYPE_AUTH_DELETEEXTATTR] = {
        @"auth_deleteextattr",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_DELETEEXTATTR),
    },
    [ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR] = {
        @"notify_deleteextattr",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR),
    },
    [ES_EVENT_TYPE_AUTH_FSGETPATH] = {
        @"auth_fsgetpath",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_FSGETPATH),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETTIME),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_UIPC_BIND),
    },
    [ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT] = {
        @"notify_uipc_connect",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_UIPC_CONNECT),
    },
    [ES_EVENT_TYPE_AUTH_UIPC_CONNECT] = {
        @"auth_uipc_connect",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_UIPC_CONNECT),
    },
    [ES_EVENT_TYPE_AUTH_EXCHANGEDATA] = {
        @"auth_exchangedata",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_EXCHANGEDATA),
    },
    // The following events are available beginning in macOS 10.15.4
    [ES_EVENT_TYPE_AUTH_SETACL] = {
        @"auth_setacl",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SETACL),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_PROC_CHECK),
    },
    [ES_EVENT_TYPE_NOTIFY_PROC_CHECK] = {
        @"notify_proc_check",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_PROC_CHECK),
    },
    [ES_EVENT_TYPE_AUTH_GET_TASK] = {
        @"auth_get_task",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_GET_TASK),
    },
    [ES_EVENT_TYPE_AUTH_SEARCHFS] = {
        @"auth_searchfs",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_SEARCHFS),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_FCNTL),
    },
    [ES_EVENT_TYPE_AUTH_IOKIT_OPEN] = {
        @"auth_iokit_open",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_IOKIT_OPEN),
    },
    [ES_EVENT_TYPE_AUTH_PROC_SUSPEND_RESUME] = {
        @"auth_proc_suspend_resume",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_PROC_SUSPEND_RESUME),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_REMOUNT),
    },
    [ES_EVENT_TYPE_NOTIFY_REMOUNT] = {
        @"notify_remount",
        NO,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_NOTIFY_REMOUNT),
    },
    [ES_EVENT_TYPE_AUTH_GET_TASK_READ] = {
        @"auth_get_task_read",
        YES,
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_GET_TASK_READ),
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
        GEN_CREATE_EVENT_HANDLE(ES_EVENT_TYPE_AUTH_COPYFILE),
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
    }
};

@end
