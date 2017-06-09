//
//  SCAudioRecorderMonitor.h
//  StarCity
//
//  Created by Shadow on 2017/5/19.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCAudioRecorder.h"

@interface SCAudioRecorderMonitor : UIView

- (void)changeMonitorStatus:(SCAudioRecorderMonitorStatus)status;
- (void)changeMonitorLevel:(float)level;

+ (instancetype)create;

@end
