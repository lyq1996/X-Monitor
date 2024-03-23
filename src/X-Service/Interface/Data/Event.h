//
//  Event.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/12.
//

#ifndef Event_h
#define Event_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Event : NSObject <NSSecureCoding>

// event unique id
@property (nonatomic, copy, readonly) NSNumber *EventIdentify;

// event type string
@property (nonatomic, copy, readonly) NSString *EventType;

// event time in second
@property (nonatomic, copy, readonly) NSNumber *EventTime;

// event corresponding process info
@property (nonatomic, readonly) NSDictionary *EventProcess;

// parent process info of event corresponding process
@property (nonatomic, readonly) NSDictionary *EventParentProcess;

// unique info for different event
@property (nonatomic, readonly) NSDictionary *EventInfo;

- (instancetype)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end

NS_ASSUME_NONNULL_END

#endif /* Event_h */
