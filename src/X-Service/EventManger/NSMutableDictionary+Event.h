//
//  Event.h
//  X-Service
//
//  Created by lyq1996 on 2023/2/9.
//

#ifndef Event_h
#define Event_h

#import <Foundation/Foundation.h>

/*
 common event field
 */
#define kEventIdentifyKey           @"eventIdentify"
#define kEventTypeKey               @"eventType"
#define kNeedDiscisionKey           @"needDiscision"
#define kEventTimeKey               @"eventTime"

#define kPidKey                     @"pid"
#define kProcessCreateTimeKey       @"processCreateTime"
#define kProcessPathKey             @"processPath"
#define kProcessCmdlineKey          @"processCmdline"
#define kProcessCodesignFlagKey     @"processCodesignFlag"
#define kProcessSigningIDKey        @"processSigningID"
#define kProcessTeamIDKey           @"processTeamID"

#define kPPidKey                    @"ppid"
#define kParentCreateTimeKey        @"parentCreateTime"
#define kParentPathKey              @"parentPath"
#define kParentCmdlineKey           @"parentCmdline"
#define kParentCodesignFlagKey      @"parentCodesignFlag"
#define kParentSigningIDKey         @"parentSigningID"
#define kParentTeamIDKey            @"parentTeamID"

/*
 event properties field
 */
#define kPropertiesKey              @"properties"

/*
 the following field will be placed in properties
 */
#define kFileUIDKey                 @"fileUID"
#define kFileGIDKey                 @"fileGID"
#define kFileModeKey                @"fileMode"
#define kFileAccessTimeKey          @"fileAccessTime"
#define kFileModifyTimeKey          @"fileModifyTime"
#define kFileCreateTimeKey           @"fileCreateTime"
#define kFilePathKey                @"filePath"

#define kProcessStatKey             @"processStat"

/*
 event short info
 */
#define kShortInfokey               @"shortInfo"

/*
 event dictionary example:
 
 {
   "processCreateTime" : 1683790591,
   "processPath" : "/bin/bash",
   "eventType" : "notify_exec",
   "processCodesignFlag" : 570492929,
   "parentCreateTime" : 1683790591,
   "parentCmdline" : "sh -c ps -p 84092 | wc -l",
   "ppid" : 48167,
   "needDiscision" : false,
   "parentTeamID" : "",
   "eventTime" : 1683790591,
   "processTeamID" : "",
   "parentSigningID" : "com.apple.bash",
   "properties" : {
     "processCreateTime" : 1683790591,
     "processCodesignFlag" : 570492929,
     "processPath" : "/usr/bin/wc",
     "fileGID" : 0,
     "processTeamID" : "",
     "fileModifyTime" : 1669970636,
     "fileMode" : 33261,
     "fileUID" : 0,
     "fileCreateTime" : 1669970636,
     "processCmdline" : "wc -l",
     "fileAccessTime" : 1669970636,
     "filePath" : "/usr/bin/wc",
     "processSigningID" : "com.apple.wc"
   },
   "eventIdentify" : 4401074216,
   "processCmdline" : "",
   "pid" : 48169,
   "parentPath" : "/bin/bash",
   "processSigningID" : "com.apple.bash",
   "parentCodesignFlag" : 570492929
 }
 */

@interface NSMutableDictionary (Event)

+ (NSMutableDictionary *)getEmptyEvent;

@end


#endif /* Event_h */
