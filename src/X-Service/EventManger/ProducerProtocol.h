//
//  EventProducer.h
//  X-Service
//
//  Created by lyq1996 on 2023/2/8.
//

#ifndef ProviderProtocol_h
#define ProviderProtocol_h

#import "Event.h"
#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    X_PRODUCER_STOPPED,
    X_PRODUCER_STARTED,
} XProducerStatus;

static NSString * _Nonnull ProducerStatus2String[] = {
    [X_PRODUCER_STOPPED] = @"X-Procuder stopped",
    [X_PRODUCER_STARTED] = @"X-Procuder started",
};

typedef enum : NSUInteger {
    X_PRODUCER_RESERVE, // not use for now
} XProducerError;

NS_ASSUME_NONNULL_BEGIN

@protocol ProducerErrorDelegate <NSObject>

- (void)handleProducerError:(XProducerError)error;

@end

@protocol ProducerDelegate <NSObject>

- (void)handleProducerStatus:(XProducerStatus)status withStatusString:(NSString *)statusString;

- (void)handleEvent:(Event *)event;

@end

@protocol ProducerProtocol <NSObject>

@required

@property (readonly) NSString *producerName;
@property (readonly) NSArray<NSString *> *supportedEventTypes;

@property (readonly) XProducerStatus producerStatus;
@property (readonly) NSString *producerStatusString;

@property (weak, readonly) id<ProducerDelegate> delegate;
@property (weak, readonly) id<ProducerErrorDelegate> errorDelegate;


- (instancetype)initProducerWithDelegate:(id<ProducerDelegate>)producerDelegate withErrorManager:(id<ProducerErrorDelegate>)producerErrorDelegate;
- (void)subscribleEventType:(NSArray<NSString *> *)eventTypes;

- (BOOL)denyEvent:(void *)handle;
- (BOOL)allowEvent:(void *)handle;

@end

NS_ASSUME_NONNULL_END

#endif /* EventProvider_h */
