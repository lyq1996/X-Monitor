//
//  ESProducer.m
//  X-Service
//
//  Created by lyq1996 on 2023/4/4.
//

#import "ESProducer.h"
#import "ESNotifyEventHandler.h"
#import "ESDefination.h"
#import "Event.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import <bsm/libbsm.h>

extern DDLogLevel ddLogLevel;

@implementation ESProducer {
    es_client_t *notifyClient;
    dispatch_queue_t notifyEventQueue;
    pid_t selfPid;
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
        selfPid = getpid();
        [self initSupportEventType];
        [self initES];
    }
    return self;
}

- (void)initSupportEventType {
    int maxEventType = ES_EVENT_TYPE_AUTH_SETOWNER;
    if (@available(macOS 10.15.1, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_SETACL;
    }
    if (@available(macOS 10.15.4, *)) {
        maxEventType = ES_EVENT_TYPE_AUTH_GET_TASK;
    }
    if (@available(macOS 11.0, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_REMOUNT;
    }
    if (@available(macOS 11.3, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_GET_TASK_INSPECT;
    }
    if (@available(macOS 12.0, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_COPYFILE;
    }
    if (@available(macOS 13.0, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_BTM_LAUNCH_ITEM_REMOVE;
    }
    if (@available(macOS 14.0, *)) {
        maxEventType = ES_EVENT_TYPE_NOTIFY_XPC_CONNECT;
    }
    
    NSSet *currentSupportedEventTypes = [NSSet setWithArray:@[
        @"notify_exec",
        @"notify_open",
        @"notify_fork",
        @"notify_close",
        @"notify_create",
        @"notify_exchangedata",
        @"notify_exit",
        @"notify_get_task",
        @"notify_kextload",
        @"notify_kextunload",
        @"notify_link",
        @"notify_mmap",
        @"notify_mprotect",
        @"notify_mount",
        @"notify_unmount",
        @"notify_iokit_open",
        @"notify_rename",
        @"notify_setattrlist",
        @"notify_setextattr",
        @"notify_setflags",
        @"notify_setmode",
        @"notify_setowner",
        @"notify_signal",
        @"notify_unlink",
        @"notify_write",
        @"notify_file_provider_materialize",
        @"notify_file_provider_update",
        @"notify_readlink",
        @"notify_truncate",
        @"notify_lookup",
        @"notify_chdir",
        @"notify_getattrlist",
        @"notify_stat",
        @"notify_access",
        @"notify_chroot",
        @"notify_utimes",
        @"notify_clone",
        @"notify_fcntl",
        @"notify_getextattr",
        @"notify_listextattr",
        @"notify_readdir",
        @"notify_deleteextattr",
        @"notify_fsgetpath",
        @"notify_dup",
        @"notify_settime",
        @"notify_uipc_bind",
        @"notify_uipc_connect",
        @"notify_setacl",
        @"notify_pty_grant",
        @"notify_pty_close",
        @"notify_proc_check",
        @"notify_searchfs",
        @"notify_proc_suspend_resume",
        @"notify_cs_invalidated",
    ]];
    
    NSMutableArray *tmpSupportedEventTypes = [NSMutableArray array];
    for (int i=0; i<=maxEventType; ++i) {
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
        dispatch_async(self->notifyEventQueue, ^() {
            es_event_type_t type = event->event_type;
            BaseEventHandler *eventHandler = ESEvents[type].createEventHandle(client, event);
            Event *notifyEvent = [eventHandler handleEvent:event];
            
            // mute system extension self event to avoid event cycle
            if ([[notifyEvent.EventProcess objectForKey:@"Pid"] isEqualToNumber:@(self->selfPid)]) {
                es_mute_process(client, &event->process->audit_token);
            } else {
                [self->delegate handleEvent:notifyEvent];
            }

            if (@available(macOS 11.0, *)) {
                es_release_message(event);
            }
            else {
                es_free_message((es_message_t *)event);
            }
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
        producerStatus = X_PRODUCER_STOPPED;
        producerStatusString = ProducerStatus2String[producerStatus];
        return;
    }
    
    [self updateEvent:notifyClient withEventType:eventTypes isAuthEvent:NO];
    producerStatus = X_PRODUCER_STARTED;
    producerStatusString = ProducerStatus2String[X_PRODUCER_STARTED];
    return;
}

@end
