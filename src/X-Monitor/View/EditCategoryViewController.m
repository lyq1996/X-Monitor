//
//  AddCategoryViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/16.
//

#import "EditCategoryViewController.h"
#import "ConfigManager.h"
#import "GlobalObserverKey.h"
#import "EventSubscibleTableCell.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation EditCategoryViewController {
    __weak IBOutlet NSTableView *eventDependence;
    __weak IBOutlet NSTextField *categoryName;
    __weak IBOutlet NSPopUpButton *categoryIcon;
    
    ConfigManager *configManager;
    
    NSMutableSet *currentEventDependence;
    
    NSArray *allIcons;
}

- (void)viewDidAppear {
    [super viewDidAppear];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    configManager = [ConfigManager shared];
    
    if (self.category != nil) {
        DDLogDebug(@"current category: %@", self.category.categoryName);
        currentEventDependence = [self.category.categoryDependence mutableCopy];
        categoryName.stringValue = self.category.categoryName;
    }
    else {
        currentEventDependence = [NSMutableSet set];
    }
    
    eventDependence.delegate = self;
    eventDependence.dataSource = configManager;
    
    [self initCatrgoryIcon];
}

- (void)initCatrgoryIcon {
    
    allIcons = @[
        NSImageNameAddTemplate,
        NSImageNameBluetoothTemplate,
        NSImageNameBonjour,
        NSImageNameBookmarksTemplate,
        NSImageNameCaution,
        NSImageNameComputer,
        NSImageNameEnterFullScreenTemplate,
        NSImageNameExitFullScreenTemplate,
        NSImageNameFolder,
        NSImageNameFolderBurnable,
        NSImageNameFolderSmart,
        NSImageNameFollowLinkFreestandingTemplate,
        NSImageNameHomeTemplate,
        NSImageNameIChatTheaterTemplate,
        NSImageNameLockLockedTemplate,
        NSImageNameLockUnlockedTemplate,
        NSImageNameNetwork,
        NSImageNamePathTemplate,
        NSImageNameQuickLookTemplate,
        NSImageNameRefreshFreestandingTemplate,
        NSImageNameRefreshTemplate,
        NSImageNameRemoveTemplate,
        NSImageNameRevealFreestandingTemplate,
        NSImageNameShareTemplate,
        NSImageNameSlideshowTemplate,
        NSImageNameStatusAvailable,
        NSImageNameStatusNone,
        NSImageNameStatusPartiallyAvailable,
        NSImageNameStatusUnavailable,
        NSImageNameStopProgressFreestandingTemplate,
        NSImageNameStopProgressTemplate,
        NSImageNameTrashEmpty,
        NSImageNameTrashFull,
        NSImageNameActionTemplate,
        NSImageNameSmartBadgeTemplate,
        NSImageNameIconViewTemplate,
        NSImageNameListViewTemplate,
        NSImageNameColumnViewTemplate,
        NSImageNameFlowViewTemplate,
        NSImageNameInvalidDataFreestandingTemplate,
        NSImageNameGoForwardTemplate,
        NSImageNameGoBackTemplate,
        NSImageNameGoRightTemplate,
        NSImageNameGoLeftTemplate,
        NSImageNameRightFacingTriangleTemplate,
        NSImageNameLeftFacingTriangleTemplate,
        NSImageNameMobileMe,
        NSImageNameMultipleDocuments,
        NSImageNameUserAccounts,
        NSImageNamePreferencesGeneral,
        NSImageNameAdvanced,
        NSImageNameInfo,
        NSImageNameFontPanel,
        NSImageNameColorPanel,
        NSImageNameUser,
        NSImageNameUserGroup,
        NSImageNameEveryone,
        NSImageNameUserGuest,
        NSImageNameMenuOnStateTemplate,
        NSImageNameMenuMixedStateTemplate,
        NSImageNameApplicationIcon,
        NSImageNameTouchBarAddDetailTemplate,
        NSImageNameTouchBarAddTemplate,
        NSImageNameTouchBarAlarmTemplate,
        NSImageNameTouchBarAudioInputMuteTemplate,
        NSImageNameTouchBarAudioInputTemplate,
        NSImageNameTouchBarAudioOutputMuteTemplate,
        NSImageNameTouchBarAudioOutputVolumeHighTemplate,
        NSImageNameTouchBarAudioOutputVolumeLowTemplate,
        NSImageNameTouchBarAudioOutputVolumeMediumTemplate,
        NSImageNameTouchBarAudioOutputVolumeOffTemplate,
        NSImageNameTouchBarBookmarksTemplate,
        NSImageNameTouchBarColorPickerFill,
        NSImageNameTouchBarColorPickerFont,
        NSImageNameTouchBarColorPickerStroke,
        NSImageNameTouchBarCommunicationAudioTemplate,
        NSImageNameTouchBarCommunicationVideoTemplate,
        NSImageNameTouchBarComposeTemplate,
        NSImageNameTouchBarDeleteTemplate,
        NSImageNameTouchBarDownloadTemplate,
        NSImageNameTouchBarEnterFullScreenTemplate,
        NSImageNameTouchBarExitFullScreenTemplate,
        NSImageNameTouchBarFastForwardTemplate,
        NSImageNameTouchBarFolderCopyToTemplate,
        NSImageNameTouchBarFolderMoveToTemplate,
        NSImageNameTouchBarFolderTemplate,
        NSImageNameTouchBarGetInfoTemplate,
        NSImageNameTouchBarGoBackTemplate,
        NSImageNameTouchBarGoDownTemplate,
        NSImageNameTouchBarGoForwardTemplate,
        NSImageNameTouchBarGoUpTemplate,
        NSImageNameTouchBarHistoryTemplate,
        NSImageNameTouchBarIconViewTemplate,
        NSImageNameTouchBarListViewTemplate,
        NSImageNameTouchBarMailTemplate,
        NSImageNameTouchBarNewFolderTemplate,
        NSImageNameTouchBarNewMessageTemplate,
        NSImageNameTouchBarOpenInBrowserTemplate,
        NSImageNameTouchBarPauseTemplate,
        NSImageNameTouchBarPlayPauseTemplate,
        NSImageNameTouchBarPlayTemplate,
        NSImageNameTouchBarQuickLookTemplate,
        NSImageNameTouchBarRecordStartTemplate,
        NSImageNameTouchBarRecordStopTemplate,
        NSImageNameTouchBarRefreshTemplate,
        NSImageNameTouchBarRemoveTemplate,
        NSImageNameTouchBarRewindTemplate,
        NSImageNameTouchBarRotateLeftTemplate,
        NSImageNameTouchBarRotateRightTemplate,
        NSImageNameTouchBarSearchTemplate,
        NSImageNameTouchBarShareTemplate,
        NSImageNameTouchBarSidebarTemplate,
        NSImageNameTouchBarSkipAhead15SecondsTemplate,
        NSImageNameTouchBarSkipAhead30SecondsTemplate,
        NSImageNameTouchBarSkipAheadTemplate,
        NSImageNameTouchBarSkipBack15SecondsTemplate,
        NSImageNameTouchBarSkipBack30SecondsTemplate,
        NSImageNameTouchBarSkipBackTemplate,
        NSImageNameTouchBarSkipToEndTemplate,
        NSImageNameTouchBarSkipToStartTemplate,
        NSImageNameTouchBarSlideshowTemplate,
        NSImageNameTouchBarTagIconTemplate,
        NSImageNameTouchBarTextBoldTemplate,
        NSImageNameTouchBarTextBoxTemplate,
        NSImageNameTouchBarTextCenterAlignTemplate,
        NSImageNameTouchBarTextItalicTemplate,
        NSImageNameTouchBarTextJustifiedAlignTemplate,
        NSImageNameTouchBarTextLeftAlignTemplate,
        NSImageNameTouchBarTextListTemplate,
        NSImageNameTouchBarTextRightAlignTemplate,
        NSImageNameTouchBarTextStrikethroughTemplate,
        NSImageNameTouchBarTextUnderlineTemplate,
        NSImageNameTouchBarUserAddTemplate,
        NSImageNameTouchBarUserGroupTemplate,
        NSImageNameTouchBarUserTemplate,
        NSImageNameTouchBarVolumeDownTemplate,
        NSImageNameTouchBarVolumeUpTemplate,
        NSImageNameTouchBarPlayheadTemplate,
    ];
    
    NSInteger index = 0;
    for (NSString *iconName in allIcons) {
        NSImage *icon = [NSImage imageNamed:iconName];
        icon.size =  NSMakeSize(20, 20);
        [categoryIcon addItemWithTitle:iconName];
        NSMenuItem *item = [categoryIcon itemAtIndex:index++];
        item.image = icon;
    }
    
    if (self.category != nil) {
        [categoryIcon selectItemWithTitle:self.category.categoryIcon];
    }
}

