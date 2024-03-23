//
//  Event.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/12.
//

#import "Event.h"
#import "EventPrivate.h"

@implementation Event

- (instancetype)init {
    self = [super init];
    if (self) {
        _EventIdentify = nil;
        _EventType = nil;
        _EventTime = nil;
        _EventProcess = nil;
        _EventParentProcess = nil;
        _EventInfo = nil;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _EventIdentify = [decoder decodeObjectForKey:@"EventIdentify"];
        _EventType = [decoder decodeObjectForKey:@"EventType"];
        _EventTime = [decoder decodeObjectForKey:@"EventTime"];
        _EventProcess = [decoder decodeObjectForKey:@"EventProcess"];
        _EventParentProcess = [decoder decodeObjectForKey:@"EventParentProcess"];
        _EventInfo = [decoder decodeObjectForKey:@"EventInfo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_EventIdentify forKey:@"EventIdentify"];
    [encoder encodeObject:_EventType forKey:@"EventType"];
    [encoder encodeObject:_EventTime forKey:@"EventTime"];
    [encoder encodeObject:_EventProcess forKey:@"EventProcess"];
    [encoder encodeObject:_EventParentProcess forKey:@"EventParentProcess"];
    [encoder encodeObject:_EventInfo forKey:@"EventInfo"];
}

@end
