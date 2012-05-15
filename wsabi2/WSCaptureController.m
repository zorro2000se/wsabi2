//
//  WSCaptureController.m
//  wsabi2
//
//  Created by Matt Aronoff on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WSCaptureController.h"

#import "WSAppDelegate.h"

@implementation WSCaptureController
@synthesize item;
@synthesize popoverController;

@synthesize frontContainer;
@synthesize backContainer;
@synthesize backNavBarTitleItem;

@synthesize annotationTableView;
@synthesize annotationNotesTableView;
@synthesize annotateButton;

@synthesize modalityButton;
@synthesize deviceButton;
@synthesize itemDataView;
@synthesize captureButton;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Internal convenience methods
-(BOOL) hasAnnotationOrNotes
{
    if (self.item.notes && ![self.item.notes isEqualToString:@""]) {
        return YES;
    }
    
    if (!currentAnnotationArray) {
        return NO;
    }
    
    for (NSNumber *val in currentAnnotationArray) {
        if ([val boolValue]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.item) {
        //Get a reference to the sensor link for this object.
        currentLink = [[NBCLDeviceLinkManager defaultManager] deviceForUri:self.item.deviceConfig.uri];
        
        //put the button in the default state.
        self.captureButton.state = WSCaptureButtonStateInactive;
        
        if (self.item.data) {
            dataImage = [UIImage imageWithData:self.item.data];
            self.itemDataView.image = dataImage;
        }
    }
    
    [self.modalityButton setBackgroundImage:[[UIImage imageNamed:@"BreadcrumbButton"] stretchableImageWithLeftCapWidth:18 topCapHeight:0] forState:UIControlStateNormal];
    [self.modalityButton setTitle:self.item.submodality forState:UIControlStateNormal];
    
    [self.deviceButton setTitle:self.item.deviceConfig.name forState:UIControlStateNormal];
    self.deviceButton.enabled = ![self.item.submodality isEqualToString:[WSModalityMap stringForCaptureType:kCaptureTypeNotSet]];
    
    //Configure the capture button.
    /*	WSCaptureButtonStateInactive,
     WSCaptureButtonStateCapture,
     WSCaptureButtonStateStop,
     WSCaptureButtonStateWarning,
     WSCaptureButtonStateWaiting,
     WSCaptureButtonStateWaitingRestartCapture,
     */

    self.captureButton.inactiveImage = [UIImage imageNamed:@"Blank"];

    self.captureButton.captureImage = [UIImage imageNamed:@"gesture-single-tap"];
    
    self.captureButton.stopImage = [UIImage imageNamed:@"stop-sign"];
    self.captureButton.stopMessage = @"Stop capture";
    
    self.captureButton.warningImage = [UIImage imageNamed:@"warning-alert"];
    self.captureButton.warningMessage = @"Hmmmm... something's up.";
    
    self.captureButton.waitingMessage = @"Waiting for sensor";
    
    self.captureButton.waitingRestartCaptureMessage = @"Reconnecting to the sensor";
    
    //put a shadow behind the button
    self.captureButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.captureButton.layer.shadowOpacity = 0.5;
    self.captureButton.layer.shadowRadius = 6;
    self.captureButton.layer.shadowOffset = CGSizeMake(1,1);
    
    //add swipe listeners to the capture button to switch between items.
//    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeCaptureButton:)];
//    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
//    [self.view addGestureRecognizer:swipeRight];
//    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeCaptureButton:)];
//    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//    [self.view addGestureRecognizer:swipeLeft];

    //Start with the button in the "ready to capture" state
    self.captureButton.state = self.item.data ? WSCaptureButtonStateInactive : WSCaptureButtonStateCapture;
    
    //configure the annotation button and panel
    if ([self hasAnnotationOrNotes]) {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation-warning"] forState:UIControlStateNormal];
    }
    else {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation"] forState:UIControlStateNormal];
    }
    
    self.backNavBarTitleItem.title = self.item.submodality;
    self.annotationNotesTableView.alwaysBounceVertical = NO;
    
    //add notification listeners
    
    //Catch a posted download
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDownloadPosted:) 
                                                 name:kSensorLinkDownloadPosted
                                               object:nil];
    //Catch an item change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleItemChanged:) 
                                                 name:kChangedWSCDItemNotification
                                               object:nil];

    //Catch a failed sensor operation
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSensorOperationFailed:) 
                                                 name:kSensorLinkOperationFailed
                                               object:nil];

    //Catch a failed sensor sequence
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSensorSequenceFailed:) 
                                                 name:kSensorLinkSequenceFailed
                                               object:nil];
    
    //enable touch logging
    [self.view startAutomaticGestureLogging:YES];

}