- (void)showAlertWindow:(NSString *)errorString {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Failed to save category"];
    [alert setInformativeText:errorString];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

- (IBAction)cancelClick:(id)sender {
    [self dismissViewController:self];
}

- (IBAction)saveClick:(id)sender {
    NSString *name = categoryName.stringValue;
    if (name.length == 0) {
        [self showAlertWindow:@"Please enter category name"];
        return;
    }
    
    if (currentEventDependence.count == 0) {
        [self showAlertWindow:@"Please select event for this category"];
        return;
    }
    
    if (self.category != nil) {
        self.category.categoryDependence = currentEventDependence;
        self.category.categoryName = name;
        self.category.categoryIcon = [categoryIcon selectedItem].title;
        
        NSDictionary *userInfo = @{
            @"editedCategory": self.category
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:kCategoryEditKey object:self userInfo:userInfo];
    }
    else {
        // check wheather category name is exist
        for (EventCategory *category in configManager.categories) {
            if ([category.categoryName isEqualToString:name]) {
                [self showAlertWindow:[NSString stringWithFormat:@"Category: \"%@\" is already exists", name]];
                return;
            }
        }
        
        EventCategory *category = [[EventCategory alloc] init];
        category.categoryDependence = currentEventDependence;
        category.categoryName = name;
        category.isCustomCategory = YES;
        category.categoryIcon = [categoryIcon selectedItem].title;
        [configManager.categories addObject:category];
    }

    if (self.completion) {
        self.completion();
    }
    
    [self dismissViewController:self];
}

#pragma mark Table view delegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    if (tableView == nil) {
        DDLogWarn(@"tableview was nil");
        return nil;
    }
    
    if (tableColumn != tableView.tableColumns[0]) {
        DDLogWarn(@"columns not columns[0], but we only has 1 columns");
        return nil;
    }
    
    if (row > tableView.numberOfRows) {
        DDLogWarn(@"row > numberOfRows");
        return nil;
    }
    
    if (row > [configManager.allEventTypes count]) {
        DDLogWarn(@"row > all event types");
        return nil;
    }
    
    NSString *eventType = configManager.allEventTypes[row];

    NSString *columnID = tableColumn.identifier;
    EventSubscibleTableCell *cell = [tableView makeViewWithIdentifier:columnID owner:self];

    NSButton *checkbox = cell.eventCheckBox;
    if (self.category != nil && [self.category.categoryDependence containsObject:eventType]) {
        DDLogVerbose(@"set event type: %@ to enable", eventType);
        checkbox.state = YES;
    }
    else {
        DDLogVerbose(@"set event type: %@ to disable", eventType);
        checkbox.state = NO;
    }

    checkbox.action = @selector(checkboxClick:);
    checkbox.title = eventType;

    return cell;
}

- (IBAction)checkboxClick:(id)sender {
    NSButton *checkbox = (NSButton *)sender;
    NSString *eventType = checkbox.title;
    if (checkbox.state == NO) {
        DDLogDebug(@"remove event type: %@ from selection", eventType);
        [currentEventDependence removeObject:eventType];
    }
    else {
        DDLogDebug(@"add event type: %@ to selection", eventType);
        [currentEventDependence addObject:eventType];
    }
    return;
}

@end
