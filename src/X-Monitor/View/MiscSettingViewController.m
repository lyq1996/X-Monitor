//
//  MiscSettingViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/8.
//

#import "MiscSettingViewController.h"
#import "ConfigManager.h"
#import "GlobalObserverKey.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation MiscSettingViewController {
    __weak IBOutlet NSPopUpButton *logLevelButton;
    __weak IBOutlet NSPopUpButton *autoClearButton;
    
    NSDictionary *index2level;
    NSDictionary *index2Interval;
    
    NSUInteger currentLogLevel;
}

- (void)initLogLevelSelection {
    for (NSNumber *index in index2level) {
        NSNumber *level = index2level[index];
        if ([level isEqualToNumber:@(ddLogLevel)]) {
            [logLevelButton selectItemAtIndex:[index unsignedIntValue]];
            break;
        }
    }
}

- (void)initAutoClearSelection {
    for (NSNumber *index in index2Interval) {
        NSNumber *interval = index2level[index];
        if ([interval isEqualToNumber:@([ConfigManager shared].autoClearInterval)]) {
            [autoClearButton selectItemAtIndex:[index unsignedIntValue]];
            break;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentLogLevel = ddLogLevel;
    
    index2level = @{
        @(0):@(DDLogLevelOff),
        @(1):@(DDLogLevelError),
        @(2):@(DDLogLevelWarning),
        @(3):@(DDLogLevelInfo),
        @(4):@(DDLogLevelDebug),
        @(5):@(DDLogLevelVerbose),
    };
    
    index2Interval = @{
        @(0):@(0),
        @(1):@(60),
        @(2):@(300),
        @(3):@(900),
        @(4):@(1800),
        @(5):@(3600),
    };
    
    [self initLogLevelSelection];
    [self initAutoClearSelection];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    
    ddLogLevel = [index2level[@(logLevelButton.indexOfSelectedItem)] unsignedIntValue];
    [ConfigManager shared].autoClearInterval = [index2Interval[@(autoClearButton.indexOfSelectedItem)] unsignedIntValue];
    
    [[ConfigManager shared] saveMiscSetting];
    
    if (currentLogLevel != ddLogLevel) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLogLevelChangeKey object:nil];
    }
}

@end
