//
//  ActivationViewController.m
//  X-Monitor
//
//  Created by lyq1996 on 2023/1/15.
//

#import "ActivationViewController.h"
#import "ExtensionController.h"
#import "HelperManager.h"
#import "ConfigManager.h"

#import <Foundation/Foundation.h>

@implementation ActivationViewController {
    __weak IBOutlet NSTextView *textView;
    __weak IBOutlet NSButton *retryButton;
    __weak IBOutlet NSButton *cancelButton;
    __weak IBOutlet NSProgressIndicator *indicator;

    NSMutableArray<id<ExtensionController>> *controllers;
    
    int retCode;
}

- (NSString *)addStrToNextLine:(NSString *)current next:(NSString *)next {
    return [NSString stringWithFormat:@"%@\n%@", current, next];
}

- (NSString *)addStrToTail:(NSString *)current tail:(NSString *)tail {
    return [NSString stringWithFormat:@"%@%@", current, tail];
}

- (NSString *)replaceLastLine:(NSString *)current replace:(NSString *)replace {
    NSRange lastComma = [current rangeOfString:@"\n" options:NSBackwardsSearch];

    if(lastComma.location != NSNotFound) {
        long newlineIndex = lastComma.location + 1;
        return [current stringByReplacingCharactersInRange:NSMakeRange(newlineIndex, [current length] - newlineIndex) withString: replace];
    } else {
        return current;
    }
}

- (IBAction)onRetry:(id)sender {
    [self doViewDidLoad];
}

- (IBAction)onCancel:(id)sender {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:retCode];
}

- (void)initSystemInfo {
    NSString *ver = [NSString stringWithFormat:@" ➡️ Current System: macOS %@", [ConfigManager shared].currentSystemVersion];
    [textView setString:ver];
}

- (void)initControllers:(BOOL)activation {
    [textView setString:[self addStrToNextLine:[textView string] next:@" ➡️ Initializing controllers"]];
    controllers = [NSMutableArray array];
    
    if (activation) {
        [controllers addObject:[[SextController alloc] initWithArgs:LOAD_EXTENSION]];
    } else {
        [controllers addObject:[[SextController alloc] initWithArgs:UNLOAD_EXTENSION]];
    }
}

- (void)workDidFinished:(WORK_RESULT)status error:(NSString *)error {
    // update UI
    [textView setString:[self addStrToNextLine:[textView string] next:[NSString stringWithFormat:@" ➡️ %@", WORK_RESULT_STRING[status]]]];
    
    // remove first work
    [controllers removeObjectAtIndex:0];

    // do remain work
    if (status == WORK_SUCCESSED && [controllers count] > 0) {
        [self updateIndicatorIncremental];
        
        id<ExtensionController> controller = [controllers objectAtIndex:0];
        [textView setString:[self addStrToNextLine:[self->textView string] next:[NSString stringWithFormat:@" ➡️ %@", [controller workBrief]]]];
        
        [controller doWork:^(WORK_RESULT status, NSString *error){
            [self workDidFinished:status error:error];
        }];
    } else if (status == WORK_SUCCESSED) {
        // no remain work, set indicator to 100% directly
        [self updateIndicator:1.0];
        [textView setString:[self addStrToNextLine:[self->textView string] next:@" ➡️ All done ✅"]];
        
        [self->cancelButton setEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self->retCode = ACTIVATION_SUCCESS;
            [self onCancel:self];
        });
    } else {
        if (error != nil) {
            [textView setString:[self addStrToNextLine:[self->textView string] next:[NSString stringWithFormat:@" ➡️ Error: %@", error]]];
        }
        [self->retryButton setEnabled:YES];
    }
}

- (void)updateIndicator:(double)progress {
    double current = progress * indicator.maxValue;
    if (current <= indicator.maxValue) {
        indicator.doubleValue = current;
    }
}

- (void)updateIndicatorIncremental {
    double increment = (indicator.maxValue - indicator.doubleValue)/2;
    indicator.doubleValue = indicator.doubleValue + increment;
}

- (void)doViewDidLoad {
    retCode = ACTIVATION_FAIL;
    [retryButton setEnabled:NO];
    [self updateIndicator:0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self initSystemInfo];
        [self updateIndicator:0.2];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self initControllers:self.activation];
        [self updateIndicator:0.3];

        // Do the first work
        if ([self->controllers count] > 0) {
            id<ExtensionController> controller = [self->controllers objectAtIndex:0];
            [self->textView setString:[self addStrToNextLine:[self->textView string] next:[NSString stringWithFormat:@" ➡️ %@", [controller workBrief]]]];
            
            [controller doWork:^(WORK_RESULT status, NSString *error){
                [self workDidFinished:status error:error];
            }];
        } else {
            [self->textView setString:[self addStrToNextLine:[self->textView string] next:@" ➡️ Nothing to do"]];
        }
    });
}

- (void)viewDidDisappear {
    for (int i=0; i<[controllers count]; ++i) {
        [[controllers objectAtIndex:i] cancel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableParagraphStyle *textViewStyle =  [NSMutableParagraphStyle new];
    [textViewStyle setLineSpacing:5.0];
    [textView setDefaultParagraphStyle:textViewStyle];
    
    // disable sheet resizeable
    [self setPreferredContentSize:NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)];
    [textView setFont:[NSFont fontWithName:@"Helvetica" size:20]];

    [self doViewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end
