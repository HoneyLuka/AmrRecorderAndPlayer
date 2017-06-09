//
//  SCAMRAudioPlayer.m
//  StarCity
//
//  Created by Shadow on 2017/5/23.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAMRAudioPlayer.h"
#import "SCAudioPlayer.h"
#import "SCAudioConvertorUtils.h"
#import "AppPaths.h"
#import <AVFoundation/AVFoundation.h>
#import "NSObject+Utils.h"
#import "UIView+Hud.h"
#import "SCAudioHelper.h"

NSString * const kSCAMRAudioPlayerStatusDidChangedEvent = @"kSCAMRAudioPlayerStatusDidChangedEvent";

const NSInteger kSCAMRAudioPlayerCacheLimit = 300;

@interface SCAMRAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, copy, readwrite) NSString *playingURL;
@property (nonatomic, copy) NSString *convertedURL;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation SCAMRAudioPlayer

+ (instancetype)sharedPlayer
{
    static SCAMRAudioPlayer *player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [SCAMRAudioPlayer new];
    });
    
    return player;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self app_addObserver:AVAudioSessionInterruptionNotification
                     selector:@selector(onInterruption:)];
        
        [self cleanIfNeeded];
        [self createFolderIfNeeded];
    }
    return self;
}

- (void)createFolderIfNeeded
{
    NSString *amrURL = [AppPaths amrTempPath];
    NSString *wavURL = [AppPaths wavTempPath];
    
    NSFileManager *f = [NSFileManager defaultManager];
    if (![f fileExistsAtPath:amrURL]) {
        [f createDirectoryAtPath:amrURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (![f fileExistsAtPath:wavURL]) {
        [f createDirectoryAtPath:wavURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)cleanIfNeeded
{
    NSString *amrURL = [AppPaths amrTempPath];
    NSString *wavURL = [AppPaths wavTempPath];
    
    NSFileManager *f = [NSFileManager defaultManager];
    
    NSArray *amrArray = [f contentsOfDirectoryAtPath:amrURL error:nil];
    if (amrArray.count >= kSCAMRAudioPlayerCacheLimit) {
        [f removeItemAtPath:amrURL error:nil];
    }
    
    NSArray *wavArray = [f contentsOfDirectoryAtPath:wavURL error:nil];
    if (wavArray.count >= kSCAMRAudioPlayerCacheLimit) {
        [f removeItemAtPath:wavURL error:nil];
    }
}

- (BOOL)isPlaying
{
    return self.playingURL != nil;
}

- (void)playAMR:(NSString *)amrURL
{
    self.playingURL = amrURL;
    [self postEvent];
    
    [self convertAMR:amrURL completion:^(NSString *wavURL) {
        
        NSString *name = [self fileNameForURL:amrURL];
        NSString *targetName = [self fileNameForURL:wavURL];
        
        //too late
        if (![name isEqualToString:targetName]) {
            return;
        }
        
        if (!wavURL) {
            [self playError];
            return;
        }
        
        [self playWav:wavURL];
    }];
}

#pragma mark - Player

- (void)playWav:(NSString *)wavURL
{
    [self stop];
    
    NSURL *fileURL = [NSURL fileURLWithPath:wavURL];
    NSError *error;
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
    
    if (error) {
        [self playError];
        return;
    }
    
    self.player.delegate = self;
    
    [SCAudioHelper changeToPlaybackMode];
    
    [self.player prepareToPlay];
    [self.player play];
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
        [self playFinished];
    }
}

#pragma mark - Action

- (void)playFinished
{
    self.playingURL = nil;
    [self postEvent];
}

- (void)playError
{
    [UIView app_toast:@"播放失败"];
    self.playingURL = nil;
    [self postEvent];
}

- (void)postEvent
{
    [self app_postEvent:kSCAMRAudioPlayerStatusDidChangedEvent];
}

- (void)onInterruption:(NSNotification *)noti
{
    NSLog(@"audioPlayer -> 中断回调");
    NSNumber *typeObj = noti.userInfo[AVAudioSessionInterruptionTypeKey];
    AVAudioSessionInterruptionType type = typeObj.integerValue;
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self stopAndNotify:YES];
        NSLog(@"audioPlayer -> 播放中断回调，开始中断，停止播放");
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        [self playFinished];
    } else {
        [self playError];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [self playError];
}

#pragma mark - AMR fetch

- (void)convertAMR:(NSString *)amrURL
        completion:(void(^)(NSString *wavURL))completion
{
    NSString *wavURLString = [self fileURLForWav:amrURL];
    if ([[NSFileManager defaultManager]fileExistsAtPath:wavURLString]) {
        completion(wavURLString);
        return;
    }
    
    NSString *amrURLString = [self fileURLForAMR:amrURL];
    if ([[NSFileManager defaultManager]fileExistsAtPath:amrURLString]) {
        [SCAudioConvertorUtils convertAmr:amrURLString toWav:wavURLString];
        completion(wavURLString);
        return;
    }
    
    [self requestAMR:amrURL
          completion:
     ^(BOOL finished) {
         if (finished) {
             completion(wavURLString);
             return;
         }
         
         completion(nil);
    }];
}

- (void)requestAMR:(NSString *)amrURL
        completion:(void(^)(BOOL finished))completion
{
    NSURL *url = [NSURL URLWithString:amrURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
         
         NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
         if (urlResponse.statusCode != 200 || !data.length || connectionError) {
             completion(NO);
             return;
         }
         
         NSString *targetAmrURL = [self fileURLForAMR:amrURL];
         if ([[NSFileManager defaultManager]fileExistsAtPath:targetAmrURL]) {
             [[NSFileManager defaultManager]removeItemAtPath:targetAmrURL error:nil];
         }
         
         if (![[NSFileManager defaultManager]createFileAtPath:targetAmrURL
                                                    contents:data
                                                  attributes:nil]) {
             completion(NO);
             return;
         }
         
         NSString *wavURL = [self fileURLForWav:amrURL];
         [SCAudioConvertorUtils convertAmr:targetAmrURL toWav:wavURL];
         completion(YES);
         return;
    }];
}

#pragma mark - Utils

- (NSString *)fileURLForWav:(NSString *)url
{
    NSString *name = [self fileNameForURL:url];
    NSString *fileURLString = [[AppPaths wavTempPath]stringByAppendingPathComponent:name];
    return fileURLString;
}

- (NSString *)fileURLForAMR:(NSString *)url
{
    NSString *name = [self fileNameForURL:url];
    NSString *fileURLString = [[AppPaths amrTempPath]stringByAppendingPathComponent:name];
    return fileURLString;
}

- (NSString *)fileNameForURL:(NSString *)url
{
    NSURL *urlObj = [NSURL URLWithString:url];
    return urlObj.lastPathComponent;
}


@end
