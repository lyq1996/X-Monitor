//
//  ProcUtils.h
//  X-Service
//
//  Created by lyq1996 on 2023/5/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProcUtils : NSObject

+ (NSString *)getPathFromPid:(NSNumber *)pid;
+ (NSNumber *)getCreatetimeFromPid:(NSNumber *)pid;
+ (NSString *)getCmdlineFromPid:(NSNumber *)pid;
+ (nullable NSDictionary *)getCodeSigningFromPid:(NSString *)path;

@end


NS_ASSUME_NONNULL_END
