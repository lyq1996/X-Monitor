//
//  EventTableViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/15.
//

#import "EventTableViewController.h"
#import "GlobalObserverKey.h"
#import "CoreManager.h"
#import "ConfigManager.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <objc/runtime.h>

extern DDLogLevel ddLogLevel;

@interface EventWrapper : NSObject

@property (nonatomic, strong) Event *event;
@property (nonatomic, copy) NSString *detailInfo;
@property (nonatomic, copy) NSString *shortInfo;

@end

@implementation EventWrapper

- (instancetype)initWithEvent:(Event *)event {
    self = [super init];
    if (self) {
        _event = event;
        _detailInfo = [self genJsonInfo:YES];
        _shortInfo = [self genShortInfo];
    }
    return self;
}

- (NSDictionary *)handleDictionary {
    NSMutableDictionary *baseProperties = [NSMutableDictionary dictionary];
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([Event class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:propertyName];
        id value = [_event valueForKey:key];
        if (value) {
            [baseProperties setObject:value forKey:key];
        } else {
            continue;
        }
    }
    free(properties);
    return baseProperties;
}

- (NSString *)genJsonInfo:(BOOL)betterOutput {
    NSDictionary *dictionary = [self handleDictionary];
    NSError *error = nil;
    NSData *eventJson = [NSJSONSerialization dataWithJSONObject:dictionary
                                                        options:betterOutput? NSJSONWritingPrettyPrinted | NSJSONWritingWithoutEscapingSlashes: NSJSONWritingWithoutEscapingSlashes
                                                          error:&error];
    if (error) {
        DDLogError(@"Error converting event object to JSON: %@", error.localizedDescription);
        return @"";
    }
    else {
        return [[NSString alloc] initWithData:eventJson encoding:NSUTF8StringEncoding];
    }
}

- (NSString *)genShortInfo {
    NSDictionary *dictionary = _event.EventInfo;
    NSError *error = nil;
    NSData *eventJson = [NSJSONSerialization dataWithJSONObject:dictionary
                                                        options:NSJSONWritingWithoutEscapingSlashes
                                                          error:&error];
    if (error) {
        DDLogError(@"Error converting event object to JSON: %@", error.localizedDescription);
        return @"";
    }
    else {
        return [[NSString alloc] initWithData:eventJson encoding:NSUTF8StringEncoding];
    }
}

@end

@interface EventTableViewController()<EventDataSourceDelagate>

@end

@implementation EventTableViewController {
    __weak IBOutlet NSTableView *eventTable;
    
    NSMutableArray<EventWrapper *> *allEvents;
    NSMutableArray<EventWrapper *> *showedEvents;
    
    CoreManager *manager;
    NSDateFormatter *dateFormatter;
    BOOL autoScroll;
    NSString *searchText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    manager = [CoreManager shared];
    eventTable.target = self;
    eventTable.delegate = self;
    eventTable.dataSource = self;
    
    allEvents = [NSMutableArray array];
    showedEvents = [NSMutableArray array];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    autoScroll = YES;
    searchText = @"";
    
    [manager.dataSource addEventSourceDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchAutoScroll:) name:kNowClickKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryChanged:) name:kCategorySetKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryEdited:) name:kCategoryEditKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearEvent:) name:kClearClickKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchChanged:) name:kSearchChangeKey object:nil];
    
    NSDate *fireTime = [NSDate dateWithTimeIntervalSinceNow:1.0];
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:fireTime interval:1.0 target:self selector:@selector(addTableRows) userInfo:nil repeats:YES];
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
    return [showedEvents count];
}

