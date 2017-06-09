//
//  SCAudioPlayer.m
//  StarCity
//
//  Created by Shadow on 2017/5/23.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "NSObject+Utils.h"
#import "SCAudioHelper.h"

NSString * const kSCAudioPlayerStatusDidChangedEvent = @"kSCAudioPlayerStatusDidChangedEvent";

@interface SCAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation SCAudioPlayer

+ (instancetype)sharedPlayer
{
    static SCAudioPlayer *player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [SCAudioPlayer new];
    });
    
    return player;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self app_addObserver:AVAudioSessionInterruptionNotification
                     selector:@selector(onInterruption:)];
    }
    return self;
}

- (BOOL)isPlaying
{
    return self.player.isPlaying;
}

- (void)playAudioWithFileURL:(NSURL *)fileURL
{
    if (self.isPlaying) {
        [self stop];
    }
    
    NSError *err;
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&err];
    if (err) {
        self.player = nil;
        return;
    }
    self.player.delegate = self;
    
    [SCAudioHelper changeToPlaybackMode];
    
    [self.player prepareToPlay];
    [self.player play];
    
    [self postEvent];
}

- (void)stop
{
    [self stopAndNotify:NO];
}
- (void)stopAndNotify:(BOOL)notify
{
    [self.player stop];
    self.player = nil;
    
    if (notify) {
        [self postEvent];
    }
}

- (void)postEvent
{
    [self app_postEvent:kSCAudioPlayerStatusDidChangedEvent];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self postEvent];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    [self postEvent];
}

#pragma mark - Action

- (void)onInterruption:(NSNotification *)noti
{
    NSLog(@"audioPlayer -> 中断回调");
    NSNumber *typeObj = noti.userInfo[AVAudioSessionInterruptionTypeKey];
    AVAudioSessionInterruptionType type = typeObj.integerValue;
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self stop];
        [self postEvent];
        NSLog(@"audioPlayer -> 播放中断回调，开始中断，停止播放");
    }
}

@end
