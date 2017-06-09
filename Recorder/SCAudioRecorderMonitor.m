//
//  SCAudioRecorderMonitor.m
//  StarCity
//
//  Created by Shadow on 2017/5/19.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import "SCAudioRecorderMonitor.h"
#import "AppUtils.h"
#import "Masonry.h"

@interface SCAudioRecorderMonitor ()

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *levelViews;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;

@end

@implementation SCAudioRecorderMonitor

+ (instancetype)create
{
    SCAudioRecorderMonitor *view = [[[NSBundle mainBundle]loadNibNamed:@"SCAudioRecorderMonitor"
                                                                 owner:self
                                                               options:nil]lastObject];
    view.autoresizingMask = UIViewAutoresizingNone;
    
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(140));
        make.height.equalTo(@(115));
    }];
    
    return view;
}

- (void)changeMonitorLevel:(float)level
{
    NSInteger offset = 0;
    
    if (level < 0.2) {
        offset = 1;
    } else if (level < 0.4) {
        offset = 2;
    } else if (level < 0.6) {
        offset = 3;
    } else {
        offset = 4;
    }
    
    for (int i = 0; i < self.levelViews.count; i++) {
        UIView *levelView = self.levelViews[i];
        if (i < offset) {
            levelView.hidden = NO;
            continue;
        }
        
        levelView.hidden = YES;
    }
}

- (void)changeMonitorStatus:(SCAudioRecorderMonitorStatus)status
{
    switch (status) {
        case SCAudioRecorderMonitorStatusIdle:
            [self dismiss];
            break;
        case SCAudioRecorderMonitorStatusRecording:
            [self show];
            self.statusLabel.text = @"手指上滑，取消录音";
            break;
        case SCAudioRecorderMonitorStatusCanceling:
            [self show];
            self.statusLabel.text = @"松开手指，取消录音";
            break;
            
        default:
            [self dismiss];
            break;
    }
}

- (void)show
{
    if (!self.superview) {
        UIWindow *window = [AppUtils frontWindow];
        [window addSubview:self];
        
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(window);
        }];
    }
}

- (void)dismiss
{
    if (self.superview) {
        [self removeFromSuperview];
    }
}

@end
