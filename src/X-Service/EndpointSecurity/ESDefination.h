//
//  ESDefination.h
//  X-Monitor
//
//  Created by lyq1996 on 2023/5/7.
//

#ifndef ESDefination_h
#define ESDefination_h

#define kESProducerNotifyQueue      "com.lyq1996.X-Service.ESnotifyQueue"
#define kESProducerName             @"Endpoint Security Producer";

#pragma mark [todo] add event defination

typedef struct {
    // event type
    NSString *eventName;
    // is auth event
    BOOL isAuthEvent;
    // event handler create block
    BaseEventHandler *(^createEventHandle)(es_client_t *, const es_message_t *);
} ESEvent;

#endif /* ESDefination_h */
