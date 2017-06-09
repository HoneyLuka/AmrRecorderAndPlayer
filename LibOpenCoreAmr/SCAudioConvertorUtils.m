//
//  SCAudioConvertorUtils.m
//  StarCity
//
//  Created by Shadow on 2017/5/4.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAudioConvertorUtils.h"
#import "voiceAmrFileCodec.h"

@implementation SCAudioConvertorUtils

+ (void)convertWav:(NSString *)wavPath toAmr:(NSString *)amrPath
{
    const char *cWavPath = [wavPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cArmPath = [amrPath cStringUsingEncoding:NSASCIIStringEncoding];
    EncodeWAVEFileToAMRFile(cWavPath, cArmPath, 1, 16);
}

+ (void)convertAmr:(NSString *)amrPath toWav:(NSString *)wavPath
{
    const char *cArmPath = [amrPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cWavPath = [wavPath cStringUsingEncoding:NSASCIIStringEncoding];
    DecodeAMRFileToWAVEFile(cArmPath, cWavPath);
}

@end
