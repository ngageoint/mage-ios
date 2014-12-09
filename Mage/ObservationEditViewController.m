//
//  ObservationEditViewController.m
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditViewController.h"
#import "ObservationEditViewDataStore.h"
#import "DropdownEditTableViewController.h"
#import "ObservationPickerTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import "GeometryEditViewController.h"
#import <NSManagedObjectContext+MAGE.h>
#import <Observation+helper.h>
#import <HttpManager.h>
#import <MageServer.h>
#import <AVFoundation/AVFoundation.h>
#import <Attachment+helper.h>

@interface ObservationEditViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) IBOutlet ObservationEditViewDataStore *editDataStore;
@property (nonatomic, strong) NSMutableArray *attachmentsToUpload;

@end

@implementation ObservationEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) init {
    return self;
}

-(void) cancel:(id)sender {
    //do your saving and such here
    [self.editDataStore discardChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addVoice:(id)sender {
}


- (IBAction)addVideo:(id)sender {
}


- (IBAction)addFromCamera:(id)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
    
}


- (IBAction)addFromGallery:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyymmdd_HHmmss"];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSString *attachmentsDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0] stringByAppendingPathComponent:@"/attachments"];
    NSString *fileToWriteTo = [attachmentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"/MAGE_%@.png", [dateFormatter stringFromDate: [NSDate date]]]];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![manager fileExistsAtPath:attachmentsDirectory isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [manager createDirectoryAtPath:attachmentsDirectory
           withIntermediateDirectories:YES
                            attributes:attr
                                 error:&error];
        if (error)
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
    }
    
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    [imageData writeToFile:fileToWriteTo atomically:YES];
    
    NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
    [attachmentJson setValue:@"image/png" forKey:@"contentType"];
    [attachmentJson setValue:fileToWriteTo forKey:@"localPath"];
    [attachmentJson setValue:[NSString stringWithFormat: @"MAGE_%@.png", [dateFormatter stringFromDate: [NSDate date]]] forKey:@"name"];
    [attachmentJson setValue:[NSNumber numberWithInteger:[imageData length]] forKey:@"size"];
    [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
    [self.attachmentsToUpload addObject:attachmentJson];
}

- (IBAction)saveObservation:(id)sender {
    
    for (NSDictionary *attachmentJson in self.attachmentsToUpload) {
        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.editDataStore.observation.managedObjectContext insertIntoContext:self.editDataStore.observation.managedObjectContext];
        attachment.url = @"crap";
        [attachment setObservation:self.editDataStore.observation];
        attachment.url = @"turd";
        [self.editDataStore.observation addAttachmentsObject:attachment];
    }
    [self.attachmentsToUpload removeAllObjects];
    
    if ([self.editDataStore saveObservation]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.attachmentsToUpload = [NSMutableArray array];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = item;

    // if self.observation is null create a new one
    if (self.observation == nil) {
        self.observation = (Observation *)[NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:[NSManagedObjectContext defaultManagedObjectContext]];
        [self.observation initializeNewObservationWithLocation: self.location];
    }
    self.editDataStore.observation = self.observation;
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"dropdownSegue"]) {
        DropdownEditTableViewController *vc = [segue destinationViewController];
        ObservationPickerTableViewCell *cell = sender;
        
        [vc setFieldDefinition:cell.fieldDefinition];
        [vc setValue:cell.valueLabel.text];
    } else if([segue.identifier isEqualToString:@"geometrySegue"]) {
        GeometryEditViewController *gvc = [segue destinationViewController];
        ObservationEditGeometryTableViewCell *cell = sender;
        [gvc setGeoPoint:cell.geoPoint];
        [gvc setFieldDefinition: cell.fieldDefinition];
        [gvc setObservation:self.observation];
    }
}

- (IBAction)unwindFromDropdownController: (UIStoryboardSegue *) segue {
    DropdownEditTableViewController *vc = [segue sourceViewController];
    [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.value reloadCell:YES];
}

- (IBAction)unwindFromGeometryController: (UIStoryboardSegue *) segue {
    GeometryEditViewController *vc = [segue sourceViewController];
    [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.geoPoint reloadCell:YES];
}


@end
