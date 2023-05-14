//
//  Event.m
//  X-Service
//
//  Created by lyq1996 on 2023/4/15.
//

#import "NSMutableDictionary+Event.h"

@implementation NSMutableDictionary (Event)

+ (NSMutableDictionary *)getEmptyEvent {
    NSMutableDictionary *event= [NSMutableDictionary dictionary];
    [event setObject:@(-1) forKey:kEventIdentifyKey];
    [event setObject:@"" forKey:kEventTypeKey];
    [event setObject:@(-1) forKey:kNeedDiscisionKey];
    [event setObject:@(-1) forKey:kEventTimeKey];
    [event setObject:@(-1) forKey:kPidKey];
    [event setObject:@(-1) forKey:kProcessCreateTimeKey];
    [event setObject:@"" forKey:kProcessPathKey];
    [event setObject:@"" forKey:kProcessCmdlineKey];
    [event setObject:@(-1) forKey:kProcessCodesignFlagKey];
    [event setObject:@"" forKey:kProcessSigningIDKey];
    [event setObject:@"" forKey:kProcessTeamIDKey];

    [event setObject:@(-1) forKey:kPPidKey];
    [event setObject:@(-1) forKey:kParentCreateTimeKey];
    [event setObject:@"" forKey:kParentPathKey];
    [event setObject:@"" forKey:kParentCmdlineKey];
    [event setObject:@(-1) forKey:kParentCodesignFlagKey];
    [event setObject:@"" forKey:kParentSigningIDKey];
    [event setObject:@"" forKey:kParentTeamIDKey];
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [event setObject:properties forKey:kPropertiesKey];
    return event;
}

@end