- (void) viewWillUnload
{
    //remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


#pragma mark - Property accessors
-(void) setItem:(WSCDItem *)newItem
{
    item = newItem;
    
    //store the annotation array locally for performance.
    if (item.annotations) {
        currentAnnotationArray = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:item.annotations]];
    }
    else {
        //If there isn't an annotation array, create and fill one.
        int maximumAnnotations = 4;
        currentAnnotationArray = [[NSMutableArray alloc] initWithCapacity:maximumAnnotations]; //the largest (current) submodality
        for (int i = 0; i < maximumAnnotations; i++) {
            [currentAnnotationArray addObject:[NSNumber numberWithBool:NO]];
        }
    }
    //configure the annotation button
    if ([self hasAnnotationOrNotes]) {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation-warning"] forState:UIControlStateNormal];
    }
    else {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation"] forState:UIControlStateNormal];
    }

}


#pragma mark - Button Action Methods
-(IBAction)annotateButtonPressed:(id)sender
{
    if (self.item.data) {
        annotateClearActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:@"Clear this item"
                                                      otherButtonTitles:@"Annotate", nil];
        annotateClearActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        [annotateClearActionSheet showInView:self.view];
    }
    else {
//        //just flip to the annotation.
//        [UIView transitionFromView:self.frontContainer
//                            toView:self.backContainer
//                          duration:kFlipAnimationDuration
//                           options:UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionTransitionFlipFromLeft
//                        completion:nil];
        [UIView flipTransitionFromView:self.frontContainer toView:self.backContainer duration:kFlipAnimationDuration completion:nil];
    }
}

-(IBAction)doneButtonPressed:(id)sender
{
    //make sure we resign first responder.
    [self.view endEditing:YES];
    
    //configure the annotation button and panel
    if ([self hasAnnotationOrNotes]) {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation-warning"] forState:UIControlStateNormal];
    }
    else {
        [self.annotateButton setBackgroundImage:[UIImage imageNamed:@"capture-button-annotation"] forState:UIControlStateNormal];
    }

    //just flip to the capture view.
    //NOTE: For a reason I just can't figure out, the contents of the data UIImageView are getting dumped when the view is flipped
    //and hidden. This works identically when hiding the view using UIView's built-in transition methods. It works identically
    //when keeping a reference to the contained UIImage as an ivar as when loading it directly from the WSCDItem. It works identically
    //when setting the UIImageView to clear its contents and not. For the moment, we'll reset the image manually when it appears.
    if (self.item.data) {
        //this makes for a smoother transition.
        self.itemDataView.backgroundColor = [UIColor darkGrayColor];
    }

    [UIView flipTransitionFromView:self.backContainer toView:self.frontContainer duration:kFlipAnimationDuration 
                        completion:^(BOOL completed) {
                            if (self.item.data) {
                                self.itemDataView.alpha = 0;
                                self.itemDataView.image = dataImage;
                                [UIView animateWithDuration:0.1 animations:^{
                                    self.itemDataView.alpha = 1.0;
                                    self.itemDataView.backgroundColor = [UIColor whiteColor];
                                }];

                            }
                    }];
    //save the context
    [(WSAppDelegate*)[[UIApplication sharedApplication] delegate] saveContext];

    //Post a notification that this item has changed
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.item,kDictKeyTargetItem,
                              [self.item.objectID URIRepresentation],kDictKeySourceID, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kChangedWSCDItemNotification
                                                        object:self
                                                      userInfo:userInfo];
    

}

