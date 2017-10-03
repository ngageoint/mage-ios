//
//  FormsViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormsViewController.h"
#import "FormCollectionViewCell.h"
#import <Event.h>

@interface FormsViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation FormsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    Event *event = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
    self.forms = event.forms;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.forms count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FormCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"form" forIndexPath:indexPath];
    NSDictionary *form = [self.forms objectAtIndex:[indexPath row]];
    cell.formNameLabel.text = [form objectForKey:@"name"];
    return cell;
}

//- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//    AttachmentCell *cell = [self.attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
//    Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
//    [cell setImageForAttachament:attachment withFormatName:self.attachmentFormatName];
//    
//    return cell;
//}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
//    if (self.attachmentSelectionDelegate) {
//        Attachment *attachment = [self attachmentAtIndex:[indexPath row]];
//        [self.attachmentSelectionDelegate selectedAttachment:attachment];
//    }
}

@end
