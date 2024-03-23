//
//  ExtensionController.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#ifndef ExtensionController_h
#define ExtensionController_h

#import <Foundation/Foundation.h>

#define SEXT_ID "com.lyq1996.X-Service"
#define KEXT_ID "X-Monitor.kext"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WORK_TYPE) {
    LOAD_EXTENSION = 0x1,
    UNLOAD_EXTENSION = 0x1 << 1,
};

typedef NS_ENUM(NSInteger, WORK_RESULT) {
    WORK_SUCCESSED = 0x0,
    WORK_SUCCESSED_NEED_REBOOT = 0x1,
    WORK_FAILED = 0x1 << 1,
    WORK_RESERVER_STATUS = 0x1 << 2,
};

static const NSString * _Nonnull WORK_RESULT_STRING[] = {
    [WORK_SUCCESSED] = @"Successed ✅",
    [WORK_SUCCESSED_NEED_REBOOT] = @"Successed ✅, but system reboot needed 😢",
    [WORK_FAILED] = @"Failed ❌",
    [WORK_RESERVER_STATUS] = @"This is reserved work status ❌",
};

@protocol ExtensionController <NSObject>

/*
 @brief work type
 */
@property (nonatomic) WORK_TYPE workType;

/*
 @brief work description with brief text
 */
@property (nonatomic) NSString *workBrief;

/*
 @brief async do load or unload work
 @param completion block
 @note completionHandler should always be called in main thread
 */
- (void)doWork:(void (^)(WORK_RESULT, NSString *))completionHandler;

/*
 @brief cancel work
 @note cancel should always called in main thread
 */
- (void)cancel;

/*
 @brief init extension load or unload work
 @param type: work type
 */
- (instancetype)initWithArgs:(WORK_TYPE)type;

@end

@interface SextController : NSObject<ExtensionController>

@end

#endif /* ExtensionController_h */

NS_ASSUME_NONNULL_END
