//
//  ProcessCache.h
//  X-Service
//
//  Created by lyq1996 on 2023/3/11.
//

#ifndef ProcessCache_h
#define ProcessCache_h

#import "EventPrivate.h"
#import "ConsumerProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProcessCache : NSObject<ConsumerProtocol> 

- (void)fillEventFromCache:(Event *)event;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END

#endif /* ProcessCache_h */
