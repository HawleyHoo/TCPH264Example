//
//  ServerSocket.h
//  Socket服务端
//
//  Created by iMac1 on 16/2/24.
//  Copyright © 2016年 iMac1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import <CFNetwork/CFNetwork.h>



@protocol GCDSocketServerDelegate <NSObject>

- (void)socketDidReserveMessageFromClient:(NSData *)message;

@end


@interface GCDSocketServer : NSObject <GCDAsyncSocketDelegate>
@property (nonatomic, weak)id <GCDSocketServerDelegate> delegate;

@property (nonatomic, strong)GCDAsyncSocket * serverSocket;

@property (nonatomic, strong)NSMutableArray * clientSockets;

- (void)open;

- (void)disconnect;

@end
