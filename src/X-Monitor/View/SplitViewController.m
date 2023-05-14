//
//  SplitViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/7.
//

#import "SplitViewController.h"
#import "GlobalObserverKey.h"

@implementation SplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSidebarToggle:) name:kSidebarToggleKey object:nil];
}

- (void)handleSidebarToggle:(id)sender {
    [self toggleSidebar:sender];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
