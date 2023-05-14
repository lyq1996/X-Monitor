//
//  AppDelegate.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#import "AppDelegate.h"
#import "GlobalObserverKey.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] postNotificationName:kInitCoreServicekey object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSNotification *)aNotification {
    return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)aboutClick:(id)sender {
    NSString *string = @"https://github.com/lyq1996/X-Monitor";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:string];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [string length])];
    NSDictionary *info = @{
        NSAboutPanelOptionCredits:attStr
    };
        
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:info];
}

@end
