//
//  MediaViewController.h
//  UFO
//
//    
//

#import <UIKit/UIKit.h>
#import "Recording.h"
#import "AudioRecordingDelegate.h"

@class MediaViewController;

@interface MediaViewController :UIViewController

@property(nonatomic, strong) Recording *recording;
@property(nonatomic, strong) id<AudioRecordingDelegate> delegate;

- (instancetype) initWithDelegate: (id<AudioRecordingDelegate>) delegate;

@end
