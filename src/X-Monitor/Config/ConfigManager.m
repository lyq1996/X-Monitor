//
//  ConfigManager.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/6.
//

#import "ConfigManager.h"
#import "CoreManager.h"
#import "GlobalObserverKey.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

#define kCategoriesKey          @"setting_category"
#define kEventTypesKey          @"setting_event_type"
#define kAllEventTypesKey       @"setting_all_event_type"
#define kLogLevelKey            @"setting_log_level"
#define kAutoClearIntervalKey   @"setting_auto_clear"

#define kEventCategoryAll       @"All Event"

@interface ConfigManager()

@property NSUserDefaults *preference;

@end

@implementation ConfigManager

+ (instancetype)shared {
    static ConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _categories = [NSMutableArray array];
        _eventTypes = [NSMutableSet set];
        _allEventTypes = [NSMutableArray array];

        NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
        _currentSystemVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", version.majorVersion, version.minorVersion, version.patchVersion];
        
        _preference = [NSUserDefaults standardUserDefaults];
        
        [self registerDefaults];
    }
    return self;
}

- (void)registerDefaults {
    // default categories    
    DDLogInfo(@"init default categories");
    EventCategory *category = [[EventCategory alloc] init];
    category.categoryName = kEventCategoryAll;
    category.categoryIcon = @"NSStatusAvailableFlat";
    category.isCustomCategory = NO;
    
    NSMutableArray *defaultCategories = [NSMutableArray arrayWithArray:@[
        category,
    ]];
    NSData *defaultCategoriesData = [NSKeyedArchiver archivedDataWithRootObject:defaultCategories requiringSecureCoding:YES error:nil];

    DDLogInfo(@"init default event");
    
    NSMutableSet *defaultTypes = [NSMutableSet set];
    NSData *defaultTypesData = [NSKeyedArchiver archivedDataWithRootObject:defaultTypes requiringSecureCoding:YES error:nil];

    NSMutableArray *defaultAllEventType = [NSMutableArray array];
    NSData *defaultAllEventTypeData = [NSKeyedArchiver archivedDataWithRootObject:defaultAllEventType requiringSecureCoding:YES error:nil];
    
    NSDictionary *defaults = @{
        kCategoriesKey: defaultCategoriesData,
        kEventTypesKey: defaultTypesData,
        kAllEventTypesKey: defaultAllEventTypeData,
        kLogLevelKey: [NSNumber numberWithInteger:ddLogLevel],
        kAutoClearIntervalKey: [NSNumber numberWithInteger:0],
    };
    
    [_preference registerDefaults:defaults];
}

- (void)initPreferences {
    
    NSData *categoriesPreferences = [self.preference objectForKey:kCategoriesKey];
    if (categoriesPreferences != nil) {
        NSError *error;
        NSArray *categoriesArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSString class], [EventCategory class], nil] fromData:categoriesPreferences error:&error];
        if (categoriesArray == nil) {
            DDLogError(@"Error unarchiving categories preferences: %@", error.localizedDescription);
            [self.preference setObject:nil forKey:kCategoriesKey];
        }
        else if ([categoriesArray count] == 0) {
            DDLogWarn(@"categories from preference was empty");
        }
        else {
            [self.categories removeAllObjects];
            [self.categories addObjectsFromArray:categoriesArray];
        }
        DDLogDebug(@"categories after read from preference: %@", self.categories);
    }

    NSData *eventTypePreferences = [self.preference objectForKey:kEventTypesKey];
    if (eventTypePreferences != nil) {
        NSError *error;
        NSSet *eventTypeSet = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSSet class], [NSString class], nil] fromData:eventTypePreferences error:&error];
        if (eventTypeSet == nil) {
            DDLogError(@"Error unarchiving event type preferences: %@", error.localizedDescription);
            [self.preference setObject:nil forKey:kEventTypesKey];
        }
        else if ([eventTypeSet count] == 0) {
            DDLogWarn(@"event type from preference was empty");
        }
        else {
            [self.eventTypes removeAllObjects];
            [self.eventTypes addObjectsFromArray:[eventTypeSet allObjects]];
        }
        DDLogDebug(@"eventType after read from preference: %@", self.eventTypes);
    }

    NSData *allEventTypePreferences = [self.preference objectForKey:kAllEventTypesKey];
    if (allEventTypePreferences != nil) {
        NSError *error;
        NSArray *allEventTypeArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSString class], nil] fromData:allEventTypePreferences error:&error];
        if (allEventTypeArray == nil) {
            DDLogError(@"Error unarchiving all event type preferences: %@", error.localizedDescription);
            [self.preference setObject:nil forKey:kAllEventTypesKey];
        }
        else if ([allEventTypeArray count] == 0) {
            DDLogInfo(@"empty all event type, maybe first launch");
        }
        else {
            [self.allEventTypes removeAllObjects];
            [self.allEventTypes addObjectsFromArray:allEventTypeArray];
        }
        DDLogDebug(@"all eventType after read from preference: %@", self.allEventTypes);
    }

    NSNumber *logLevel = [self.preference objectForKey:kLogLevelKey];
    if (logLevel == nil) {
        DDLogError(@"read log level from preference failed, use default value");
        [self.preference setObject:nil forKey:kLogLevelKey];
        logLevel = [self.preference objectForKey:kLogLevelKey];
    }
    ddLogLevel = [logLevel unsignedIntValue];
    
    NSNumber *clearInterval = [self.preference objectForKey:kAutoClearIntervalKey];
    if (clearInterval == nil) {
        DDLogError(@"read auto clear interval from preference failed, use default value");
        [self.preference setObject:nil forKey:kAutoClearIntervalKey];
        clearInterval = [self.preference objectForKey:kAutoClearIntervalKey];
    }
    self.autoClearInterval = [clearInterval intValue];
}

