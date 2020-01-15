#import "AudioRecorderViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MobileCoreServices/UTCoreTypes.h"

@interface AudioRecorderViewController ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>{
    BOOL isRecording;
    
}

@property (nonatomic,strong) NSString *voiceValue;
@property (nonatomic,strong) AVAudioRecorder * recorder;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *sliderTimer;
@property (nonatomic,strong) NSString *downloadedMediaPath;

@property (weak, nonatomic) IBOutlet UIButton *recordBarButton;
@property (strong,nonatomic) NSString *mediaFilePath;
@property (strong,nonatomic) NSString *recorderFilePath;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *trashButton;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (weak, nonatomic) IBOutlet UILabel *recordingLength;
@property (weak, nonatomic) IBOutlet UILabel *recordingStartTime;
@property (weak, nonatomic) IBOutlet UILabel *currentRecordingLength;
@property (weak, nonatomic) IBOutlet UIButton *useRecordingButton;

- (IBAction) dismissAndSetObservationMedia:(id)sender;
- (IBAction) startRecording;
- (IBAction) playRecording:(id)sender;
-(void) performRecording;
@end
@implementation AudioRecorderViewController

#pragma mark -
#pragma mark View Life Cycle

- (instancetype) initWithDelegate: (id<AudioRecordingDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    
    return self;
}

- (NSString * ) createFolderInTempDirectory {
    NSString *uuid = [[NSUUID new] UUIDString];
    NSString *mediaTempFolder = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), uuid];
    
    // Create a the actual directory
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaTempFolder])
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaTempFolder withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    return mediaTempFolder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaFilePath = [self createFolderInTempDirectory];
    
    isRecording = NO;
    
    [self setupView:NO];
}

- (void) setupView: (BOOL) recordingExists {
    [self.playButton setHidden:!recordingExists];
    [self.trashButton setHidden:!recordingExists];
    [self.playSlider setHidden:!recordingExists];
    [self.recordingStartTime setHidden:!recordingExists];
    [self.recordBarButton setEnabled:!recordingExists];
    [self.recordingLength setHidden:!recordingExists];
    [self.useRecordingButton setHidden:!recordingExists];
}

- (IBAction)deleteRecording:(id)sender {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath: self.recording.filePath error: &error];
    self.recording = nil;
    self.currentRecordingLength.text = @"00:00:00";
    [self setupView:NO];
}

#pragma
#pragma mark - Voice Recording

- (IBAction) startRecording {
    [self performSelectorInBackground:@selector(performRecording) withObject:nil];
}

-(void) performRecording {
    
    if (!isRecording) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.recordBarButton setImage: [UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        }];
        
        self.recording = [[Recording alloc]init];
        
        self.recording.mediaType = @"audio/mp4";
        isRecording = YES;
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *err = nil;
        [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
        if(err){
            NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
        [audioSession setActive:YES error:&err];
        err = nil;
        if(err) {
            NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
        
        NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithCapacity:0];
        [settings setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [settings setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
        [settings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        [settings setValue :[NSNumber numberWithInt:8] forKey:AVLinearPCMBitDepthKey];
        [settings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [settings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        //Encoder
        [settings setValue :[NSNumber numberWithInt:12000] forKey:AVEncoderBitRateKey];
        [settings setValue :[NSNumber numberWithInt:8] forKey:AVEncoderBitDepthHintKey];
        [settings setValue :[NSNumber numberWithInt:8] forKey:AVEncoderBitRatePerChannelKey];
        [settings setValue :[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
        
        NSNumber *num = [NSNumber numberWithLongLong:(long long)[[NSDate date] timeIntervalSince1970]];
        NSString *extensionName = [num stringValue];
        self.recording.fileName = [NSString stringWithFormat:@"%@%@%@",@"Voice_", extensionName, @".mp4"];
        self.recorderFilePath = [NSString stringWithFormat:@"%@/%@", self.mediaFilePath, self.recording.fileName];
        self.recording.filePath = self.recorderFilePath;
        NSLog(@"Recording path %@",self.recorderFilePath);
        
        NSURL *url = [NSURL fileURLWithPath:self.recorderFilePath];
        err = nil;
        self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
        if (!self.recorder || err != nil) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable To Record"
                                                                            message:[err localizedDescription]
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
        }
        
        BOOL audioHWAvailable = audioSession.inputAvailable;
        if (!audioHWAvailable) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                            message:@"Audio input hardware not available"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
        }
        
        //prepare to record
        [self.recorder setDelegate:self];
        [self.recorder prepareToRecord];
        self.recorder.meteringEnabled = YES;
        
        if (_sliderTimer != nil && _sliderTimer.isValid) {
            [_sliderTimer invalidate];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateRecordingLength) userInfo:nil repeats:YES];
        });
        
        // start recording
        [self.recorder record];
        
    } else {
        isRecording = NO;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.recordBarButton setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
        }];
        
        [self.recorder stop];
        if (_sliderTimer != nil && _sliderTimer.isValid) {
            [_sliderTimer invalidate];
        }
        _sliderTimer = nil;
    }
}

- (void)updateRecordingLength {
    double totalSeconds = self.recorder.currentTime;
    int seconds = (int)totalSeconds % 60;
    int minutes = ((int)totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    self.recordingLength.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    self.currentRecordingLength.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:recorder.url options:nil];
    CMTime time = asset.duration;
    double totalSeconds = CMTimeGetSeconds(time);
    self.recording.recordingLength = [NSNumber numberWithDouble:totalSeconds];
    
    int seconds = (int)totalSeconds % 60;
    int minutes = ((int)totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    self.recordingLength.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    self.currentRecordingLength.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    
    [self setupView:YES];
}

- (IBAction) playRecording:(id)sender{
    NSLog(@"Starting to play the sound");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSURL *url = [NSURL fileURLWithPath:self.recording.filePath];
    
    NSError *error;
    if (self.audioPlayer == nil) {
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        self.audioPlayer.delegate = self;
        [self.audioPlayer setVolume:1.0];
        self.audioPlayer.numberOfLoops = 0;
    }
    if (_audioPlayer.playing) {
        [self stopAudio];
    } else {
        [self playAudio];
    }
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"played the sound");
    [self stopAudio];
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Error playing the sound");
    [self stopAudio];
}

- (IBAction)playButtonPressed:(id)sender {
    if (_audioPlayer.playing) {
        [self stopAudio];
    } else {
        [self playAudio];
    }
}

- (void) stopAudio {
    if (_audioPlayer.isPlaying) {
        [_audioPlayer stop];
    }
    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [self updateSlider];
    [_sliderTimer invalidate];
}

- (void) playAudio {
    if (_sliderTimer != nil && _sliderTimer.isValid) {
        [_sliderTimer invalidate];
    }
    _sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    self.playSlider.maximumValue = _audioPlayer.duration;
    
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)updateSlider {
    // Update the slider about the music time
    self.playSlider.value = _audioPlayer.currentTime;
}

- (IBAction)sliderStartChange:(id)sender {
    [_audioPlayer stop];
    [_sliderTimer invalidate];
}

- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [_audioPlayer stop];
    [_audioPlayer setCurrentTime:self.playSlider.value];
    [self playAudio];
}



#pragma
#pragma mark - Media methods

- (IBAction) dismissAndSetObservationMedia:(id)sender{
    if (self.delegate) {
        [self.delegate recordingAvailable:self.recording];
    }
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//    }];
}

@end
