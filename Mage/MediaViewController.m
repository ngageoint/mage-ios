#import "MediaViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MobileCoreServices/UTCoreTypes.h"

@interface MediaViewController ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>{
    BOOL isRecording;

}

@property (nonatomic,strong) NSString *voiceValue;
@property (nonatomic,strong) AVAudioRecorder * recorder;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) NSString *downloadedMediaPath;

@property (weak, nonatomic) IBOutlet UIButton *recordBarButton;
@property (strong,nonatomic) NSString *mediaFilePath;
@property (strong,nonatomic) NSString *recorderFilePath;
@property (weak, nonatomic) IBOutlet UILabel *recordTime;
@property (weak, nonatomic) IBOutlet UIProgressView *recordingPlayProgress;

- (IBAction) dismissAndSetObservationMedia:(id)sender;
- (IBAction) startRecording;
- (IBAction) playRecording:(id)sender;
-(void) performRecording;
@end
@implementation MediaViewController

#pragma mark -
#pragma mark View Life Cycle

- (NSString * ) createFolderInTempDirectory {
    
    NSString *uuidString = (__bridge NSString*)CFUUIDCreateString(nil, CFUUIDCreate(nil));
    NSString *mediaTempFolder = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), uuidString];
    
    // Create a the actual directory
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaTempFolder])
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaTempFolder withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    return mediaTempFolder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mediaFilePath = [self createFolderInTempDirectory];
    
	isRecording = NO;
}

- (IBAction)deleteRecording:(id)sender {
}
    //NSNotification callback function
- (void)moviePlayerPlaybackStateDidChange:(NSNotification*)notification {
    MPMoviePlayerController *moviePlayer = notification.object;

    MPMoviePlaybackState playbackState = moviePlayer.playbackState;
    
    if(playbackState == MPMoviePlaybackStateStopped) {
        NSLog(@"MPMoviePlaybackStateStopped");
    } else if(playbackState == MPMoviePlaybackStatePlaying) {
        NSLog(@"MPMoviePlaybackStatePlaying");
    } else if(playbackState == MPMoviePlaybackStatePaused) {
        NSLog(@"MPMoviePlaybackStatePaused");
    } else if(playbackState == MPMoviePlaybackStateInterrupted) {
        NSLog(@"MPMoviePlaybackStateInterrupted");
    } else if(playbackState == MPMoviePlaybackStateSeekingForward) {
        NSLog(@"MPMoviePlaybackStateSeekingForward");
    } else if(playbackState == MPMoviePlaybackStateSeekingBackward) {
        NSLog(@"MPMoviePlaybackStateSeekingBackward");
    }
}

#pragma 
#pragma mark - Voice Recording

- (IBAction) startRecording{
        [self performSelectorInBackground:@selector(performRecording) withObject:nil];
}

-(void) performRecording{
    
    if(!isRecording){
        
        [self.recordBarButton setImage: [UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        
        self.recording = [[Recording alloc]init];

        self.recording.mediaType = @"audio/mp4";
        isRecording = YES;

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *err = nil;
        [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
        if(err){
            NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
            return;
        }
        [audioSession setActive:YES error:&err];
        err = nil;
        if(err){
            NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
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
        self.recording.fileName = [NSString stringWithFormat:@"%@%@",@"Voice_",extensionName];
        self.recorderFilePath = [NSString stringWithFormat:@"%@/%@.mp4", self.mediaFilePath, self.recording.fileName];
        self.recording.filePath = self.recorderFilePath;
        NSLog(@"Recording path %@",self.recorderFilePath);

        NSURL *url = [NSURL fileURLWithPath:self.recorderFilePath];
        err = nil;
        self.recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
        if(!self.recorder){
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle: @"Unable to record" message: [err localizedDescription] delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
            //prepare to record
        [self.recorder setDelegate:self];
        [self.recorder prepareToRecord];
        self.recorder.meteringEnabled = YES;
        
        BOOL audioHWAvailable = audioSession.inputAvailable;
        if (! audioHWAvailable) {
            UIAlertView *cantRecordAlert =
            [[UIAlertView alloc] initWithTitle: @"Warning" message: @"Audio input hardware not available" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [cantRecordAlert show];
            return;
        }
            // start recording
        [self.recorder record];
        
    }else{
        isRecording = NO;
        [self.recordBarButton setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
		[self.recorder stop];
    }
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:recorder.url options:nil];
    CMTime time = asset.duration;
    double totalSeconds = CMTimeGetSeconds(time);
    self.recording.recordingLength = [NSNumber numberWithDouble:totalSeconds];
    
    int seconds = (int)totalSeconds % 60;
    int minutes = ((int)totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    self.recordTime.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (IBAction) playRecording:(id)sender{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSURL *url = [NSURL fileURLWithPath:self.recording.filePath];

	NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.delegate = self;
    [self.audioPlayer setVolume:1.0];
    [self.audioPlayer prepareToPlay];
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer play];
}


#pragma 
#pragma mark - Media methods

- (IBAction) dismissAndSetObservationMedia:(id)sender{
    if (self.delegate) {
        [self.delegate recordingAvailable:self.recording];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma
#pragma mark - Download Media to TMP directory

-(void) playMediaFromDocumentsFolder:(NSString *) fromPath{
    NSURL *fURL = [NSURL fileURLWithPath:fromPath];
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:fURL];

    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(moviePlayerPlaybackStateDidChange:)  name:MPMoviePlayerPlaybackStateDidChangeNotification  object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    videoPlayerView.moviePlayer.view.frame = self.view.frame;
    
    videoPlayerView.moviePlayer.initialPlaybackTime = -1.0;
    if([videoPlayerView.moviePlayer isPreparedToPlay])
        [videoPlayerView.moviePlayer prepareToPlay];
    [videoPlayerView.moviePlayer play];

}
@end