-(IBAction)modalityButtonPressed:(id)sender
{
//    [delegate didRequestModalityChangeForItem:self.item];

    //Post a notification to show the modality walkthrough
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self.item forKey:kDictKeyTargetItem];
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowWalkthroughNotification
                                                        object:self
                                                      userInfo:userInfo];

    //close the popover
    [self.popoverController dismissPopoverAnimated:YES];
}

-(IBAction)deviceButtonPressed:(id)sender
{
//    [delegate didRequestDeviceChangeForItem:self.item];

    //Post a notification to show the modality walkthrough starting from device selection.
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.item,kDictKeyTargetItem,[NSNumber numberWithBool:YES],kDictKeyStartFromDevice,nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowWalkthroughNotification
                                                        object:self
                                                      userInfo:userInfo];

    //close the popover
    [self.popoverController dismissPopoverAnimated:YES];
}

-(IBAction)captureButtonPressed:(id)sender
{    

    //Try to capture.
    //Post a notification to start capture, starting from this item
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.item,kDictKeyTargetItem,
                              [self.item.objectID URIRepresentation],kDictKeySourceID, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kStartCaptureNotification
                                                        object:self
                                                      userInfo:userInfo];

    //Update our state (temporarily, just cycle states).
    //self.captureButton.state = fmod((self.captureButton.state + 1), WSCaptureButtonStateWaiting_COUNT);
    self.captureButton.state = WSCaptureButtonStateWaiting;
}
                                       
#pragma mark - Gesture recognizer handlers
-(void) didSwipeCaptureButton:(UISwipeGestureRecognizer*)recog
{
    if (recog.direction == UISwipeGestureRecognizerDirectionLeft) {
        //go to the previous item
        [delegate didRequestCapturePreviousItem:self.item];
    }
    else if (recog.direction == UISwipeGestureRecognizerDirectionRight) {
        //go to the next item
        [delegate didRequestCaptureNextItem:self.item];
    }
        
}


#pragma mark - UIActionSheet delegate
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == annotateClearActionSheet && buttonIndex != actionSheet.cancelButtonIndex) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            
            //show another action sheet to confirm the deletion
            deleteConfirmActionSheet = [[UIActionSheet alloc] initWithTitle:@"Clear this data?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:@"Clear"
                                                          otherButtonTitles:nil];
            [deleteConfirmActionSheet showInView:self.view];
            
        }
        else {
            //just flip to the annotation.
//            [UIView transitionFromView:self.frontContainer
//                                toView:self.backContainer
//                              duration:kFlipAnimationDuration
//                               options:UIViewAnimationOptionShowHideTransitionViews|UIViewAnimationOptionTransitionFlipFromLeft
//                            completion:^(BOOL finished) {
//                            }];
            [UIView flipTransitionFromView:self.frontContainer toView:self.backContainer duration:kFlipAnimationDuration completion:nil];
        }
    }
    
    else if (actionSheet == deleteConfirmActionSheet && buttonIndex != actionSheet.cancelButtonIndex)
    {
        //This is the clear button. Remove data and set the capture button state.
        self.item.data = nil;
        self.item.dataContentType = nil;
        
        //Post a notification that this item has changed
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.item,kDictKeyTargetItem,
                                  [self.item.objectID URIRepresentation],kDictKeySourceID, nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangedWSCDItemNotification
                                                            object:self
                                                          userInfo:userInfo];
        self.captureButton.state = WSCaptureButtonStateCapture;

    }
}

