//
//  MediaViewController.h
//  UFO
//
//    
//

#import <UIKit/UIKit.h>
#import "Recording.h"

@protocol AudioRecordingDelegate;

@class MediaViewController;

@interface MediaViewController :UIViewController

@property(nonatomic, strong) Recording *recording;
@property(nonatomic, strong) id<AudioRecordingDelegate> audioRecordingDelegate;

- (instancetype) initWithDelegate: (id<AudioRecordingDelegate>) audioRecordingDelegate;

@end
