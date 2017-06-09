//
//  SCAudioRecorder.m
//  StarCity
//
//  Created by Shadow on 2017/5/3.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "NSObject+Utils.h"
#import "SCAudioConvertorUtils.h"
#import "SCWeakProxy.h"
#import "SCAudioRecorderMonitor.h"

const CGFloat kSCAudioRecorderMaxRecordDuration = 3 * 60;

@interface SCAudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) SCAudioRecorderMonitor *monitor;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) SCWeakProxy *weakProxy;

@property (nonatomic, strong) AVAudioRecorder *recorder;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *amrURL;

@end

@implementation SCAudioRecorder

- (void)dealloc
{
    [self app_removeAllObserver];
    [self stopTimer];
    
    if (_monitor) {
        [_monitor changeMonitorStatus:SCAudioRecorderMonitorStatusIdle];
    }
}

- (SCWeakProxy *)weakProxy
{
    if (!_weakProxy) {
        _weakProxy = [SCWeakProxy proxyWithTarget:self];
    }
    return _weakProxy;
}

- (SCAudioRecorderMonitor *)monitor
{
    if (!_monitor) {
        _monitor = [SCAudioRecorderMonitor create];
    }
    
    return _monitor;
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithURL:url amrURL:nil];
}

- (instancetype)initWithURL:(NSURL *)url amrURL:(NSURL *)amrURL
{
    self = [super init];
    self.url = url;
    self.amrURL = amrURL;
    [self setup];
    return self;
}

- (void)createCacheFolderIfNeeded
{
    if (self.url) {
        NSString *wavPath = [self.url.relativePath stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager]fileExistsAtPath:wavPath]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:wavPath
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:nil];
        }
    }
    
    if (self.amrURL) {
        NSString *amrPath = [self.amrURL.relativePath stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager]fileExistsAtPath:amrPath]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:amrPath
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:nil];
        }
    }
}

- (void)setup
{
    [self createCacheFolderIfNeeded];
    [self app_addObserver:AVAudioSessionInterruptionNotification
                 selector:@selector(onInterruption:)];
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc]initWithURL:self.url
                                               settings:[self recorderSettings]
                                                  error:&error];
    self.recorder.meteringEnabled = YES;
    self.recorder.delegate = self;
    if (![self.recorder prepareToRecord]) {
        NSLog(@"audioRecorder -> 准备播放失败");
    }
}

- (NSDictionary *)recorderSettings
{
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    [settings setObject:@(8000) forKey:AVSampleRateKey];
    [settings setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    [settings setObject:@(1) forKey:AVNumberOfChannelsKey];
    [settings setObject:@(AVAudioQualityMedium) forKey:AVEncoderAudioQualityKey];
    return settings;
}

- (BOOL)isRecordValid
{
    AVAudioSessionRecordPermission permission = [AVAudioSession sharedInstance].recordPermission;
    if (permission == AVAudioSessionRecordPermissionDenied) {
        NSError *err = [NSError errorWithDomain:@"com.fatepair.audio_recorder"
                                           code:SCAudioRecorderErrorCodeNoPermission
                                       userInfo:nil];
        [self recordFailed:err];
        return NO;
    }
    
    return YES;
}

- (void)record
{
    if (![self isRecordValid]) {
        return;
    }
    
    if (!self.recorder) {
        [self recordFailed:nil];
        return;
    }
    
    NSError *error;
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord
                                          error:&error];
    if (error) {
        [self recordFailed:nil];
        return;
    }
    
    self.recorder.delegate = self;
    
    if ([self.recorder recordForDuration:kSCAudioRecorderMaxRecordDuration]) {
        [self startTimer];
        NSLog(@"audioRecorder -> 开始录制");
    } else {
        [self recordFailed:nil];
    }
}

- (void)stop
{
    if (!self.recorder.isRecording) {
        return;
    }
    
    if (self.recorder.currentTime < 1) {
        NSLog(@"audioRecorder -> 结束录制，时间太短");
        self.recorder.delegate = nil;
        [self stopTimer];
        [self recordTooShort];
    }
    
    NSLog(@"audioRecorder -> 结束录制");
    [self.recorder stop];
}

- (void)cancel
{
    if (!self.recorder.isRecording) {
        return;
    }
    
    NSLog(@"audioRecorder -> 取消录制");
    self.recorder.delegate = nil;
    [self stopTimer];
    [self.recorder stop];
}

- (void)recordFailed:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(audioRecorder:didFailed:)]) {
        [self.delegate audioRecorder:self didFailed:error];
    }
}

- (void)recordTooShort
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderTooShortToCancel:)]) {
        [self.delegate audioRecorderTooShortToCancel:self];
    }
}

- (void)encodeAudioFile
{
    if (!self.amrURL) {
        [self notifyDelegateRecordFinished];
        return;
    }
    
    [SCAudioConvertorUtils convertWav:self.url.relativePath toAmr:self.amrURL.relativePath];
    
    [self notifyDelegateRecordFinished];
}

