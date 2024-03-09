//
//  EventDataSource.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/14.
//

#import "Event.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EventDataSourceDelagate <NSObject>

- (void)OnEventDataSourceAdd:(Event *)event;

@end

@interface EventDataSource : NSObject

- (void)addEvent:(Event *)event;

- (void)addEventSourceDelegate:(id<EventDataSourceDelagate>)delegate;

@end

NS_ASSUME_NONNULL_END
