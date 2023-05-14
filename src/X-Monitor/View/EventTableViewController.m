//
//  EventTableViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/15.
//

#import "EventTableViewController.h"
#import "GlobalObserverKey.h"
#import "CoreManager.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation EventTableViewController {
    __weak IBOutlet NSTableView *eventTable;
    CoreManager *manager;
    NSDateFormatter *dateFormatter;
    BOOL autoScroll;
}

- (void)updateEventTable {
    [eventTable reloadData];
    if (eventTable.numberOfRows > 0 && autoScroll) {
        [eventTable scrollRowToVisible:eventTable.numberOfRows - 1];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    manager = [CoreManager shared];
    eventTable.target = self;
    eventTable.delegate = self;
    eventTable.dataSource = self;
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    autoScroll = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchAutoScroll:) name:kNowClickKey object:nil];
    
    NSDate *fireTime = [NSDate dateWithTimeIntervalSinceNow:1.0];
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:fireTime interval:1.0 target:self selector:@selector(updateEventTable) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer fire];
}

- (void)switchAutoScroll:(id)sender {
    autoScroll = !autoScroll;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark table view data source delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[manager.dataSource Events2Show] count];
}

#pragma mark table view data delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *text;
    NSString *cellID;
    
    if (eventTable == nil) {
        return nil;
    }
    
    if (row > eventTable.numberOfRows || row > [[manager.dataSource Events2Show] count]) {
        return nil;
    }
    
    Event *event = [[manager.dataSource Events2Show] objectAtIndex:row];
    
    if (tableColumn == tableView.tableColumns[0]) {
        NSNumber *eventTime = event.eventTime;
        NSDate *textTime = [NSDate dateWithTimeIntervalSince1970:[eventTime longLongValue]];
        text = [dateFormatter stringFromDate:textTime];
    }
    else if (tableColumn == tableView.tableColumns[1]) {
        text = event.eventType;
    }
    else if (tableColumn == tableView.tableColumns[2]) {
        NSNumber *pid = event.pid;
        text = [NSString stringWithFormat:@"%d", [pid intValue]];
    }
    else if (tableColumn == tableView.tableColumns[3]) {
        NSString *path = [event.processPath lastPathComponent];
        text = path;
    }
    else if (tableColumn == tableView.tableColumns[4]) {
        text = [event shortInfo];
    }
    else {
        text = @"";
    }
    
    cellID = tableColumn.identifier;
    NSTableCellView *cell = [tableView makeViewWithIdentifier:cellID owner:self];
    if (cell != nil) {
        cell.textField.stringValue = text;
        return cell;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (eventTable.selectedRowIndexes.count < 0 || eventTable.selectedRow > [[manager.dataSource Events2Show] count]) {
        return;
    }

    Event *event = [[manager.dataSource Events2Show] objectAtIndex:eventTable.selectedRow];
    
    NSDictionary *userInfo = @{
        @"detailInfo": [event detailInfo]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kEventInfoSetKey object:self userInfo:userInfo];
}

@end
