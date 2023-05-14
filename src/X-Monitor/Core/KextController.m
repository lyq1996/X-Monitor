//
//  KextController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/18.
//

#import "ExtensionController.h"
#import "HelperManager.h"
#import "HelperProtocol.h"
#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@implementation KextController {
    void (^handle)(WORK_RESULT, NSString *);
    dispatch_queue_t workQueue;
}

@synthesize workBrief;
@synthesize workType;

- (void)doWork:(void (^)(WORK_RESULT, NSString *))completionHandler {
    handle = completionHandler;
    
    DDLogDebug(@"try to get helper remote object");
    
#pragma mark [TODO] kext support
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (self->handle) {
            self->handle(WORK_FAILED, @"not support for now");
        }
    });
    
    /*
    // connection error handle
    void (^errorHandle)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"XPC proxy error: %@", error);
            if (self->handle) {
                self->handle(WORK_FAILED, [error localizedDescription]);
            }
        });
    };
    
    id<HelperProtocol> helper = [[HelperManager new] getHelper:errorHandle];

    if (helper == nil && self->handle) {
        DDLogError(@"get helper proxy failed");
        self->handle(WORK_FAILED, @"get helper proxy failed");
    }
    
    dispatch_async(workQueue, ^{
        NSURL *kextURL = [NSURL fileURLWithPath:[[[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingString:@"/"] stringByAppendingString:@KEXT_ID]];
        
        if (self.workType == LOAD_EXTENSION) {
            [helper installKernelExtension:kextURL kextID:@KEXT_ID reply:^(int ret){
                
                if (ret == kIOReturnSuccess) {
                    DDLogInfo(@"install kernel extension successed");
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (self->handle) {
                            self->handle(WORK_SUCCESSED, nil);
                        }
                    });
                } else {
                    DDLogError(@"install kernel extension failed, OSReturn: %d", ret);
                    NSString *error = [NSString stringWithFormat:@"install kernel extension failed, OSReturn: %d", ret];
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (self->handle) {
                            self->handle(WORK_FAILED, error);
                        }
                    });
                }
            }];
        }
    });
     */
}


- (void)cancel{
    handle = nil;
}

- (instancetype)initWithArgs:(WORK_TYPE)type {
    self = [super init];
    if (self != nil) {
        if (type == LOAD_EXTENSION) {
            workBrief = @"Loading kernel extension";
        }
        
        if (type == UNLOAD_EXTENSION) {
            workBrief = @"Unloading kernel extension";
        }
        
        workType = type;
        workQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

@end
