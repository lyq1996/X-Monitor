//
//  ClientProtocol.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/3/12.
//

#ifndef ClientProtocol_h
#define ClientProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    X_CLIENT_HANDLE_EVENT,
    X_CLIENT_HANDLE_ERROR,
} XClientCommand;

@protocol ClientProtocol

@required

- (void)handleServiceCmd:(XClientCommand)cmd withData:(NSData *)data withCompletion:(void (^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ClientProtocol_h */
