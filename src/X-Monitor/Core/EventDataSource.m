//
//  EventDataSource.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/14.
//

#import "GlobalObserverKey.h"
#import "EventDataSource.h"
#import "ConfigManager.h"
#import "EventCategory.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation EventDataSource {
    NSMutableArray<Event *> *allEvents;
    
    NSString *searchText;
}

- (instancetype)init {
    if (self = [super init]) {
        
        allEvents = [NSMutableArray array];
        _Events2Show = [NSMutableArray array];

        searchText = @"";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryChanged:) name:kCategorySetKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryEdited:) name:kCategoryEditKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearEvent:) name:kClearClickKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchChanged:) name:kSearchChangeKey object:nil];
        
    }
    return self;
}

- (void)searchChanged:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *newSearchText = userInfo[@"searchText"];
    DDLogDebug(@"search text: %@", searchText);
    
    if (![searchText isEqualToString:newSearchText]) {
        searchText = newSearchText;
        [_Events2Show removeAllObjects];
        
        EventCategory *category = [ConfigManager shared].currentCategory;
        
        for (Event *event in allEvents) {
            if (category.categoryDependence == nil || [category.categoryDependence containsObject:event.eventType]) {
                if ([searchText length] == 0 || [[event detailInfo] containsString:searchText]) {
                    [_Events2Show addObject:event];
                }
            }
        }
    }
}

- (void)clearEvent:(id)sender {
    [_Events2Show removeAllObjects];
    [allEvents removeAllObjects];
}

- (void)categoryChanged:(id)sender {
    EventCategory *category = [ConfigManager shared].currentCategory;
    [_Events2Show removeAllObjects];

    for (Event *event in allEvents) {
        if (category.categoryDependence == nil || [category.categoryDependence containsObject:event.eventType]) {
            [_Events2Show addObject:event];
        }
    }
    DDLogDebug(@"data source switch to: %@", category.categoryName);
}

- (void)categoryEdited:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    EventCategory *category = userInfo[@"editedCategory"];
    DDLogDebug(@"edit data source: %@", category.categoryName);
    if (category == [ConfigManager shared].currentCategory) {
        DDLogDebug(@"current data source edited: %@", category.categoryName);
    }

    [_Events2Show removeAllObjects];

    for (Event *event in allEvents) {
        if ([category.categoryDependence containsObject:event.eventType]) {
            [_Events2Show addObject:event];
        }
    }
}

- (void)addEvent:(Event *)event {
    
    [allEvents addObject:event];
    NSString *eventType = event.eventType;
    
    EventCategory *category = [ConfigManager shared].currentCategory;
    if (category.categoryDependence == nil || ([category.categoryDependence containsObject:eventType])) {
        
        if ([searchText length] == 0 || [[event detailInfo] containsString:searchText]) {
            [_Events2Show addObject:event];
        }
    }
}

@end
