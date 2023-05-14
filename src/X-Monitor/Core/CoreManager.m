//
//  CoreManager.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/8.
//

#import "CoreManager.h"
#import "ServiceProtocol.h"
#import "ClientProtocol.h"
#import "GlobalObserverKey.h"
#import "ConfigManager.h"
#import <Cocoa/Cocoa.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#define kMachServiceName @"com.lyq1996.X-Service"

extern DDLogLevel ddLogLevel;

@interface CoreManager()<ClientProtocol>
@end

@implementation CoreManager {
    NSXPCConnection *connection;
}

+ (instancetype)shared {
    static CoreManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
 
- (instancetype)init {
    if (self = [super init]) {
        _status = X_CORE_UNINITED;
        _dataSource = [[EventDataSource alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setLogLevel:) name:kLogLevelChangeKey object:nil];
    }
    return self;
}

- (void)showAlertWindow:(NSString *)errorString withMesggageText:(NSString *)msgText{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:msgText];
    [alert setInformativeText:errorString];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

- (void)handleInterrupt {
    _status = X_CORE_UNINITED;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self showAlertWindow:@"Connection to X-Service interrupt" withMesggageText:@"Service Exception"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kInitCoreServicekey object:nil];
    });
    
}

- (void)handleInvalidation {
    _status = X_CORE_UNINITED;

    dispatch_async(dispatch_get_main_queue(), ^(){
        [self showAlertWindow:@"Connection to X-Service invalid" withMesggageText:@"Service Exception"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kInitCoreServicekey object:nil];
    });
}

- (XCoreError)setLogLevel {
    __block XCoreError result = X_CORE_FAIL;
    
    DDLogDebug(@"init service log level");
    
    id proxy = (id<ServiceProtocol>)[connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
        DDLogError(@"XPC connected failed with error [%@]!", error.localizedDescription);
    }];
    
    NSData *logLevel = [NSData dataWithBytes:&ddLogLevel length:sizeof(NSUInteger)];
    
    [proxy handleClientCmd:X_SERVICE_SET_LOG_LEVEL withData:logLevel withCompletion:^(BOOL ret, NSData *data) {
        
        if (ret == YES) {
            result = X_CORE_SUCCESS;
            
            NSUInteger currentLevel = 0;
            [data getBytes:&currentLevel length:sizeof(NSUInteger)];
            
            DDLogInfo(@"set service log level ret: %d, current level: %lu", ret, (unsigned long)currentLevel);
        }
    }];
    
    return result;
}

- (XCoreError)getAllEventType {
    __block XCoreError result = X_CORE_FAIL;

    DDLogDebug(@"init service supported event");
    
    id proxy = (id<ServiceProtocol>)[connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
        DDLogError(@"XPC connected failed with error [%@]!", error.localizedDescription);
    }];

    [proxy handleClientCmd:X_SERVICE_GET_EVENT_TYPE withData:nil withCompletion:^(BOOL ret, NSData *data){
        if (ret == YES) {
            result = X_CORE_SUCCESS;
            NSArray *array = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSString class], nil] fromData:data error:nil];
            DDLogVerbose(@"service support event: %@", array);
            result = X_CORE_SUCCESS;
            
            if ([array isEqualToArray:[ConfigManager shared].allEventTypes] != YES) {
                DDLogInfo(@"current all event type not equal to service's all");
                [[ConfigManager shared].allEventTypes removeAllObjects];
                [[ConfigManager shared].allEventTypes addObjectsFromArray:array];
                
                BOOL needReload = NO;
                
                // check subscrible event in array ?
                for (NSString *event in [[ConfigManager shared].eventTypes copy]) {
                    if (![array containsObject:event]) {
                        DDLogInfo(@"remove not exists event: %@ from subsrcible", event);
                        [[ConfigManager shared].eventTypes removeObject:event];
                    }
                }
                
                // update category
                for (EventCategory *category in [[ConfigManager shared].categories copy]) {
                    if (!category.isCustomCategory) {
                        DDLogDebug(@"ignore category: %@ due to not custom", category.categoryName);
                        continue;
                    }
                    
                    for (NSString *event in [category.categoryDependence copy]) {
                        if (![array containsObject:event]) {
                            [category.categoryDependence removeObject:event];
                            DDLogInfo(@"remove event type: %@ from category: %@", event, category.categoryName);
                        }
                    }
                    
                    if ([category.categoryDependence count] == 0) {
                        [[ConfigManager shared].categories removeObject:category];
                        needReload = YES;
                        DDLogInfo(@"remove category: %@", category.categoryName);
                    }
                }
                
                [[ConfigManager shared] saveEventSetting];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSidebarReloadKey object:nil];
            }
        }
    }];

    return result;
}

