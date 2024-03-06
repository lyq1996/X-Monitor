//
//  EventManager.h
//  X-Service
//
//  Created by lyq1996 on 2023/3/11.
//

#ifndef EventManager_h
#define EventManager_h

#import "ProducerProtocol.h"
#import "ConsumerProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventManager : NSObject<ProducerDelegate>

@property (readonly) NSArray<NSString *> *supportedEventType;

- (void)addProducer:(id<ProducerProtocol>)producer;

- (void)addConsumer:(id<ConsumerProtocol>)consumer;

- (void)detachConsumer:(id<ConsumerProtocol>)consumer;

@end

NS_ASSUME_NONNULL_END

#endif /* EventManager_h */
