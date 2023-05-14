//
//  main.m
//  helper
//
//  Created by lyq1996 on 2023/1/18.
//

#import "Helper.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>

#ifdef DEBUG
DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
DDLogLevel ddlogLevel = DDLogLevelInfo;
#endif


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[[Helper alloc] init] run];
    }
    return 0;
}