#pragma mark table view data delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *text;
    NSString *cellID;
    
    if (eventTable == nil) {
        return nil;
    }
    
    if (row > eventTable.numberOfRows || row > [showedEvents count]) {
        return nil;
    }
    
    EventWrapper *wrapper = [showedEvents objectAtIndex:row];
    Event *event = wrapper.event;
    
    if (tableColumn == tableView.tableColumns[0]) {
        NSNumber *eventTime = event.EventTime;
        NSDate *textTime = [NSDate dateWithTimeIntervalSince1970:[eventTime longLongValue]];
        text = [dateFormatter stringFromDate:textTime];
    }
    else if (tableColumn == tableView.tableColumns[1]) {
        text = event.EventType;
    }
    else if (tableColumn == tableView.tableColumns[2]) {
        NSNumber *pid = [event.EventProcess objectForKey:@"Pid"];
        text = [NSString stringWithFormat:@"%d", [pid intValue]];
    }
    else if (tableColumn == tableView.tableColumns[3]) {
        NSString *path = [[event.EventProcess objectForKey:@"ProcessPath"] lastPathComponent];
        text = path;
    }
    else if (tableColumn == tableView.tableColumns[4]) {
        text = wrapper.shortInfo;
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
    if (eventTable.selectedRowIndexes.count < 0 || eventTable.selectedRow > [showedEvents count]) {
        return;
    }

    EventWrapper *wrapper = [showedEvents objectAtIndex:eventTable.selectedRow];
    
    NSDictionary *userInfo = @{
        @"detailInfo": wrapper.detailInfo
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kEventInfoSetKey object:self userInfo:userInfo];
}

#pragma mark clear button clicked
- (void)clearEvent:(id)sender {
    [allEvents removeAllObjects];
    [showedEvents removeAllObjects];
    [self clearTableRows];

    DDLogDebug(@"table view rows cleared");
}

#pragma mark search changed
- (void)searchChanged:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *newSearchText = userInfo[@"searchText"];
    DDLogDebug(@"search text: %@", searchText);
    
    if (![searchText isEqualToString:newSearchText]) {
        searchText = newSearchText;
        [self updateShowedEvent];
    }
}

#pragma mark category changed
- (void)categoryChanged:(id)sender {
    [self updateShowedEvent];
}

#pragma mark category edited
- (void)categoryEdited:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    EventCategory *category = userInfo[@"editedCategory"];
    DDLogDebug(@"edit category: %@", category.categoryName);
    if (category == [ConfigManager shared].currentCategory) {
        DDLogDebug(@"current data source edited: %@", category.categoryName);
    }

    [self updateShowedEvent];
}

- (void)updateShowedEvent {
    EventCategory *category = [ConfigManager shared].currentCategory;
    [showedEvents removeAllObjects];

    for (EventWrapper *eventWrapper in allEvents) {
        if (category.categoryDependence == nil || [category.categoryDependence containsObject:eventWrapper.event.EventType]) {
            if ([searchText length] == 0 || [[eventWrapper detailInfo] containsString:searchText]) {
                [showedEvents addObject:eventWrapper];
            }
        }
    }
    
    [self clearTableRows];
    [self addTableRows];
    
    DDLogDebug(@"category: %@, category dependence: %@, search: %@", category.categoryName, category.categoryDependence, searchText);
}

- (void)clearTableRows {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSInteger i = 0; i < [eventTable numberOfRows]; ++i) {
        [indexes addIndex:i];
    }
    
    [eventTable beginUpdates];
    [eventTable removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideRight];
    [eventTable endUpdates];
}

- (void)addTableRows {
    if ([eventTable numberOfRows] == [showedEvents count]) {
        return;
    }
    
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSInteger i = [eventTable numberOfRows]; i < [showedEvents count]; ++i) {
        [indexes addIndex:i];
    }
    
    [eventTable beginUpdates];
    [eventTable insertRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideRight];
    [eventTable endUpdates];
    
    NSDictionary *userInfo = @{
        @"counts": @([showedEvents count])
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kCountsSetKey object:self userInfo:userInfo];
    
    if (eventTable.numberOfRows > 0 && autoScroll) {
        [eventTable scrollRowToVisible:eventTable.numberOfRows - 1];
    }
}

#pragma mark EventDataSourceDelagate protocol
- (void)OnEventDataSourceAdd:(nonnull Event *)event {
    dispatch_async(dispatch_get_main_queue(), ^(){
        EventWrapper *wrapper = [[EventWrapper alloc] initWithEvent:event];
        
        [self->allEvents addObject:wrapper];

        NSString *eventType = event.EventType;
        
        EventCategory *category = [ConfigManager shared].currentCategory;
        if (category.categoryDependence != nil && ![category.categoryDependence containsObject:eventType]) {
            return;
        }
        
        if ([self->searchText length] != 0 && ![wrapper.detailInfo containsString:self->searchText]) {
            return;
        }
        
        [self->showedEvents addObject:wrapper];
    });
}

@end