- (void)notifyDelegateRecordFinished
{
    if ([self.delegate respondsToSelector:@selector(audioRecorder:didFinishRecord:amr:)]) {
        [self.delegate audioRecorder:self didFinishRecord:self.url amr:self.amrURL];
    }
}

#pragma mark - Monitor

- (void)changeMonitorStatus:(SCAudioRecorderMonitorStatus)status
{
    if (!self.monitorViewEnabled) {
        return;
    }
    
    [self.monitor changeMonitorStatus:status];
}

- (void)changeMonitorLevel:(float)level
{
    if (!self.monitorViewEnabled) {
        return;
    }
    
    [self.monitor changeMonitorLevel:level];
}

#pragma mark - Meter

- (void)startTimer
{
    [self stopTimer];
    self.timer = [NSTimer timerWithTimeInterval:0.3
                                         target:self.weakProxy
                                       selector:@selector(levelTimerCallback:)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    if (self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)levelTimerCallback:(NSTimer *)timer
{
    [self.recorder updateMeters];
    
    float   level = 0;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels = [self.recorder averagePowerForChannel:0];
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        level = powf(adjAmp, 1.0f / root);
    }
    
    if ([self.delegate respondsToSelector:@selector(audioRecorder:didUpdateSoundLevel:)]) {
        [self.delegate audioRecorder:self didUpdateSoundLevel:level];
    }
    
    [self changeMonitorLevel:level];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [self stopTimer];
    
    if (!flag) {
        NSLog(@"audioRecorder -> 结束录制回调，录制失败");
        [self recordFailed:nil];
    } else {
        NSLog(@"audioRecorder -> 结束录制回调，开始转换amr");
        [self encodeAudioFile];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
    [self stopTimer];
    NSLog(@"audioRecorder -> 录制错误回调，录制失败");
    [self recordFailed:error];
}

- (void)onInterruption:(NSNotification *)noti
{
    NSLog(@"audioRecorder -> 录制中断回调");
    NSNumber *typeObj = noti.userInfo[AVAudioSessionInterruptionTypeKey];
    AVAudioSessionInterruptionType type = typeObj.integerValue;
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self stopTimer];
        NSLog(@"audioRecorder -> 录制中断回调，开始中断，取消录制");
        [self cancel];
    }
}

#pragma mark - Helper

- (void)autoHandleRecordButtonAction:(UIControl *)button
{
    [button addTarget:self
               action:@selector(buttonTouchDown)
     forControlEvents:UIControlEventTouchDown];
    [button addTarget:self
               action:@selector(buttonTouchUp:event:)
     forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [button addTarget:self
               action:@selector(buttonDrag:event:)
     forControlEvents:UIControlEventTouchDragInside | UIControlEventTouchDragOutside];
    [button addTarget:self
               action:@selector(buttonCancel)
     forControlEvents:UIControlEventTouchCancel];
}

- (void)buttonTouchDown
{
    if (self.monitorViewEnabled) {
        [self changeMonitorStatus:SCAudioRecorderMonitorStatusRecording];
    }
    
    [self record];
}

- (void)buttonDrag:(UIButton *)button event:(UIEvent *)event
{
    if (!self.monitorViewEnabled) {
        return;
    }
    
    UITouch *touch = [[event allTouches] anyObject];
    CGFloat boundsExtension = 0.f;
    CGRect outerBounds = CGRectInset(button.bounds, -1 * boundsExtension, -1 * boundsExtension);
    BOOL touchOutside = !CGRectContainsPoint(outerBounds, [touch locationInView:button]);
    if (touchOutside) {
        BOOL previewTouchInside = CGRectContainsPoint(outerBounds, [touch previousLocationInView:button]);
        if (previewTouchInside) {
            [self changeMonitorStatus:SCAudioRecorderMonitorStatusCanceling];
            // UIControlEventTouchDragExit
        } else {
            // UIControlEventTouchDragOutside
        }
    } else {
        BOOL previewTouchOutside = !CGRectContainsPoint(outerBounds, [touch previousLocationInView:button]);
        if (previewTouchOutside) {
            [self changeMonitorStatus:SCAudioRecorderMonitorStatusRecording];
            // UIControlEventTouchDragEnter
        } else {
            // UIControlEventTouchDragInside
        }
    }
}

- (void)buttonTouchUp:(UIButton *)button event:(UIEvent *)event
{
    [self changeMonitorStatus:SCAudioRecorderMonitorStatusIdle];
    
    UITouch *touch = [[event allTouches] anyObject];
    CGFloat boundsExtension = 25.0f;
    CGRect outerBounds = CGRectInset(button.bounds, -1 * boundsExtension, -1 * boundsExtension);
    BOOL touchOutside = !CGRectContainsPoint(outerBounds, [touch locationInView:button]);
    if (touchOutside) {
        // UIControlEventTouchUpOutside
        //did cancel
        [self cancel];
    } else {
        // UIControlEventTouchUpInside
        //did end
        [self stop];
    }
}

- (void)buttonCancel
{
    [self changeMonitorStatus:SCAudioRecorderMonitorStatusIdle];
    //did cancel
    [self cancel];
}


@end
