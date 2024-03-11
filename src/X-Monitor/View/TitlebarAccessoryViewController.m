//
//  TitlebarAccessoryViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/4.
//

#import "TitlebarAccessoryViewController.h"
#import "GlobalObserverKey.h"
#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation TitlebarAccessoryViewController {
    __weak IBOutlet NSButton *sidebarButton;
    __weak IBOutlet NSTextField *eventCountsText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sidebarButton.showsBorderOnlyWhileMouseInside = YES;
    [eventCountsText setStringValue:@"0"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setEventCounts:) name:kCountsSetKey object:nil];
}

- (IBAction)sideBarClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSidebarToggleKey object:nil];
}

// change to eventcount source delegate
- (void)setEventCounts:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo || ![userInfo objectForKey:@"counts"]) {
        return;
    }
    
    DDLogDebug(@"current event counts: %@", userInfo[@"counts"]);
    [eventCountsText setStringValue:[NSString stringWithFormat:@"%d", [userInfo[@"counts"] intValue]]];
}

@end
