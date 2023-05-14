//
//  ActivationViewController.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#ifndef ActivationViewController_h
#define ActivationViewController_h

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    ACTIVATION_SUCCESS,
    ACTIVATION_FAIL,
} ActivationResult;

@interface ActivationViewController : NSViewController

@property (nonatomic) BOOL activation;

@end

NS_ASSUME_NONNULL_END

#endif
