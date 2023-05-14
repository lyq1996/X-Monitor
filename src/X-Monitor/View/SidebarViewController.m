//
//  SidebarViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/4.
//

#import "SidebarViewController.h"
#import "ConfigManager.h"
#import "GlobalObserverKey.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>

extern DDLogLevel ddLogLevel;

@implementation SidebarViewController {
    __weak IBOutlet NSOutlineView *eventCategories;
    __weak IBOutlet NSSearchField *searchBox;
}

#pragma mark Sidebar outline view delegate

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
    if (eventCategories.selectedRow < 0 || eventCategories.selectedRow > [[ConfigManager shared].categories count] - 1) {
        DDLogVerbose(@"invalid sidebar selection: %ld", eventCategories.selectedRow);
        return;
    }
    
    [ConfigManager shared].currentCategory = [[ConfigManager shared].categories objectAtIndex:eventCategories.selectedRow];
    
    DDLogVerbose(@"sidebar selected: %@", [ConfigManager shared].currentCategory.categoryName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCategorySetKey object:self userInfo:nil];
}

- (void)selectLine:(NSInteger)row {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
    [self->eventCategories selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void)reloadOutlineView:(id)sender {
    [eventCategories reloadData];
    [self selectLine:0];
}

- (IBAction)searchBoxChanged:(NSSearchField *)sender {
   
    NSDictionary *userInfo = @{
        @"searchText": searchBox.stringValue
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kSearchChangeKey object:self userInfo:userInfo];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window makeFirstResponder:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadOutlineView:) name:kSidebarReloadKey object:nil];

    [eventCategories setDelegate:self];
    [eventCategories setDataSource:[ConfigManager shared]];
    [self selectLine:0];
}

@end
