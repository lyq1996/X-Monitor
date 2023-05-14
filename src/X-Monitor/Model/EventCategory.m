//
//  EventCategory.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/2/6.
//

#import "EventCategory.h"
#import "ConfigManager.h"

@implementation EventCategory

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.categoryDependence forKey:@"dependence"];
    [encoder encodeObject:self.categoryIcon forKey:@"icon"];
    [encoder encodeObject:self.categoryName forKey:@"name"];
    [encoder encodeBool:self.isCustomCategory forKey:@"isCustom"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _categoryDependence = [decoder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableSet class], [NSString class], nil] forKey:@"dependence"];
        _categoryIcon = [decoder decodeObjectOfClass:[NSString class] forKey:@"icon"];
        _categoryName = [decoder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _isCustomCategory = [decoder decodeBoolForKey:@"isCustom"];
    }
    return self;
}

@end
