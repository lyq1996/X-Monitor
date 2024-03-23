//
//  ServiceManager.h
//  X-Service
//
//  Created by lyq1996 on 2023/2/9.
//
#ifndef ServiceManager_h
#define ServiceManager_h

#import "ServiceProtocol.h"
#import "EventManager.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServiceManager : NSObject<ServiceProtocol, NSXPCListenerDelegate>

- (instancetype)initWithEventManager:(EventManager *)manager;
- (void)start;

@end

NS_ASSUME_NONNULL_END

#endif /* ServiceManager_h */
