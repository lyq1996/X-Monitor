//
//  HelperManager.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/18.
//

#ifndef HelperManager_h
#define HelperManager_h

#import "HelperProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HelperManager : NSObject

- (nullable id<HelperProtocol>) getHelper:(void (^)(NSError *))handle;

@end

NS_ASSUME_NONNULL_END

#endif /* HelperManager_h */
