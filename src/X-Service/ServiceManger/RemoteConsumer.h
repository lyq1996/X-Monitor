//
//  RemoteConsumer.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/3/28.
//

#ifndef RemoteConsumer_h
#define RemoteConsumer_h

#import "ConsumerProtocol.h"
#import "ClientProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemoteConsumer : NSObject<ConsumerProtocol>

@property (readonly) pid_t remotePid;
@property (readonly) uint64_t counts;
@property (readonly) NSXPCConnection *remoteConnection;

- (instancetype)initWithConnection:(NSXPCConnection *)connection;

@end

NS_ASSUME_NONNULL_END

#endif /* RemoteConsumer_h */
