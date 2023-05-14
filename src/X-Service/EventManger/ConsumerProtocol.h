//
//  ConsumerProtocol.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/3/11.
//

#ifndef ConsumerProtocol_h
#define ConsumerProtocol_h

#import "Event.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ConsumerProtocol

@required

@property NSSet<NSString *> *subscribleEventTypes;

- (void)consumeEvent:(Event *)event;

@end

NS_ASSUME_NONNULL_END

#endif /* EventConsumer_h */