- (void)saveEventSetting{
    NSError *error;
    NSData *categoriesData = [NSKeyedArchiver archivedDataWithRootObject:self.categories requiringSecureCoding:YES error:&error];
    if (categoriesData == nil) {
        DDLogError(@"serialize categories failed: %@", error.localizedDescription);
    }
    [self.preference setObject:categoriesData forKey:kCategoriesKey];
    DDLogDebug(@"categories saved into preferences");

    NSData *eventTypeData = [NSKeyedArchiver archivedDataWithRootObject:self.eventTypes requiringSecureCoding:YES error:&error];
    if (eventTypeData == nil) {
        DDLogError(@"serialize categories failed: %@", error.localizedDescription);
    }
    [self.preference setObject:eventTypeData forKey:kEventTypesKey];
    DDLogDebug(@"eventTypes saved into preferences");
    
    NSData *allEventTypeData = [NSKeyedArchiver archivedDataWithRootObject:self.allEventTypes requiringSecureCoding:YES error:&error];
    if (allEventTypeData == nil) {
        DDLogError(@"serialize categories failed: %@", error.localizedDescription);
    }
    [self.preference setObject:allEventTypeData forKey:kAllEventTypesKey];
    DDLogDebug(@"all eventTypes saved into preferences");
}

- (void)saveMiscSetting {
    NSNumber *logLevel = [NSNumber numberWithUnsignedInteger:ddLogLevel];
    [self.preference setObject:logLevel forKey:kLogLevelKey];
    DDLogDebug(@"log level saved into preferences");

    NSNumber *clearInterval = [NSNumber numberWithUnsignedInteger:self.autoClearInterval];
    [self.preference setObject:clearInterval forKey:kAutoClearIntervalKey];
    DDLogDebug(@"auto clear interval saved into preferences");
}

- (void)restoreEventTypesToDefault {
    DDLogDebug(@"resotre event type to default");
    [self.preference setObject:nil forKey:kEventTypesKey];
}

- (void)restoreEventCategoryToDefault {
    DDLogDebug(@"resotre categories to default");
    [self.preference setObject:nil forKey:kCategoriesKey];
}

- (void)restoreEventSettingToDefault {
    [self restoreEventTypesToDefault];
    [self restoreEventCategoryToDefault];
    [self initPreferences];
}

#pragma mark Sidebar outline view source delegate protocol
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
    // Maybe a table view is enough for us when the event category only has one tree-depth.
    // Do we really need an outline view?
    if (item == nil) {
        return [self.categories count];
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
    return self.categories[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

#pragma mark Settings event subscrible table view source delegate protocol
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.allEventTypes count];
}

@end
