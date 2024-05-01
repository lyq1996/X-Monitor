//
//  main.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#import "ConfigManager.h"
#import "Signature.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Cocoa/Cocoa.h>

extern DDLogLevel ddLogLevel;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        [DDLog addLogger:fileLogger];
        DDOSLogger *logger = [[DDOSLogger alloc] init];
        [DDLog addLogger:logger];

        ConfigManager *configManager = [ConfigManager shared];
        [configManager initPreferences];
    }
    return NSApplicationMain(argc, argv);
}
