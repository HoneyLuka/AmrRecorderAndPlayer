//
//  SCAudioPlayer.h
//  StarCity
//
//  Created by Shadow on 2017/5/23.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSCAudioPlayerStatusDidChangedEvent;

@interface SCAudioPlayer : NSObject

@property (nonatomic, strong) id tag;

@property (nonatomic, assign, readonly) BOOL isPlaying;

- (void)playAudioWithFileURL:(NSURL *)fileURL;
- (void)stop;
- (void)stopAndNotify:(BOOL)notify;

- (BOOL)isPlaying;

+ (instancetype)sharedPlayer;

@end
