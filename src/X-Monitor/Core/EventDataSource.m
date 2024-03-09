//
//  EventDataSource.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/14.
//

#import "GlobalObserverKey.h"
#import "EventDataSource.h"
#import "ConfigManager.h"
#import "EventCategory.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation EventDataSource {
    NSMutableArray<id<EventDataSourceDelagate>> *allDelegates;
    dispatch_queue_t onEventQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        allDelegates = [NSMutableArray array];
        onEventQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)addEvent:(Event *)event {
    for (id delegate in allDelegates) {
        dispatch_async(onEventQueue, ^(){
            [delegate OnEventDataSourceAdd:event];
        });
    }
}

- (void)addEventSourceDelegate:(nonnull id<EventDataSourceDelagate>)delegate {
    [allDelegates addObject:delegate];
}

@end
