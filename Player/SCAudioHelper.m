//
//  SCAudioHelper.m
//  StarCity
//
//  Created by Shadow on 2017/6/7.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAudioHelper.h"
#import <AVFoundation/AVFoundation.h>

@implementation SCAudioHelper

+ (BOOL)changeToPlaybackMode
{
    NSError *error;
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        return NO;
    }

//    UInt32 doChangeDefaultRoute = 1;
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
    
//    [[AVAudioSession sharedInstance]overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
//                                                      error:&error];
//    if (error) {
//        return NO;
//    }
    
    return YES;
}

@end
