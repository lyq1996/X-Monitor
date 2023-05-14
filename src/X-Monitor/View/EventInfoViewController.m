//
//  EventInfoViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/15.
//

#import "GlobalObserverKey.h"
#import "EventInfoViewController.h"

@implementation EventInfoViewController {
    __weak IBOutlet NSTextView *eventInfo;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInfoSet:) name:kEventInfoSetKey object:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)handleInfoSet:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *info = userInfo[@"detailInfo"];
    [eventInfo setString:info];
}

@end
