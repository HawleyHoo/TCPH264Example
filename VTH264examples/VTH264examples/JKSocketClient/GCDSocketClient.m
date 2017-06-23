//
//  ClientSocket.m
//  客户端
//
//  Created by iMac1 on 16/2/24.
//  Copyright © 2016年 iMac1. All rights reserved.
//

#import "GCDSocketClient.h"

static const char * kGCDSocketClientQueue = "";

@interface GCDSocketClient ()


@end


@implementation GCDSocketClient

//- (NSMutableArray *)messageQueue {
//    if (!_messageQueue) {
//        _messageQueue = [[NSMutableArray alloc] init];
//    }return _messageQueue;
//}


- (void)connectToHost{
    
    dispatch_queue_t queue = dispatch_queue_create(kGCDSocketClientQueue, DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(queue, kGCDSocketClientQueue, "ture", NULL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:queue];
    }
    _clientSocket.userData = @"GCDSocketClient";
    [_clientSocket disconnect];
    
    NSError * error ;///192.168.0.230   192.168.0.214
    [self.clientSocket connectToHost:@"192.168.0.211" onPort:5278 error:&error];
    if (error) {
        NSLog(@"客户端连接失败");
    }else{
        NSLog(@"客户端连接成功");
    }
    
}

- (void)disconnect{
    NSData * data = [@"disconnect" dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)sendMessage:(NSData *)message {
    [self.clientSocket writeData:message withTimeout:-1 tag:0];
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"连接成功:   %@",sock);
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    NSString * message = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"来自服务端的消息:  %@",message);
    // 在这里跟各位童靴说下 ，很多碰到这种问题 ，开始的时候能够接收到返回的数据 过来一会就不能，经常这种情况，我看了下 大家都是把timeout写成 10啊 30啊固定的时间，这里我和大家解释下，这个函数的意义，readDataWithTimeout  它底层相当于开了线程等待接收数据 过了这个时间 就自动停止，-1表示一直接收  。
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"连接失败:   %@    error:%@ ",sock.userData, [err description]);
    [sock disconnect];
    if (err.code == 60) {
        NSLog(@"连接超时");
    }else{
        self.clientSocket = nil;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    [sock readDataWithTimeout:-1 tag:0];
}

@end
