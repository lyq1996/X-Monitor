//
//  ServiceManager.m
//  ServiceManager
//
//  Created by lyq1996 on 2023/2/9.
//

#import "ServiceManager.h"
#import "ServiceProtocol.h"
#import "ClientProtocol.h"
#import "ConsumerProtocol.h"
#import "EventManager.h"
#import "RemoteConsumer.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation ServiceManager {
    __weak EventManager *eventManager;
    NSXPCListener *listener;
    NSMutableArray *remoteConsumers;
}

- (instancetype)initWithEventManager:(EventManager *)manager {
    self = [super init];
    if (self != nil) {
        eventManager = manager;
        listener = nil;
        remoteConsumers = [NSMutableArray array];
    }
    return self;
}

#pragma mark Service method

- (void)start {
    NSString *machServiceName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSEndpointSecurityMachServiceName"];

    listener = [[NSXPCListener alloc] initWithMachServiceName:machServiceName];
    listener.delegate = self;
    [listener resume];
    
    DDLogInfo(@"X-Service XPC listener started");
}

#pragma mark XPC listener delegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    
    // one process can only create one connection to service
    pid_t remotePid = newConnection.processIdentifier;
    for (RemoteConsumer *consumer in remoteConsumers) {
        if (consumer.remotePid == remotePid) {
            DDLogWarn(@"deny process: %d, already has a connection to X-Service", remotePid);
            return NO;
        }
    }
    
    // [TODO] Verify peer
    
    DDLogVerbose(@"incoming connection: %@", newConnection);

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ServiceProtocol)];
    newConnection.exportedObject = self;
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ClientProtocol)];
    
    __weak NSXPCConnection *weakNewConnection = newConnection;
    newConnection.invalidationHandler = ^(){
        DDLogWarn(@"service side NSXPCConnection invalid");
        [self handleInvalidOrInterrupt:weakNewConnection];
    };

    newConnection.interruptionHandler = ^(){
        DDLogWarn(@"service side NSXPCConnection interrupt");
        [self handleInvalidOrInterrupt:weakNewConnection];
    };
    
    DDLogInfo(@"Accept new connection from: %d", remotePid);

    RemoteConsumer *consumer = [[RemoteConsumer alloc] initWithConnection:newConnection];
    [remoteConsumers addObject:consumer];
    DDLogVerbose(@"current consumer size: %lu, add consumer: %@", remoteConsumers.count, consumer);
    
    [newConnection resume];
    return YES;
}

- (void)handleInvalidOrInterrupt:(NSXPCConnection *)weakNewConnection {
    RemoteConsumer *consumer = [self getRemoteConsumer:weakNewConnection];

    [self handleStopCmd:consumer];
    DDLogInfo(@"the process: %d consumer: %llu events", consumer.remotePid, consumer.counts);
    [self->remoteConsumers removeObject:consumer];
}

- (RemoteConsumer *)getRemoteConsumer:(NSXPCConnection *)connection {
    NSXPCConnection *current = connection;
    if (current == nil) {
        DDLogVerbose(@"current connection is nil, get from context");
        current = [NSXPCConnection currentConnection];
    }
    
    for (RemoteConsumer *consumer in remoteConsumers) {
        DDLogVerbose(@"in consumer: %@ <-> current: %@", consumer.remoteConnection, current);
        if (consumer.remoteConnection == current) {
            DDLogVerbose(@"find consumer: %@", consumer);
            return consumer;
        }
    }
    return nil;
}

#pragma mark XPC Service method

- (BOOL)handleSubCmd:(RemoteConsumer *)consumer withData:(NSData *)data {
    DDLogDebug(@"handle subscrible cmd from consumer: %@", consumer);

    NSSet *subscrible = nil;
    @try {
        NSError *error;
        subscrible = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSSet class], [NSString class], nil] fromData:data error:&error];
        if (error != nil) {
            DDLogError(@"Failed to unarchive NSArray: %@", error);
            return NO;
        }
    } @catch (NSException *exception) {
        DDLogError(@"Failed to unarchive NSArray: %@", exception);
        return NO;
    }

    for (NSString *event in subscrible) {
        if (![eventManager.supportedEventType containsObject:event]) {
            DDLogError(@"client trying to subscrible not support event: %@", event);
            return NO;
        }
    }
    
    consumer.subscribleEventTypes = subscrible;
    return YES;
}

- (BOOL)handleStartCmd:(RemoteConsumer *)consumer {
    DDLogDebug(@"handle start cmd from consumer: %@", consumer);
    [eventManager addConsumer:consumer];
    return YES;
}

- (BOOL)handleStopCmd:(RemoteConsumer *)consumer {
    DDLogDebug(@"handle stop cmd from consumer: %@", consumer);
    [eventManager detachConsumer:consumer];
    return YES;
}

- (void)handleClientCmd:(XServiceCommand)cmd withData:(NSData *)data withCompletion:(void (^)(BOOL, NSData *))completion {
    
    RemoteConsumer *consumer = [self getRemoteConsumer:nil];
    if (consumer == nil) {
        DDLogError(@"handle client cmd failed, get consumer failed");
        completion(NO, nil);
    }
    
    switch (cmd) {
        case X_SERVICE_PING:
            // pong
            completion(YES, nil);
            break;

        case X_SERVICE_SUBSCIBLE_EVENT:
            completion([self handleSubCmd:consumer withData:data], nil);
            break;
            
        case X_SERVICE_START:
            completion([self handleStartCmd:consumer], nil);
            break;
            
        case X_SERVICE_STOP:
            completion([self handleStopCmd:consumer], nil);
            break;

        case X_SERVICE_DECISION_EVENT:
            break;
        
        case X_SERVICE_GET_EVENT_TYPE:
            completion(YES, [NSKeyedArchiver archivedDataWithRootObject:eventManager.supportedEventType requiringSecureCoding:YES error:nil]);
            break;
            
        case X_SERVICE_SET_LOG_LEVEL:
            if (data.length == sizeof(NSUInteger)) {
                [data getBytes:&ddLogLevel length:sizeof(NSUInteger)];
                completion(YES, [NSData dataWithBytes:&ddLogLevel length:sizeof(NSUInteger)]);
            }
            else {
                completion(NO, [NSData dataWithBytes:&ddLogLevel length:sizeof(NSUInteger)]);
            }
            break;
            
        default:
            completion(NO, nil);
            break;
    }
    
}

#pragma mark Event producer status handle method
- (void)handleProducerError:(XProducerError)error {
    // notify all client the producer status
}

@end
