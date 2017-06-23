//
//  ViewController.m
//  VTH264examples
//
//  Created by  on 16/5/3.
//  Copyright (c) 2016年 srd. All rights reserved.
//

#import "ViewController.h"
#import "AAPLEAGLLayer.h"
#import "config.h"

#import "GCDSocketClient.h"

@interface ViewController ()
{
    AVCaptureSession *captureSession;
    AVCaptureConnection* connectionVideo;
    AVCaptureDevice *cameraDeviceB;
    AVCaptureDevice *cameraDeviceF;
    
    BOOL cameraDeviceIsF;
    
    H264HwEncoderImpl *h264Encoder;
    AVCaptureVideoPreviewLayer *recordLayer;
    
     H264HwDecoderImpl *h264Decoder;
    AAPLEAGLLayer *playLayer;
}


@property (nonatomic, strong) GCDSocketClient * socketClient;
@end

@implementation ViewController

- (GCDSocketClient *)socketClient {
    if (!_socketClient) {
        _socketClient = [[GCDSocketClient alloc] init];
    }return _socketClient;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.socketClient connectToHost];
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.socketClient disconnect];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    cameraDeviceIsF = YES;
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == AVCaptureDevicePositionFront) {
            cameraDeviceF = device;
        }
        else if(device.position == AVCaptureDevicePositionBack)
        {
            cameraDeviceB = device;
        }
    }
    
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:h264outputWidth height:h264outputHeight];
     h264Encoder.delegate = self;
    
    h264Decoder = [[H264HwDecoderImpl alloc] init];
    h264Decoder.delegate = self;

    UIButton *kaiguanBtn = [[UIButton alloc] initWithFrame:CGRectMake(5,80,100,40)];
    [kaiguanBtn setTitle:@"开摄像头" forState:UIControlStateNormal];
    [kaiguanBtn setBackgroundColor:[UIColor redColor]];
    [kaiguanBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [kaiguanBtn addTarget:self
                       action:@selector(kaiguanBtnClick:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:kaiguanBtn];
    kaiguanBtn.selected = NO;

    
    UIButton *qianhouBtn = [[UIButton alloc] initWithFrame:CGRectMake(220,80,100,40)];
    [qianhouBtn setTitle:@"前后摄像头" forState:UIControlStateNormal];
    [qianhouBtn setBackgroundColor:[UIColor redColor]];
    [qianhouBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [qianhouBtn addTarget:self
                        action:@selector(qianhouBtnClick:)
              forControlEvents:UIControlEventTouchUpInside];
    qianhouBtn.selected = NO;
    [self.view addSubview:qianhouBtn];
    
    
    playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(160, 120, 160, 300)];
    playLayer.backgroundColor = [UIColor blackColor].CGColor;
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)kaiguanBtnClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected==YES)
    {
        [self stopCamera];
        [self initCamera:cameraDeviceIsF];
        [self startCamera];
    }
    else
    {
         [self stopCamera];
    }

}

-(void)qianhouBtnClick:(UIButton *)btn
{
    if (captureSession.isRunning==YES)
    {
        cameraDeviceIsF = !cameraDeviceIsF;
        NSLog(@"变位置");
        [self stopCamera];
        [self initCamera:cameraDeviceIsF];
        [self startCamera];

    }
}

- (void) initCamera:(BOOL)type
{
    NSError *deviceError;
    AVCaptureDeviceInput *inputCameraDevice;
    if (type==false)
    {
        inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDeviceB error:&deviceError];
    }
    else
    {
        inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDeviceF error:&deviceError];
    }
    AVCaptureVideoDataOutput *outputVideoDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
    outputVideoDevice.videoSettings = videoSettings;
    [outputVideoDevice setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:inputCameraDevice];
    [captureSession addOutput:outputVideoDevice];
    [captureSession beginConfiguration];
    
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];
    connectionVideo = [outputVideoDevice connectionWithMediaType:AVMediaTypeVideo];
#if TARGET_OS_IPHONE
    [self setRelativeVideoOrientation];
    
    NSNotificationCenter* notify = [NSNotificationCenter defaultCenter];
    [notify addObserver:self
               selector:@selector(statusBarOrientationDidChange:)
                   name:@"StatusBarOrientationDidChange"
                 object:nil];
#endif

    [captureSession commitConfiguration];
    recordLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    [recordLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
}


- (void) startCamera
{
    recordLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    [recordLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    recordLayer.frame = CGRectMake(0, 120, 160, 300);
    [self.view.layer addSublayer:recordLayer];
    [captureSession startRunning];
    [self.view.layer addSublayer:playLayer];
}
- (void) stopCamera
{
    [captureSession stopRunning];
    [recordLayer removeFromSuperlayer];
    [playLayer removeFromSuperlayer];
}

#pragma mark - 视频采集回调
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    /// 视频数据
    if (connection == connectionVideo) {
//        NSLog(@" %@", sampleBuffer);

        
        [h264Encoder encode:sampleBuffer];
    }
}

#pragma mark -  H264编码回调  H264HwEncoderImplDelegate
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    
    
//    [self.socketClient sendMessage:[NSData dataWithData:h264Data]];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
    
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    
//    NSLog(@"\n关键帧h264Data:%@\n.",h264Data);
//     [self.socketClient sendMessage:[NSData dataWithData:h264Data]];
    
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; 
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    
    
    NSLog(@"\n其他帧h264Data:%@\n.\n",h264Data);
    [self.socketClient sendMessage:h264Data];
    
    
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
    NSLog(@"\n decode后 其他帧h264Data:%@\n.\n",h264Data);
}
    
#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

#pragma mark -  方向设置

#if TARGET_OS_IPHONE
- (void)statusBarOrientationDidChange:(NSNotification*)notification {
    [self setRelativeVideoOrientation];
}

- (void)setRelativeVideoOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            connectionVideo.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            connectionVideo.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            connectionVideo.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            connectionVideo.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}
#endif
@end
