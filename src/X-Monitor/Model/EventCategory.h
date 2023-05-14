//
//  EventCategory.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/6.
//

#ifndef EventCategory_h
#define EventCategory_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventCategory : NSObject<NSSecureCoding>

// category name
@property (nonatomic) NSString *categoryName;

// category icon
@property (nonatomic, nullable) NSString *categoryIcon;

// category depend event type
// nil means category depen all current event type
@property (nonatomic, nullable) NSMutableSet<NSString *> *categoryDependence;

// can category be removed from categories
@property (nonatomic) BOOL isCustomCategory;

@end

NS_ASSUME_NONNULL_END

#endif
