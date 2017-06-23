//
//  ClientSocket.h
//  客户端
//
//  Created by iMac1 on 16/2/24.
//  Copyright © 2016年 iMac1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
@interface GCDSocketClient : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, strong)GCDAsyncSocket * clientSocket;

- (void)connectToHost;

- (void)disconnect;

- (void)sendMessage:(NSData *)message;

@end
