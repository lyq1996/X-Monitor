#  X-Service Atchitecture

## Service Manager
The Service Manager creates an XPC listener and accepts new connections from clients.

The Service Manager exports the following interface to clients:

```
- (void)handleClientCmd:(XServiceCommand)cmd withData:(nullable NSData *)data withCompletion:(void (^)(BOOL, NSData *))completion;
```

In this interface, the XServiceCommand enum includes the following values:
```
typedef enum : NSUInteger {
    X_SERVICE_PING,
    X_SERVICE_SUBSCIBLE_EVENT,
    X_SERVICE_START,
    X_SERVICE_STOP,
    X_SERVICE_DECISION_EVENT,
    X_SERVICE_GET_EVENT_TYPE,
    X_SERVICE_SET_LOG_LEVEL,
} XServiceCommand;
```

## Remote Consumer
Once the client connect to the service, a RemoteConsumer object will be created.

```
@interface RemoteConsumer : NSObject<ConsumerProtocol>

@property (readonly) pid_t remotePid;
@property (readonly) uint64_t counts;
@property (readonly) NSXPCConnection *remoteConnection;

- (instancetype)initWithConnection:(NSXPCConnection *)connection;

@end
```
And the RemoteConsumer object, will be stored in the service's remoteConsumers array along with its corresponding XPC connection. Whenever a remote client calls the handleClientCmd interface, the XPC connection is obtained through [NSXPCConnection currentConnection], and the RemoteConsumer object is retrieved. This design is intended to support multiple remote consumers in the future.

## Event Manager
Event manager receive event from producers, and dispatch event to consumers.

## Process Cache Consumer
The Process cache stores a dictionary of process information objects indexed by their process ID. The ProcessCache object implements the consumeEvent method that takes in an Event object but does nothing with it. This method just ensures that exec and fork events are subscribed to the consumer.

## Endpoint Security Producer
This producer generates endpoint security events for macOS. It handles events using the corresponding event handler and posts the events to the Event Manager.

# How X-Service works
 
X-Service main.m:
 ```
 int main(int argc, char *argv[])
{
    ...
    
    // init event manager
    EventManager *manager = [[EventManager alloc] init];
    
    // init service
    ServiceManager *service = [[ServiceManager alloc] initWithEventManager:manager];
    
    // init producer
    ESProducer *esProducer = [[ESProducer alloc] initProducerWithDelegate:manager withErrorManager:service];
    
    // add producer to event manager
    [manager addProducer:esProducer];
    
    // start xpc listener
    [service start];
}
```
## Flow chat
TODO
