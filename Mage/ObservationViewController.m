//
//  ObservationViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationViewController.h"
#import "GeoPoint.h"
#import <Observation+helper.h>
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationPropertyTableViewCell.h"
#import <User.h>
#import "AttachmentCell.h"
#import "Attachment+FICAttachment.h"
#import <FICImageCache.h>
#import "AppDelegate.h"
#import "ImageViewerViewController.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AFNetworking/AFNetworking.h>
#import <HttpManager.h>
#import "ObservationEditViewController.h"
#import <Server+helper.h>
#import "MapDelegate.h"
#import "ObservationDataStore.h"

@interface ObservationViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@property (nonatomic, strong) IBOutlet ObservationDataStore *observationDataStore;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ObservationViewController

AVPlayer *player;

- (NSDateFormatter *) dateFormatter {
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
    
	NSString *name = [_observation.properties valueForKey:@"type"];
	self.navigationItem.title = name;
    
    Observations *observations = [Observations observationsForObservation:self.observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        [self.mapDelegate selectedObservation:_observation];
    }
    [self.mapDelegate setObservations:observations];
    
    self.userLabel.text = _observation.user.name;
    
    self.userLabel.text = [NSString stringWithFormat:@"%@ (%@)", _observation.user.name, _observation.user.username];
	self.timestampLabel.text = [self.dateFormatter stringFromDate:_observation.timestamp];
	
	self.locationLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", _observation.location.coordinate.latitude, _observation.location.coordinate.longitude];
    
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    NSDictionary *properties = self.observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.observation.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate selectedObservation:self.observation region:viewRegion];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    maskLayer.anchorPoint = CGPointZero;
    
    // Setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha.
	// A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:.25];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    // An array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];
    
    // These are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array.
	// The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @.35, @.35f];
    maskLayer.bounds = _mapView.frame;
	UIView *view = [[UIView alloc] initWithFrame:_mapView.frame];
    
    view.backgroundColor = [UIColor blackColor];
    
    [self.view insertSubview:view belowSubview:self.mapView];
    self.mapView.layer.mask = maskLayer;
}

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_observation.properties count];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
    id value = [[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    id title = [observationCell.fieldDefinition objectForKey:@"title"];
    if (title == nil) {
        title = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    }
    [observationCell populateCellWithKey:title andValue:value];
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    id key = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSDictionary *form = [Server observationForm];
    
    for (id field in [form objectForKey:@"fields"]) {
        NSString *fieldName = [field objectForKey:@"name"];
        if ([key isEqualToString: fieldName]) {
            NSString *type = [field objectForKey:@"type"];
            NSString *CellIdentifier = [NSString stringWithFormat:@"observationCell-%@", type];
            ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                CellIdentifier = @"observationCell-generic";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            }
            cell.fieldDefinition = field;
            return cell;
        }
    }
    
    NSString *CellIdentifier = @"observationCell-generic";
    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
    return [cell getCellHeightForValue:[[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]]];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [_attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
 
    FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
        cell.image.image = image;
        [cell.image.layer addAnimation:[CATransition animation] forKey:kCATransition];
        cell.image.layer.cornerRadius = 5;
        cell.image.clipsToBounds = YES;
    };
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL imageExists = [delegate.imageCache retrieveImageForEntity:attachment withFormatName:AttachmentSmallSquare completionBlock:completionBlock];
    
    if (imageExists == NO) {
        cell.image.image = [UIImage imageNamed:@"download"];
    }
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _observation.attachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [_attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSLog(@"clicked attachment %@", attachment.url);
    
    if ([attachment.contentType hasPrefix:@"image"]) {
        [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
    } else if ([attachment.contentType hasPrefix:@"video"]) {
        [self downloadAndSaveMediaToTempFolder:attachment];
    } else if ([attachment.contentType hasPrefix:@"audio"]) {
        [self downloadAndSaveMediaToTempFolder:attachment];
    }
}

#pragma mark - Download Media to TMP directory
-(void) downloadAndSaveMediaToTempFolder:(Attachment *) attachment{
    HttpManager *http = [HttpManager singleton];
    Observation *obs = (Observation *)attachment.observation;
    
    NSString *downloadPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:attachment.remoteId] stringByAppendingPathComponent:attachment.name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
        // save the local path
        NSLog(@"playing locally");
        [self playMediaFromDocumentsFolder:downloadPath];
    } else {
        NSLog(@"Downloading to %@", downloadPath);
        NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:attachment.url parameters: nil error: nil];
        AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
                // save the local path
                [self playMediaFromDocumentsFolder:downloadPath];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            
        }];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[downloadPath stringByDeletingLastPathComponent]]) {
            NSLog(@"Creating directory %@", [downloadPath stringByDeletingLastPathComponent]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
        operation.responseSerializer = [AFHTTPResponseSerializer serializer];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:NO];
        [operation start];
    }
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

-(void) playMediaFromDocumentsFolder:(NSString *) fromPath{
    NSURL *fURL = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", fURL);
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:fURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(moviePlayerPlaybackStateDidChange:)  name:MPMoviePlayerPlaybackStateDidChangeNotification  object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    videoPlayerView.moviePlayer.view.frame = self.view.frame;
    videoPlayerView.moviePlayer.initialPlaybackTime = 0.0;
    videoPlayerView.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [videoPlayerView.moviePlayer prepareToPlay];
    [videoPlayerView.moviePlayer play];
}

-(void) playMovieAtURL: (NSURL*) theURL {
    
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:theURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(moviePlayerPlaybackStateDidChange:)  name:MPMoviePlayerPlaybackStateDidChangeNotification  object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    videoPlayerView.moviePlayer.view.frame = self.view.frame;
    videoPlayerView.moviePlayer.initialPlaybackTime = 0.0;
    videoPlayerView.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [videoPlayerView.moviePlayer prepareToPlay];
    [videoPlayerView.moviePlayer play];
}

// When the movie is done, release the controller.
-(void) myMovieFinishedCallback: (NSNotification*) aNotification
{
    MPMoviePlayerController* theMovie = [aNotification object];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: MPMoviePlayerPlaybackDidFinishNotification
     object: theMovie];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[_observation.properties valueForKey:@"type"] style: UIBarButtonItemStyleBordered target:nil action:nil];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"viewImageSegue"])
    {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setAttachment:sender];
    } else if ([[segue identifier] isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStyleBordered target:nil action:nil];
        ObservationEditViewController *oevc = [segue destinationViewController];
        [oevc setObservation:_observation];
    }
}

@end
