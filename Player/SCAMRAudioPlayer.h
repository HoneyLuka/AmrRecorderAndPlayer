//
//  SCAMRAudioPlayer.h
//  StarCity
//
//  Created by Shadow on 2017/5/23.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSCAMRAudioPlayerStatusDidChangedEvent;

@interface SCAMRAudioPlayer : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, copy, readonly) NSString *playingURL;

@property (nonatomic, strong) id tag;

- (void)playAMR:(NSString *)amrURL;

- (void)stop;
- (void)stopAndNotify:(BOOL)notify;

+ (instancetype)sharedPlayer;

@end