- (XCoreError)initCore {
    __block XCoreError result = X_CORE_FAIL;
    
    NSXPCConnection *newConnection = [[NSXPCConnection alloc] initWithMachServiceName:kMachServiceName options:NSXPCConnectionPrivileged];

    if (newConnection == nil) {
        return result;
    }
    else {
        newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ServiceProtocol)];
        newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ClientProtocol)];
        newConnection.exportedObject = self;
        
        newConnection.interruptionHandler = ^{
            [self handleInterrupt];
        };

        newConnection.invalidationHandler = ^{
            [self handleInvalidation];
        };
        [newConnection resume];
        
        id proxy = (id<ServiceProtocol>)[newConnection synchronousRemoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
            DDLogError(@"XPC connected failed with error [%@]!", error.localizedDescription);
        }];
        
        [proxy handleClientCmd:X_SERVICE_PING withData:nil withCompletion:^(BOOL ret, NSData *data) {
            DDLogDebug(@"pong from service: %d", ret);
            result = X_CORE_SUCCESS;
        }];

        if (result == X_CORE_SUCCESS) {
            connection = newConnection;
            _status = X_CORE_STOPPED;
            result = [self setLogLevel];
            result = [self getAllEventType];
        }
        return result;
    }
}

- (XCoreError)startCore {
    __block XCoreError result = X_CORE_FAIL;
    
    if (_status == X_CORE_UNINITED) {
        DDLogError(@"core un-inited");
        return result;
    }
    
    if (_status == X_CORE_STARTED) {
        DDLogWarn(@"aleady start");
        result = X_CORE_SUCCESS;
        return result;
    }

    if ([[ConfigManager shared].eventTypes count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self showAlertWindow:@"No event for monitor!\nPlease go to X-Monitor -> Settings." withMesggageText:@"Start failed"];
            
        });
        return result;
    }
    
    NSError *error;
    NSData *subscriableEvent = [NSKeyedArchiver archivedDataWithRootObject:[ConfigManager shared].eventTypes requiringSecureCoding:YES error:&error];
    if (error != nil) {
        DDLogError(@"failed to serialize subscriable event, %@", error.localizedDescription);
        return result;
    }
    
    id proxy = (id<ServiceProtocol>)[connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
        DDLogError(@"XPC connected failed with error [%@]!", error.localizedDescription);
    }];

    [proxy handleClientCmd:X_SERVICE_SUBSCIBLE_EVENT withData:subscriableEvent withCompletion:^(BOOL ret, NSData *data) {
        DDLogDebug(@"subscrible result from service: %d", ret);
        if (ret == YES) {
            result = X_CORE_SUCCESS;
        }
    }];
    if (result == X_CORE_FAIL) {
        DDLogError(@"subscrible event failed, check service log for more details");
        return result;
    }
    
    [proxy handleClientCmd:X_SERVICE_START withData:nil withCompletion:^(BOOL ret, NSData *data) {
        DDLogDebug(@"start result from service: %d", ret);
        if (ret == YES) {
            result = X_CORE_SUCCESS;
        }
    }];
    if (result == X_CORE_FAIL) {
        DDLogError(@"start event failed, check service log for more details");
        return result;
    }
    
    _status = X_CORE_STARTED;
    return result;
}

- (XCoreError)stopCore {
    __block XCoreError result = X_CORE_FAIL;
    
    if (_status == X_CORE_UNINITED) {
        DDLogError(@"core un-inited");
        return result;
    }
    
    if (_status == X_CORE_STOPPED) {
        DDLogWarn(@"aleady stopped");
        result = X_CORE_SUCCESS;
        return result;
    }
    
    id proxy = (id<ServiceProtocol>)[connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
        DDLogError(@"XPC connected failed with error [%@]!", error.localizedDescription);
    }];
    
    [proxy handleClientCmd:X_SERVICE_STOP withData:nil withCompletion:^(BOOL ret, NSData *data) {
        DDLogDebug(@"stop result from service: %d", ret);
        if (ret == YES) {
            result = X_CORE_SUCCESS;
        }
    }];
    if (result == X_CORE_FAIL) {
        DDLogError(@"stop event failed, check service log for more details");
        return result;
    }
    
    _status = X_CORE_STOPPED;
    return result;
}

- (void)setLogLevel:(id)sender {
    [self setLogLevel];
}

- (void)handleServiceCmd:(XClientCommand)cmd withData:(NSData *)data withCompletion:(nonnull void (^)(BOOL))completion {
    if (cmd == X_CLIENT_HANDLE_EVENT) {
        
        NSError *error = nil;
        
        NSMutableSet *allowClasses = [[EventFactory getAllClasses] mutableCopy];
        [allowClasses addObject:[NSString class]];
        [allowClasses addObject:[NSNumber class]];
        Event *event = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowClasses fromData:data error:nil];

        if (error != nil) {
            return;
        } else {
            [self.dataSource addEvent:event];
        }
        
        completion(YES);
    }
}

@end
