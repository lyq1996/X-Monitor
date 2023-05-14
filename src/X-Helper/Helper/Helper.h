//
//  helper.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/20.
//

#ifndef helper_h
#define helper_h

#import "HelperProtocol.h"
#import <Foundation/Foundation.h>

@interface Helper : NSObject<HelperProtocol, NSXPCListenerDelegate>

- (void)run;

@end

#endif /* helper_h */
