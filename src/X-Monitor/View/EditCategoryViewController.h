//
//  AddCategoryViewController.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/16.
//

#ifndef EditCategoryViewController_h
#define EditCategoryViewController_h

#import "EventCategory.h"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditCategoryViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, nullable) EventCategory *category;

@property (nonatomic, nullable) void (^completion)(void);

@end

NS_ASSUME_NONNULL_END

#endif
