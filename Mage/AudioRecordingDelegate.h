//
//  AudioRecordingDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "Recording.h"

@protocol AudioRecordingDelegate <NSObject>

@required

- (void) recordingAvailable: (Recording *) recording;

@end
