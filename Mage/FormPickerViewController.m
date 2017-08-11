//
//  FormPickerViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormPickerViewController.h"
#import "FormCollectionViewCell.h"

@interface FormPickerViewController ()

@property (strong, nonatomic) id<FormPickedDelegate> delegate;
@property (strong, nonatomic) NSArray *forms;

@end

@implementation FormPickerViewController

static NSString *CellIdentifier = @"FormCell";

- (instancetype) initWithDelegate: (id<FormPickedDelegate>) delegate andForms: (NSArray *) forms {
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    _forms = forms;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerNib:[UINib nibWithNibName:@"FormCell" bundle:nil] forCellWithReuseIdentifier:CellIdentifier];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.forms count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (FormCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    FormCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.formNameLabel.text = [[self.forms objectAtIndex:[indexPath row]] objectForKey:@"name"];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [_delegate formPicked: [self.forms objectAtIndex:[indexPath row]]];
}

@end
