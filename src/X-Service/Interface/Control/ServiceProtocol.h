//
//  ServiceProtocol.h
//  X-Service
//
//  Created by lyq1996 on 2023/2/9.
//

#ifndef ServiceProtocol_h
#define ServiceProtocol_h

#import "ProducerProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    X_SERVICE_PING,
    X_SERVICE_SUBSCIBLE_EVENT,
    X_SERVICE_START,
    X_SERVICE_STOP,
    X_SERVICE_DECISION_EVENT,
    X_SERVICE_GET_EVENT_TYPE,
    X_SERVICE_SET_LOG_LEVEL,
} XServiceCommand;

@protocol ServiceProtocol <NSObject>

@required

- (void)handleClientCmd:(XServiceCommand)cmd withData:(nullable NSData *)data withCompletion:(void (^)(BOOL, NSData *))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ServiceProtocol_h */
