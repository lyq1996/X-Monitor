//
//  MainView.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#import "MainViewController.h"
#import "GlobalObserverKey.h"

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInfoButtonClick:) name:kInfoClickKey object:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)splitViewWillResizeSubviews:(NSNotification *)notification {
    NSLog(@"%@", notification.userInfo);
    ;
}



- (void)handleInfoButtonClick:(id)sender {
    if (self.splitViewItems[1].isCollapsed) {
        [self.splitViewItems[1].animator setCollapsed:NO];
    }
    else {
        [self.splitViewItems[1].animator setCollapsed:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInfoImageChangeKey object:self userInfo:nil];
}

@end
