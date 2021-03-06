//
//  ViewController.m
//  服务端
//
//  Created by iMac1 on 16/2/24.
//  Copyright © 2016年 iMac1. All rights reserved.
//

#import "ViewController.h"
#import "GCDSocketServer.h"
#import "AAPLEAGLLayer.h"
#import "H264HwDecoderImpl.h"

#import <sys/socket.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <arpa/inet.h>

@interface ViewController () <GCDSocketServerDelegate, H264HwDecoderImplDelegate>
@property (nonatomic, strong)GCDSocketServer * serverSocket;


@property (nonatomic, strong) H264HwDecoderImpl * h264Decoder;

@property (nonatomic, strong) AAPLEAGLLayer *playLayer;
@end

@implementation ViewController

- (NSString *)getDeviceIPIpAddresses

{
    
    int sockfd =socket(AF_INET,SOCK_DGRAM, 0);
    
    //    if (sockfd <</span> 0) return nil;
    
    NSMutableArray *ips = [NSMutableArray array];
    
    
    
    int BUFFERSIZE = 4096;
    
    struct ifconf ifc;
    
    char buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
    
    struct ifreq * ifr, ifrcopy;
    
    ifc.ifc_len = BUFFERSIZE;
    
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd,SIOCGIFCONF, &ifc) >= 0){
        
        for (ptr = buffer; ptr < buffer + ifc.ifc_len; ){
            
            ifr = (struct ifreq *)ptr;
            
            int len =sizeof(struct sockaddr);
            
            if (ifr->ifr_addr.sa_len > len) {
                
                len = ifr->ifr_addr.sa_len;
                
            }
            
            ptr += sizeof(ifr->ifr_name) + len;
            
            if (ifr->ifr_addr.sa_family !=AF_INET) continue;
            
            if ((cptr = (char *)strchr(ifr->ifr_name,':')) != NULL) *cptr =0;
            
            if (strncmp(lastname, ifr->ifr_name,IFNAMSIZ) == 0)continue;
            
            memcpy(lastname, ifr->ifr_name,IFNAMSIZ);
            
            ifrcopy = *ifr;
            
            ioctl(sockfd,SIOCGIFFLAGS, &ifrcopy);
            
            if ((ifrcopy.ifr_flags &IFF_UP) == 0)continue;
            
            
            
            NSString *ip = [NSString stringWithFormat:@"%s",inet_ntoa(((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr)];
            
            [ips addObject:ip];
            
        }
        
    }
    
    close(sockfd);
    
    
    
    
    
    NSString *deviceIP =@"";
    
    for (int i=0; i < ips.count; i++)
        
    {
        
        if (ips.count >0)
            
        {
            
            deviceIP = [NSString stringWithFormat:@"%@",ips.lastObject];
            
        }
        
    }
    
    NSLog(@"deviceIP========%@",deviceIP);
    return deviceIP;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 200, 30)];
    label.text = [self getDeviceIPIpAddresses];
    label.textColor = [UIColor blackColor];
    [self.view addSubview:label];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    GCDSocketServer * serverSocket = [[GCDSocketServer alloc]init];
    self.serverSocket = serverSocket;
    serverSocket.delegate = self;
    
    
    self.h264Decoder = [[H264HwDecoderImpl alloc] init];
    self.h264Decoder.delegate = self;
    
    self.playLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    self.playLayer.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.4].CGColor;
    [self.view.layer addSublayer:self.playLayer];
}

- (IBAction)open:(id)sender {
    [self.serverSocket open];
    
}

- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer {
    if(imageBuffer) {
        self.playLayer.pixelBuffer = imageBuffer;
        
        /// 不能切换到其他线程，不然内存会暴涨
        CVPixelBufferRelease(imageBuffer);
    }
}


- (void)socketDidReserveMessageFromClient:(NSData *)h264Data{
    [self.h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}
@end