#pragma mark - Notification handlers
-(void) handleItemChanged:(NSNotification*)notification
{
    //At the moment, this is mainly used to catch a deletion, but may also be used to catch any time
    //the item changes out from under us.
    
    //Do this in the most simpleminded way possible
    NSMutableDictionary *info = (NSMutableDictionary*)notification.userInfo;
    
    WSCDItem *targetItem = (WSCDItem*) [self.item.managedObjectContext objectWithID:[self.item.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[info objectForKey:kDictKeySourceID]]];

    //Catch a change to the item state.
    if (self.item == targetItem) {
        if ([info objectForKey:@"data"]) {
            //the table view is going to take care of editing the actual data, we just need to use
            //the image.
            dataImage = [UIImage imageWithData:[info objectForKey:@"data"]];
            self.itemDataView.image = dataImage;
        }
        else {
            self.itemDataView.image = nil;
        }
    }
}

-(void) handleDownloadPosted:(NSNotification*)notification
{
    //Do this in the most simpleminded way possible
    NSMutableDictionary *info = (NSMutableDictionary*)notification.userInfo;
    
    WSCDItem *targetItem = (WSCDItem*) [self.item.managedObjectContext objectWithID:[self.item.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[info objectForKey:kDictKeySourceID]]];
    
    if (self.item == targetItem && [info objectForKey:@"data"]) {
        //the table view is going to take care of editing the actual data, we just need to use
        //the image.
        dataImage = [UIImage imageWithData:[info objectForKey:@"data"]];
        self.itemDataView.image = dataImage;
    }
    
    //return the capture state to normal or hidden
    if(self.itemDataView.image)
    {
        self.captureButton.state = WSCaptureButtonStateInactive;
    }
    else {
        self.captureButton.state = WSCaptureButtonStateCapture;

    }
}

-(void) handleSensorOperationFailed:(NSNotification*)notification
{
    //Do this in the most simpleminded way possible
    NSMutableDictionary *info = (NSMutableDictionary*)notification.userInfo;
    NSError *error = [info objectForKey:@"error"];
    //IF the capture button is visible:
    if (self.captureButton.state != WSCaptureButtonStateInactive) {
        self.captureButton.state = WSCaptureButtonStateWarning;
        self.captureButton.warningMessage = error.description;
    }
    else {
        //Log the error but don't change the UI
        NSLog(@"Ran into a failed sensor sequence: %@",error.description);
    }

}

-(void) handleSensorSequenceFailed:(NSNotification *)notification
{
    //Do this in the most simpleminded way possible
    NSMutableDictionary *info = (NSMutableDictionary*)notification.userInfo;
    
//    WSCDItem *targetItem = (WSCDItem*) [self.item.managedObjectContext objectWithID:[self.item.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[info objectForKey:kDictKeySourceID]]];
//
//    //Make sure this applies to us.
//    if (self.item == targetItem) {
//        
    WSBDResult *result = (WSBDResult*)[info objectForKey:kDictKeyCurrentResult];
    NSString *resultString = [NSString stringWithFormat:@"Sensor problem: %@", result.message ? result.message : [WSBDResult stringForStatusValue:result.status]];   
        
        //SensorSequenceType seq = [[info objectForKey:kDictKeySequenceType] intValue];
//        
//        if (seq == kSensorSequenceConfigCaptureDownload ||
//            seq == kSensorSequenceCaptureDownload ||
//            seq == kSensorSequenceFull 
//            ) {
    
    //IF the capture button is visible:
    if (self.captureButton.state != WSCaptureButtonStateInactive) {
        //This is a failed capture notification, so change our button state.
        self.captureButton.warningMessage = resultString;
        self.captureButton.state = WSCaptureButtonStateWarning;
    }
    else {
        //Log the error but don't change the UI
        NSLog(@"Ran into a failed sensor sequence: %@",resultString);
    }

//        }
//    }
}

#pragma mark - TableView data source/delegate
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.annotationNotesTableView) {
        return 1;
    }
    
    WSSensorCaptureType capType = [WSModalityMap captureTypeForString:item.submodality];
    
    if (capType == kCaptureTypeLeftSlap || capType == kCaptureTypeRightSlap) {
        return 4;
    }
    else if (capType == kCaptureTypeThumbsSlap || 
             capType == kCaptureTypeBothEars ||
             capType == kCaptureTypeBothFeet ||
             capType == kCaptureTypeBothIrises ||
             capType == kCaptureTypeBothRetinas)
    {
        return 2;
    }
    else return 1; //all other capture types
}

