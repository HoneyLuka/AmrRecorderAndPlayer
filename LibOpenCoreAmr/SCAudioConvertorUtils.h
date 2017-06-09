//
//  SCAudioConvertorUtils.h
//  StarCity
//
//  Created by Shadow on 2017/5/4.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCAudioConvertorUtils : NSObject

+ (void)convertWav:(NSString *)wavPath toAmr:(NSString *)amrPath;
+ (void)convertAmr:(NSString *)amrPath toWav:(NSString *)wavPath;

@end
