//
//  MainWindowController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/4.
//

#import "MainWindowController.h"
#import "ServiceProtocol.h"
#import "GlobalObserverKey.h"
#import "ConfigManager.h"
#import "CoreManager.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation MainWindowController {
    __weak IBOutlet NSToolbarItem *startItem;
    __weak IBOutlet NSToolbarItem *nowItem;
    __weak IBOutlet NSToolbarItem *clearItem;
    __weak IBOutlet NSToolbarItem *processChainItem;
    __weak IBOutlet NSToolbarItem *infoItem;
    __weak IBOutlet NSToolbar *toolbar;

    TitlebarAccessoryViewController *additionalTitlebar;
}

- (void)configureAdditionalTitlebar {
    additionalTitlebar = [[self storyboard] instantiateControllerWithIdentifier:@"TitlebarAccessoryViewController"];
    additionalTitlebar.layoutAttribute = NSLayoutAttributeBottom;
    additionalTitlebar.fullScreenMinHeight = additionalTitlebar.view.bounds.size.height;
    [[self window] addTitlebarAccessoryViewController:additionalTitlebar];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.windowFrameAutosaveName = [[NSBundle mainBundle] bundleIdentifier];
    [self configureAdditionalTitlebar];
    
#pragma [TODO] save into preferences
    infoItem.image = [NSImage imageNamed:@"InfoSelect"];
    nowItem.image = [NSImage imageNamed:@"NowSelect"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initService:) name:kInitCoreServicekey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeInfoImage:) name:kInfoImageChangeKey object:nil];
}

- (void)initService:(id)sender {
    NSStoryboard *activationBoard = [NSStoryboard storyboardWithName:@"Activation" bundle:nil];
    NSWindowController *activationWindow = [activationBoard instantiateControllerWithIdentifier:@"ActivationWindow"];
    ActivationViewController *activationViewController = (ActivationViewController *)activationWindow.contentViewController;
    activationViewController.activation = YES;

    [self.window beginSheet:activationWindow.window completionHandler:^(NSModalResponse returnCode) {
        DDLogDebug(@"Sheet closed with return code: %ld", (long)returnCode);
        if (returnCode == ACTIVATION_SUCCESS) {
            CoreManager *coreManager = [CoreManager shared];
            XCoreError ret = [coreManager initCore];
            if (ret != X_CORE_SUCCESS) {
                DDLogError(@"init core service failed, will exit");
                [NSApp terminate:nil];
            }
        }
        else {
            [NSApp terminate:nil];
        }
    }];
}

- (IBAction)start:(id)sender {
    XCoreError ret;
    if ([CoreManager shared].status == X_CORE_STOPPED) {
        ret = [[CoreManager shared] startCore];
        if (ret == X_CORE_SUCCESS) {
            startItem.image = [NSImage imageNamed:@"StartSelect"];
        }
    }
    else if ([CoreManager shared].status == X_CORE_STARTED) {
        ret = [[CoreManager shared] stopCore];
        if (ret == X_CORE_SUCCESS) {
            startItem.image = [NSImage imageNamed:@"Start"];
        }
    }
    else {
        // should never happen status == X_CORE_UNINITED
    }
}

- (IBAction)now:(id)sender {
    if ([[nowItem.image name] isEqualToString:@"Now"]) {
        nowItem.image = [NSImage imageNamed:@"NowSelect"];
    }
    else {
        nowItem.image = [NSImage imageNamed:@"Now"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNowClickKey object:nil];
}

- (IBAction)clear:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kClearClickKey object:nil];
}

- (void)changeInfoImage:(id)sender {
    if ([[infoItem.image name] isEqualToString:@"Info"]) {
        infoItem.image = [NSImage imageNamed:@"InfoSelect"];
    }
    else {
        infoItem.image = [NSImage imageNamed:@"Info"];
    }
}

- (IBAction)info:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kInfoClickKey object:nil];
}

- (IBAction)processChain:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kExploreClickKey object:nil];
}

@end
