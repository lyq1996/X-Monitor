//
//  RemoteConsumer.m
//  X-Service
//
//  Created by lyq1996 on 2023/3/28.
//

#import "RemoteConsumer.h"
#import "ClientProtocol.h"
#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation RemoteConsumer {
}

@synthesize subscribleEventTypes;

- (instancetype)initWithConnection:(NSXPCConnection *)connection {
    self = [super init];
    if (self) {
        _remotePid = connection.processIdentifier;
        _remoteConnection = connection;
    }
    return self;
}

- (void)consumeEvent:(Event *)event {
    id<ClientProtocol> proxy = [self.remoteConnection remoteObjectProxy];

    // convert event to json
    NSError *error = nil;
    NSData *eventData = [NSKeyedArchiver archivedDataWithRootObject:event requiringSecureCoding:YES error:&error];
    
    [proxy handleServiceCmd:X_CLIENT_HANDLE_EVENT withData:eventData withCompletion:^(BOOL status){
        self->_counts ++;
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<pid: %d, connection: %p>", self.remotePid, self.remoteConnection];
}

@end
