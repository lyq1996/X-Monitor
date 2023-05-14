//
//  EventManager.m
//  X-Service
//
//  Created by lyq1996 on 2023/3/11.
//

#import "EventManager.h"
#import "ProcessCache.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

#define kEventManagerNotifyQueue    "com.lyq1996.X-Service.EventManagerNotifyQueue"

@implementation EventManager {

    // Event with its producer
    NSMutableDictionary<NSString *, id<ProducerProtocol>> *producers;

    // Event with its consumers
    NSMutableArray<id<ConsumerProtocol>> *consumers;
    
    // Process cache
    ProcessCache *caches;
    
    // Notify event queue
    dispatch_queue_t notifyEventQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        producers = [NSMutableDictionary dictionary];
        consumers = [NSMutableArray array];
        caches = [[ProcessCache alloc] init];
        caches.subscribleEventTypes = [NSSet setWithArray:@[@"notify_exec", @"notify_fork"]];
        notifyEventQueue = dispatch_queue_create(kEventManagerNotifyQueue, NULL);
    }
    return self;
}

- (NSArray<NSString *> *)supportedEventType {
    return producers.allKeys;
}

- (void)addProducer:(id<ProducerProtocol>)producer {
    for (NSString *type in producer.supportedEventTypes) {
        [producers setObject:producer forKey:type];
        DDLogVerbose(@"add producer: %@ for event type: %@", producer.producerName, type);
    }
}

- (void)addConsumer:(id<ConsumerProtocol>)consumer {
    if (![consumers containsObject:consumer]) {
        DDLogDebug(@"add consumer: %@ into consumers", consumer);
        [consumers addObject:consumer];
        
        if (![consumers containsObject:caches]) {
            DDLogDebug(@"add cache consumer into consumers");
            [consumers addObject:caches];
        }
        
        [self updateProducerEventType];
    }
}

- (void)detachConsumer:(id<ConsumerProtocol>)consumer {
    if ([consumers containsObject:consumer]) {
        DDLogDebug(@"detach consumer: %@ from consumers", consumer);
        [consumers removeObject:consumer];
        
        if ([consumers count] == 1 && [consumers containsObject:caches]) {
            DDLogDebug(@"current consumer count is 1, detach cache consumer from consumers");
            [consumers removeObject:caches];
            [caches clearCache];
        }
        
        [self updateProducerEventType];
    }
}

- (void)updateProducerEventType {
    NSMutableSet *types = [NSMutableSet set];
    for (id<ConsumerProtocol> consumer in consumers) {
        [types addObjectsFromArray:[consumer.subscribleEventTypes allObjects]];
    }
    
    for (id<ProducerProtocol> producer in [NSSet setWithArray:[producers allValues]]) {
        DDLogDebug(@"generate event type for producer: %@", producer.producerName);
        NSMutableArray<NSString *> *producerEventTypes = [NSMutableArray array];
        
        for (NSString *type in types) {
            if (producer == [producers objectForKey:type]) {
                DDLogDebug(@"add event type: %@ for producer: %@", type, producer.producerName);
                [producerEventTypes addObject:type];
            }
        }
        [producer subscribleEventType:producerEventTypes];
    }
}

- (void)decisionEvent:(BOOL)isAllow withEventHandle:(void *)eventIdentify withConsumer:(id<ConsumerProtocol>)consumer {
    // todo
    // call producer.handleAuth(eventIdentify, isAllow)
    // need add cache for multi-consumer auth response
}

- (void)handleEvent:(Event *)event {

    if ([event.needDiscision isEqualToNumber:@(NO)]) {
        dispatch_async(notifyEventQueue, ^(){
            // notify event
            // fill process info from cache
            
            /*
            NSLog(@"%@", [event shortInfo]);
            NSLog(@"%@", [event detailInfo]);
            NSLog(@"%@", [event jsonInfo]);
            */
             
            [self->caches fillEventFromCache:event];
            for (id<ConsumerProtocol> consumer in [self->consumers copy]) {
                if ([consumer.subscribleEventTypes containsObject:event.eventType]) {
                    [consumer consumeEvent:event];
                }
            }
        });
    }
}

- (void)handleProducerStatus:(XProducerStatus)status withStatusString:(NSString *)statusString {
    // todo
}

@end
