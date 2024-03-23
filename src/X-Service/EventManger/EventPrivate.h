//
//  EventPrivate.h
//  X-Monitor
//
//  Created by lyq1996 on 2024/3/21.
//

#import "Event.h"

@interface Event()

// event unique id
@property (nonatomic, copy, readwrite) NSNumber *EventIdentify;

// event type string
@property (nonatomic, copy, readwrite) NSString *EventType;

// event time in second
@property (nonatomic, copy, readwrite) NSNumber *EventTime;

// event corresponding process info
@property (nonatomic, readwrite) NSDictionary *EventProcess;

// parent process info of event corresponding process
@property (nonatomic, readwrite) NSDictionary *EventParentProcess;

// unique info for different event
@property (nonatomic, readwrite) NSDictionary *EventInfo;

@end
