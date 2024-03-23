//
//  main.m
//  X-
//
//  Created by lyq1996 on 2023/1/15.
//

#import "ServiceManager.h"
#import "ESProducer.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Foundation/Foundation.h>

#ifdef DEBUG
DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
DDLogLevel ddlogLevel = DDLogLevelInfo;
#endif

int main(int argc, char *argv[])
{
    // init log
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    [DDLog addLogger:fileLogger];
    DDOSLogger *logger = [[DDOSLogger alloc] init];
    [DDLog addLogger:logger];

    // init event manager
    EventManager *manager = [[EventManager alloc] init];
    
    // init service
    ServiceManager *service = [[ServiceManager alloc] initWithEventManager:manager];
    
    // init producer
    ESProducer *esProducer = [[ESProducer alloc] initProducerWithDelegate:manager withErrorManager:service];
    
    // add producer to event manager
    [manager attachProducer:esProducer];
    
    // start xpc listener
    [service start];
    dispatch_main();
}
