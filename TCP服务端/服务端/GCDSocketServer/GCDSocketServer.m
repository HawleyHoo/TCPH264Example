//
//  ServerSocket.m
//  Socket服务端
//
//  Created by iMac1 on 16/2/24.
//  Copyright © 2016年 iMac1. All rights reserved.
//

#import "GCDSocketServer.h"


@interface GCDSocketServer ()

@property (nonatomic, strong) NSMutableData * dataContainer;

@property (nonatomic, strong) dispatch_queue_t dataPackageHandleQueue;

@end


@implementation GCDSocketServer

static NSData * byteHeader;

static char * const kSocketServerQueueKey = "kSocketServerQueue";


- (void)open {
    
    dispatch_queue_t queue = dispatch_queue_create(kSocketServerQueueKey, DISPATCH_QUEUE_SERIAL);
    
    
    self.dataPackageHandleQueue = dispatch_queue_create(kSocketServerQueueKey, DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_set_specific(self.dataPackageHandleQueue, kSocketServerQueueKey, "ture", NULL);
    dispatch_set_target_queue(self.dataPackageHandleQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    
    GCDAsyncSocket * serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:queue];
    
    NSError * error ;
    [serverSocket acceptOnPort:5279 error:&error];
    self.serverSocket = serverSocket;
    if (error) {
        NSLog(@"服务端打开失败");
    } else {
        NSLog(@"服务端打开成功");
    }
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    byteHeader = [NSData dataWithBytes:bytes length:length];
    
    self.dataContainer = [NSMutableData data];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    NSLog(@"与客户端失联:%@    %@",sock.connectedHost,error);
    
    [self.clientSockets removeAllObjects];
}


- (void)socket:(GCDAsyncSocket *)serverSockket didAcceptNewSocket:(GCDAsyncSocket *)clientSocket{
    [self.clientSockets addObject:clientSocket];
    
    NSLog(@"当前有%ld个客户端连接 serverSockket:%@   clientSocket:%@",self.clientSockets.count,serverSockket,clientSocket);
    
    NSString * message = @"握手成功，允许连接!\n";
    NSData * data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    [clientSocket writeData:data withTimeout:-1 tag:0];
    [clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag {
    
    //NSString * message = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    //if ([message isEqualToString:@"disconnect"]) {
       // [self.clientSockets removeObject:clientSocket];
    //} else {
        //dispatch_async(self.dataPackageHandleQueue, ^{
            
            [self handleDataPackage:data];
            
            [clientSocket readDataWithTimeout:-1 tag:0];
        //});
    //}
}


- (void)handleDataPackage:(NSData *)data {
    NSRange range = [data rangeOfData:byteHeader options:NSDataSearchBackwards range:NSMakeRange(0, data.length)];
    
    /// 以0000 0001开头且只有一个0000 0001
    if (range.location != NSNotFound && range.location == 0) {
        
        [self respondToDelegateThenCleanDataContainer];
        [self.dataContainer appendData:data];
        
        /// 有1个或者多个0000 0001，但不一定以0000 0001开头
    } else if (range.location != NSNotFound && range.location > 0) {
        
        /// 这里的延时很大
        [self handleDataPackage:[data subdataWithRange:NSMakeRange(0, range.location)]];
        [self handleDataPackage:[data subdataWithRange:NSMakeRange(range.location, data.length - range.location)]];
        
        /// 无0000 0001
    } else if (range.location == NSNotFound) {
        
        [self.dataContainer appendData:data];
    }
}


- (void)respondToDelegateThenCleanDataContainer {
    if (self.dataContainer.length) {
        if ([self.delegate respondsToSelector:@selector(socketDidReserveMessageFromClient:)]) {
            
            [self.delegate socketDidReserveMessageFromClient:[NSData dataWithData:self.dataContainer]];
        }
        
        [self.dataContainer resetBytesInRange:NSMakeRange(0, self.dataContainer.length)];
        [self.dataContainer setLength:0];
    }
}


- (NSMutableArray *)clientSockets{
    if (!_clientSockets) {
        _clientSockets = [[NSMutableArray alloc]init];
    }return _clientSockets;
}

- (void)disconnect{
    [self.clientSockets removeAllObjects];
}

@end