// Customize the appearance of table view cells.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.annotationNotesTableView) {
        return 300;
    }
    else return 44; //default row height;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.annotationNotesTableView) {
        return @"Notes";
    }
    
    else return nil;
    
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *StringCell = @"StringCell"; 
    static NSString *TextViewCell = @"TextViewCell";
    
    if (aTableView == self.annotationTableView) {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:StringCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextViewCell];
        }
        
        WSSensorCaptureType capType = [WSModalityMap captureTypeForString:item.submodality];
        NSString *titleString = nil;
        if (capType == kCaptureTypeLeftSlap || capType == kCaptureTypeRightSlap) {
            switch (indexPath.row) {
                case 0:
                    titleString = @"Index";
                    break;
                case 1:
                    titleString = @"Middle";
                    break;
                case 2:
                    titleString = @"Ring";
                    break;
                case 3:
                    titleString = @"Little";
                    break;
                default:
                    break;
            }
        }
        else if (capType == kCaptureTypeThumbsSlap || 
                 capType == kCaptureTypeBothEars ||
                 capType == kCaptureTypeBothFeet ||
                 capType == kCaptureTypeBothIrises ||
                 capType == kCaptureTypeBothRetinas)
        {
            switch (indexPath.row) {
                case 0:
                    titleString = @"Left";
                    break;
                case 1:
                    titleString = @"Right";
                    break;
                default:
                    break;
            }

        }
        else {
            titleString = item.submodality;
        }
        
        cell.textLabel.text = titleString;
        
        NSString *imageName = nil;
        if ([[currentAnnotationArray objectAtIndex:indexPath.row] boolValue]) {
            //if there is an annotation, use the "Not OK" symbol.
            imageName = @"symbol-notok";
        }
        else {
            imageName = @"symbol-ok";
        }
        
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        
        return cell;
    }
    else if (aTableView == self.annotationNotesTableView) {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:TextViewCell];
        UITextView *textView;
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:TextViewCell];
            textView = [[UITextView alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 4, 2)];
            textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            textView.delegate = self;
            textView.font = [UIFont systemFontOfSize:17];
            textView.backgroundColor = [UIColor clearColor];
            
            [cell.contentView addSubview:textView];
            //enable touch logging for new cells
            [cell startAutomaticGestureLogging:YES];
            
        }
        else {
            for (int i = 0; i < [cell.contentView.subviews count]; i++) {
                UIView *v = [cell.contentView.subviews objectAtIndex:i];
                if ([v isKindOfClass:[UITextView class]]) {
                    textView = (UITextView*)v;
                    break; //stop looking
                }
            } 
        }
        textView.text = self.item.notes;  
        
        //Disables UITableViewCell from accidentally becoming selected.
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }

    return nil;
    
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the managed object for the given index path
//        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
//        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
//        
//        // Save the context.
//        NSError *error = nil;
//        if (![context save:&error]) {
//            /*
//             Replace this implementation with code to handle the error appropriately.
//             
//             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//             */
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//
//
//    }   
//}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (aTableView != self.annotationTableView) {
        return; //only respond to selections from this one table view.
    }
    
    //mark this row as either annotated or not.
    BOOL existingValue = [[currentAnnotationArray objectAtIndex:indexPath.row] boolValue];
    [currentAnnotationArray replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:!existingValue]];
    
    //reload this row.
    [aTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    //store the changes
    self.item.annotations = [NSKeyedArchiver archivedDataWithRootObject:currentAnnotationArray];
    
    //deselect the row afterwards
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextView delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView logTextViewStarted:nil];
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.item.notes = textView.text;
}

-(void) textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    [textView logTextViewEnded:nil];
}


@end
