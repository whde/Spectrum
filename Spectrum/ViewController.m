//
//  ViewController.m
//  Spectrum
//
//  Created by OS on 2019/5/5.
//  Copyright © 2019 Whde. All rights reserved.
//


#import "ViewController.h"
#import "SpectrumView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import<CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>


@interface ViewController () <AVAudioRecorderDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong, nonatomic) UIButton *recordButton;
@property (strong, nonatomic) UILabel *tipLabel;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic,strong) AVCaptureAudioDataOutput *captureAudioDataOutput;
@property(strong,nonatomic) AVCaptureSession *captureSession;//数据传递

@property (strong, nonatomic) SpectrumView *spectrumView3;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak ViewController *weakSelf = self;
    //Example 3
    self.spectrumView3 = [[SpectrumView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.bounds)-150,190,300, 120)];
    self.spectrumView3.itemLevelCallback = ^() {
        
        /*
        [weakSelf.audioRecorder updateMeters];
        //取得第一个通道的音频，音频强度范围是-160到0
        float power= [weakSelf.audioRecorder peakPowerForChannel:0];
        weakSpectrum2.level = power;
        */
    };
    [self.view addSubview:self.spectrumView3];
    
    
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.tipLabel];
}


#pragma mark - getter 懒加载

- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[UIButton alloc]init];
        _recordButton.backgroundColor = [UIColor colorWithRed:253/255.f green:111/255.f blue:82/255.f alpha:1.0];
        _recordButton.layer.cornerRadius = 50;
        // 开始
        [_recordButton addTarget:self action:@selector(recordStart:) forControlEvents:UIControlEventTouchDown];
        // 取消
        [_recordButton addTarget:self action:@selector(recordCancel:) forControlEvents: UIControlEventTouchUpOutside];
        //完成
        [_recordButton addTarget:self action:@selector(recordFinish:) forControlEvents:UIControlEventTouchUpInside];
        //移出
        [_recordButton addTarget:self action:@selector(recordTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
        //移入
        [_recordButton addTarget:self action:@selector(recordTouchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    }
    return _recordButton;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.textColor = [UIColor lightGrayColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
- (AVAudioRecorder *)audioRecorder {
    if (!_audioRecorder) {
        [self setAudioSession];
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

#pragma mark - layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    self.recordButton.frame = CGRectMake(width / 2.f - 50.f, height - 120, 100.f, 100.f);
    self.tipLabel.frame = CGRectMake(0, height - 160, width, 30);
}


#pragma mark - ControlEvents

- (void)recordStart:(UIButton *)button {
    if (![self.audioRecorder isRecording]) {
        NSLog(@"录音开始");
        [self.audioRecorder record];
        self.tipLabel.text = @"正在录音";
        [self.captureSession startRunning];
        [self startAnimate];
    }
}


- (void)recordCancel:(UIButton *)button {
    
    if ([self.audioRecorder isRecording]) {
        NSLog(@"取消");
        [self.audioRecorder stop];
        self.tipLabel.text = @"";
        [self.captureSession stopRunning];
    }
}

- (void)recordFinish:(UIButton *)button {
    
    if ([self.audioRecorder isRecording]) {
        NSLog(@"完成");
        [self.audioRecorder stop];
        self.tipLabel.text = @"";
        
    }
    
}

- (void)recordTouchDragExit:(UIButton *)button {
    if([self.audioRecorder isRecording]) {
        self.tipLabel.text = @"松开取消";
        [self.captureSession stopRunning];
        [self stopAnimate];
    }
}

- (void)recordTouchDragEnter:(UIButton *)button {
    if([self.audioRecorder isRecording]) {
        self.tipLabel.text = @"正在录音";
        [self startAnimate];
    }
}


- (void)startAnimate {
    [self.spectrumView3 start];
}

- (void)stopAnimate {
    [self.spectrumView3 stop];
}



- (void)setAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];

    _captureSession = [[AVCaptureSession alloc]init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    NSError *error = nil;
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDev error:&error];
    
    if ([_captureSession canAddInput:audioIn]) {
        [_captureSession addInput:audioIn];
    }
    _captureAudioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    if([_captureSession canAddOutput:_captureAudioDataOutput]) {
        [_captureSession addOutput:_captureAudioDataOutput];
        dispatch_queue_t queue = dispatch_queue_create("myQueue",DISPATCH_QUEUE_CONCURRENT);
        [_captureAudioDataOutput setSampleBufferDelegate:self queue:queue];
        [_captureAudioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSMutableArray *dataArr = [[NSMutableArray alloc]init];
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    for( int y=0; y< audioBufferList.mNumberBuffers; y++ ){
        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
        Byte *frame = (Byte *)audioBuffer.mData;
        int d = audioBuffer.mDataByteSize;
        if (d==2048) {
            for(long i=0; i<50; i++) {
                long x1 = frame[40*i+1]<<8;
                long x2 = frame[40*i];
                short int w = x1 | x2;
                if (w > 32767) {
                    w = 32767;
                } else if (w < -32768) {
                    w = -32768;
                }
                float y =  w / 32767.0;
                [dataArr addObject:@(fabsf(y))];
            }
        }
    }
    
    [self.spectrumView3 setLevels:dataArr];
    CFRelease(blockBuffer);
}


/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
- (NSDictionary *)getAudioSetting {
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}


/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
- (NSURL *)getSavePath {
    
    //  在Documents目录下创建一个名为FileData的文件夹
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"AudioData"];
    NSLog(@"%@",path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if(!(isDirExist && isDir)) {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",path);
    }
    
    path = [path stringByAppendingPathComponent:@"myRecord.aac"];
    NSLog(@"file path:%@",path);
    NSURL *url=[NSURL fileURLWithPath:path];
    return url;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end

