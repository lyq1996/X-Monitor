//
//  EventProviderStatus.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/3/11.
//

#ifndef EventProviderStatus_h
#define EventProviderStatus_h

typedef enum : NSUInteger {
    X_EVENT_PROVIDER_IDLE,
    X_EVENT_PROVIDER_WORKING,
    X_EVENT_PROVIDER_ABNORMAL,
} XEventProviderStatus;

#endif /* EventProviderStatus_h */
