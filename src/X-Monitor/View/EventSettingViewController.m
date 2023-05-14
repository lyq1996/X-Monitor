//
//  EventSettingViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/8.
//

#import "EventSettingViewController.h"
#import "EventSubscibleTableCell.h"
#import "EditCategoryViewController.h"
#import "ConfigManager.h"
#import "CoreManager.h"
#import "EventCategory.h"
#import "GlobalObserverKey.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation EventSettingViewController {
    __weak IBOutlet NSTableView *subscribledEvents;
    __weak IBOutlet NSOutlineView *eventCategories;
    __weak IBOutlet NSButton *restoreToDefault;
    __weak IBOutlet NSButton *addCategory;
    __weak IBOutlet NSButton *removeCategory;
    __weak IBOutlet NSButton *settingCategory;
    
    EventCategory *currentSelect;
    
    BOOL sidebarReload;
    BOOL editAble;
    ConfigManager *configManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    configManager = [ConfigManager shared];
    
    // if started
    if ([[CoreManager shared] status] == X_CORE_STARTED) {
        editAble = NO;
    }
    else {
        editAble = YES;
    }
    
    sidebarReload = NO;

    restoreToDefault.enabled = editAble;
    
    addCategory.enabled = editAble;
    removeCategory.enabled = NO;
    settingCategory.enabled = NO;
    
    [subscribledEvents setDelegate:self];
    [subscribledEvents setDataSource:configManager];
    
    [eventCategories setDelegate:self];
    [eventCategories setDataSource:configManager];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [configManager saveEventSetting];
    
    if (sidebarReload) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSidebarReloadKey object:nil];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
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
    if ([configManager.eventTypes containsObject:eventType]) {
        DDLogVerbose(@"set event type: %@ to enable", eventType);
        checkbox.state = YES;
    }
    else {
        DDLogVerbose(@"set event type: %@ to disable", eventType);
        checkbox.state = NO;
    }

    checkbox.action = @selector(checkboxClick:);
    checkbox.target = self;
    checkbox.enabled = editAble;
    checkbox.title = eventType;

    return cell;
}

#pragma mark Outline view delegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSString *columnID = tableColumn.identifier;
    NSTableCellView *cell = [outlineView makeViewWithIdentifier:columnID owner:self];
    [cell.textField setStringValue:[item categoryName]];
    NSImage *icon = [NSImage imageNamed:[item categoryIcon]];
    icon.size = NSMakeSize(20, 20);
    [cell.imageView setImage:icon];
    return cell;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    DDLogVerbose(@"sidebar selected change");
    if (eventCategories.selectedRow < 0 || eventCategories.selectedRow > [configManager.categories count] - 1) {
        DDLogVerbose(@"invalid sidebar selection: %ld", eventCategories.selectedRow);
        return;
    }
    
    EventCategory *category = [configManager.categories objectAtIndex:eventCategories.selectedRow];
    currentSelect = category;
    
    DDLogVerbose(@"outline view selected: %@", category.categoryName);
    
    removeCategory.enabled = category.isCustomCategory && editAble;
    settingCategory.enabled = category.isCustomCategory && editAble;
}

- (IBAction)removeCategoryClick:(id)sender {
    [configManager.categories removeObject:[configManager.categories objectAtIndex:eventCategories.selectedRow]];
    
    [eventCategories reloadData];
    self->sidebarReload = YES;

    [self->eventCategories selectRowIndexes: [NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (IBAction)checkboxClick:(id)sender {
    NSButton *checkbox = (NSButton *)sender;
    NSString *eventType = checkbox.title;
    if (checkbox.state == NO) {
        DDLogDebug(@"remove event type: %@ from subscrible", eventType);
        [configManager.eventTypes removeObject:eventType];
    }
    else {
        DDLogDebug(@"add event type: %@ to subscrible", eventType);
        [configManager.eventTypes addObject:eventType];
    }
    return;
}

- (IBAction)restoreToDefaultClick:(id)sender {
    [configManager restoreEventSettingToDefault];
    [subscribledEvents reloadData];
    [eventCategories reloadData];
    sidebarReload = YES;
}

- (IBAction)settingCategoryClick:(id)sender {
    EditCategoryViewController *editCategory = [[NSStoryboard mainStoryboard] instantiateControllerWithIdentifier:@"EditCategory"];
    editCategory.category = currentSelect;
    editCategory.completion = ^() {
        [self->eventCategories reloadData];
        self->sidebarReload = YES;
    };
    [self presentViewControllerAsSheet:editCategory];
}

- (IBAction)addingCategoryClick:(id)sender {
    EditCategoryViewController *editCategory = [[NSStoryboard mainStoryboard] instantiateControllerWithIdentifier:@"EditCategory"];
    editCategory.category = nil;
    editCategory.completion = ^() {
        [self->eventCategories reloadData];
        self->sidebarReload = YES;
    };
    [self presentViewControllerAsSheet:editCategory];
}


@end
