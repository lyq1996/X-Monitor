//
//  SextControler.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#import "ExtensionController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <SystemExtensions/SystemExtensions.h>
#import <Foundation/Foundation.h>

extern DDLogLevel ddLogLevel;

@implementation SextController {
    // completion handle
    void (^handle)(WORK_RESULT, NSString *);
}

@synthesize workBrief;
@synthesize workType;

/**
 * @brief system extension request upgrade callback
 */
- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest OS_UNUSED *)request
                  actionForReplacingExtension:(OSSystemExtensionProperties *)existing
                                withExtension:(OSSystemExtensionProperties *)extension {
    
    DDLogInfo(@"Got the upgrade request (%@ -> %@); answering replace.", existing.bundleVersion, extension.bundleVersion);
    if (existing.bundleVersion != extension.bundleVersion || existing.bundleShortVersion != existing.bundleShortVersion) {
        return OSSystemExtensionReplacementActionReplace;
    }
    
    return OSSystemExtensionReplacementActionCancel;
}

/**
 * @brief system extension request user approval callback
 */
- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request {
    DDLogInfo(@"Request to control %@ awaiting approval.", request.identifier);
}

/**
 * @brief system extension request end callback
 */
- (void)request:(OSSystemExtensionRequest *)request
    didFinishWithResult:(OSSystemExtensionRequestResult)result {
    
    if (result == OSSystemExtensionRequestCompleted) {
        DDLogInfo(@"Request to control %@ succeeded [%zu].", request.identifier, (unsigned long)result);
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (self->handle) {
                self->handle(WORK_SUCCESSED, nil);
            }
        });
    } else if (result == OSSystemExtensionRequestWillCompleteAfterReboot) {
        DDLogInfo(@"Request to reboot to complete.");

        dispatch_async(dispatch_get_main_queue(), ^(){
            if (self->handle) {
                self->handle(WORK_SUCCESSED_NEED_REBOOT, nil);
            }
        });
    }
}

/**
 * @brief system extension request with error callback
 */
- (void)request:(OSSystemExtensionRequest *)request
    didFailWithError:(NSError *)error {

    if ([error code] == OSSystemExtensionErrorRequestCanceled) {
        DDLogInfo(@"Request to control %@ canceled: [%zu], assume successed", request.identifier, (unsigned long)[error code]);

        dispatch_async(dispatch_get_main_queue(), ^(){
            if (self->handle) {
                self->handle(WORK_SUCCESSED, nil);
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (self->handle) {
                self->handle(WORK_FAILED, [error localizedDescription]);
            }
        });
        
        DDLogInfo(@"Request to control %@ failed with error: [%@].", request.identifier, error);
    }
}

/*
 @berif load extension
 */
- (void)loadExtension {
    OSSystemExtensionRequest *request = nil;
    NSString *sextID = [NSString stringWithFormat:@"%s", SEXT_ID];
    dispatch_queue_t activeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    request = [OSSystemExtensionRequest activationRequestForExtension:sextID queue:activeQueue];
    if (request == nil) {
        DDLogError(@"Failed to init the activate request");
        if (self->handle) {
            handle(WORK_FAILED, @"Failed to init the activate request");
        }
        return;
    }
    
    request.delegate = (id<OSSystemExtensionRequestDelegate>)self;
    [[OSSystemExtensionManager sharedManager] submitRequest:request];
}

/*
 @berif unload extension
 @note  NOT USE, unload will always failed.
 */
- (void)unloadExtension {
    NSString *sextID = [NSString stringWithFormat:@"%s", SEXT_ID];

    OSSystemExtensionRequest *request = nil;
    dispatch_queue_t deactiveQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    request = [OSSystemExtensionRequest deactivationRequestForExtension:sextID queue:deactiveQueue];
    if (request == nil) {
        DDLogError(@"Failed to init the deactivate request");
        if (self->handle) {
            handle(WORK_FAILED, @"Failed to init the deactivate request");
        }
        return;
    }
    
    request.delegate = (id<OSSystemExtensionRequestDelegate>)self;
    [[OSSystemExtensionManager sharedManager] submitRequest:request];
}

- (void)doWork:(void (^)(WORK_RESULT, NSString *))completionHandler {
    handle = completionHandler;
    
    if (self.workType == LOAD_EXTENSION) {
        [self loadExtension];
    }
    
    if (self.workType == UNLOAD_EXTENSION) {
        [self unloadExtension];
    }
}

- (void)cancel{
    handle = nil;
}

- (instancetype)initWithArgs:(WORK_TYPE)type {
    self = [super init];
    if (self != nil) {
        if (type == LOAD_EXTENSION) {
            workBrief = @"Loading system extension";
        }
        
        if (type == UNLOAD_EXTENSION) {
            workBrief = @"Unloading system extension";
        }
        
        workType = type;
    }
    return self;
}

@end
