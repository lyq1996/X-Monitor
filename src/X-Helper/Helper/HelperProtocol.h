//
//  HelperProtocol.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/18.
//

#ifndef HelperProtocol_h
#define HelperProtocol_h

#import <Foundation/Foundation.h>

@protocol HelperProtocol <NSObject>

- (void)installKernelExtension:(NSURL *)kextURL kextID:(NSString *)identifier reply:(void (^)(int))block;

@end

// other ...

#endif /* HelperProtocol_h */
