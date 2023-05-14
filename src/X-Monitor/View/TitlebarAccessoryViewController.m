//
//  TitlebarAccessoryViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/4.
//

#import "TitlebarAccessoryViewController.h"
#import "GlobalObserverKey.h"
#import <Foundation/Foundation.h>

@implementation TitlebarAccessoryViewController {
    __weak IBOutlet NSButton *sidebarButton;
    __weak IBOutlet NSTextField *eventCountsText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sidebarButton.showsBorderOnlyWhileMouseInside = YES;
    [eventCountsText setStringValue:@"0"];
}

- (IBAction)sideBarClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSidebarToggleKey object:nil];
}

// change to eventcount source delegate
- (void)setEventCounts:(int)count {
    _eventCounts = count;
    [eventCountsText setStringValue:[NSString stringWithFormat:@"%d", count]];
}

- (int)getEventCounts {
    return _eventCounts;
}

@end
