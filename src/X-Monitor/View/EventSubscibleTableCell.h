//
//  EventSubscibleTableCell.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/4/8.
//

#ifndef EventSubscibleTableCell_h
#define EventSubscibleTableCell_h

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventSubscibleTableCell : NSTableCellView

@property (nullable, assign) IBOutlet NSButton *eventCheckBox;

@end

NS_ASSUME_NONNULL_END

#endif
