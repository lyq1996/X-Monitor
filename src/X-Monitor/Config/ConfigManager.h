//
//  ConfigManager.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/6.
//

#import "EventCategory.h"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ConfigManager : NSObject<NSOutlineViewDataSource, NSTableViewDataSource>

// all supported event types (No default value)
@property (nonatomic) NSMutableArray<NSString *> *allEventTypes;

// all subscribed event types
@property (nonatomic) NSMutableSet<NSString *> *eventTypes;

// all event categories, which will show in sidebar
@property (nonatomic) NSMutableArray<EventCategory *> *categories;

// current selected category
@property (nonatomic) EventCategory *currentCategory;

@property (nonatomic, readonly) NSString* currentSystemVersion;

@property (nonatomic) NSUInteger autoClearInterval;

+ (instancetype)shared;

- (void)restoreEventSettingToDefault;
- (void)saveEventSetting;
- (void)saveMiscSetting;
- (void)initPreferences;

@end

NS_ASSUME_NONNULL_END
