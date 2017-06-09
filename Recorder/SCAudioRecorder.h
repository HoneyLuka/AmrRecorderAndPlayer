//
//  SCAudioRecorder.h
//  StarCity
//
//  Created by Shadow on 2017/5/3.
//  Copyright © 2017年 Tiaoshu Tech Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SCAudioRecorderErrorCode) {
    SCAudioRecorderErrorCodeNoPermission = -1,
};

typedef NS_ENUM(NSUInteger, SCAudioRecorderMonitorStatus) {
    SCAudioRecorderMonitorStatusIdle,
    SCAudioRecorderMonitorStatusRecording,
    SCAudioRecorderMonitorStatusCanceling,
};

@class SCAudioRecorder;
@protocol SCAudioRecorderDelegate <NSObject>

@optional

- (void)audioRecorder:(SCAudioRecorder *)recorder
      didFinishRecord:(NSURL *)fileURL
                  amr:(NSURL *)amrURL;

- (void)audioRecorderTooShortToCancel:(SCAudioRecorder *)recorder;
- (void)audioRecorder:(SCAudioRecorder *)recorder didFailed:(NSError *)error;
- (void)audioRecorder:(SCAudioRecorder *)recorder didUpdateSoundLevel:(float)level;

@end

@interface SCAudioRecorder : NSObject

@property (nonatomic, weak) id<SCAudioRecorderDelegate> delegate;

/**
 Show monitor view when recording. 
 You should call 'changeMonitorStatus:' manually to control monitor view status、show or hide.
 */
@property (nonatomic, assign) BOOL monitorViewEnabled;

- (instancetype)initWithURL:(NSURL *)url;

/**
 Auto convert to amr when amrURL is NOT null.
 */
- (instancetype)initWithURL:(NSURL *)url amrURL:(NSURL *)amrURL NS_DESIGNATED_INITIALIZER;

- (void)record;
- (void)stop;
- (void)cancel;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new  NS_UNAVAILABLE;

#pragma mark - Monitor control

- (void)changeMonitorStatus:(SCAudioRecorderMonitorStatus)status;

#pragma mark - Helper

- (void)autoHandleRecordButtonAction:(UIControl *)button;

@end
