//
//  CoreManager.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/8.
//

#ifndef CoreManager_h
#define CoreManager_h

#import "EventDataSource.h"
#import "Event.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    X_CORE_UNINITED,    // core manager uninited
    X_CORE_STOPPED,     // core manager stopped
    X_CORE_STARTED,     // core manager started
} XCoreStatus;

typedef enum : NSUInteger {
    X_CORE_SUCCESS,
    X_CORE_FAIL,          // extension connect fail
} XCoreError;

@interface CoreManager : NSObject

@property (readonly) XCoreStatus status;

@property (readonly) EventDataSource *dataSource;

- (XCoreError)initCore;
- (XCoreError)startCore;
- (XCoreError)stopCore;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END

#endif
