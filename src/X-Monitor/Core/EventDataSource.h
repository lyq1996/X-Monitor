//
//  EventDataSource.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/14.
//

#import "Event.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventDataSource : NSObject

@property (readonly) NSMutableArray<Event *> *Events2Show;

- (void)addEvent:(Event *)event;

@end

NS_ASSUME_NONNULL_END
