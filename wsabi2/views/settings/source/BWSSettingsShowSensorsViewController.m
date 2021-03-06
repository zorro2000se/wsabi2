// This software was developed at the National Institute of Standards and
// Technology (NIST) by employees of the Federal Government in the course
// of their official duties. Pursuant to title 17 Section 105 of the
// United States Code, this software is not subject to copyright protection
// and is in the public domain. NIST assumes no responsibility whatsoever for
// its use by other parties, and makes no guarantees, expressed or implied,
// about its quality, reliability, or any other characteristic.

#import "BWSAppDelegate.h"
#import "BWSCDItem.h"
#import "BWSCDPerson.h"
#import "BWSCDDeviceDefinition.h"
#import "BWSModalityMap.h"
#import "BWSSettingsAddSensorViewController.h"
#import "BWSConstants.h"
#import "BWSDDLog.h"
#import "UITableView+BWSUtilities.h"

#import "BWSSettingsShowSensorsViewController.h"

@interface BWSSettingsShowSensorsViewController ()

/// List of the sensors retrieved from the backing store
@property (nonatomic, strong) NSDictionary *sensors;

/// Obtain a dictionary of all sensors, where the key is the modality number
- (NSDictionary *)retrieveAllSensors;
/// Obtain an array of all sensors, given a modality number
- (NSArray *)retrieveSensorsForModality:(WSSensorModalityType)modality;
/// Add a new sensor
- (IBAction)addSensor:(id)sender;

@end

@implementation BWSSettingsShowSensorsViewController

@synthesize sensors = _sensors;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addSensorButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSensor:)];
    [[self navigationItem] setRightBarButtonItem:addSensorButton];
    
    [self setSensors:[self retrieveAllSensors]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setSensors:[self retrieveAllSensors]];
    [[self tableView] reloadData];
    
    self.navigationController.contentSizeForViewInPopover = CGSizeMake(self.tableView.frame.size.width, [self.tableView contentHeight]);
    self.contentSizeForViewInPopover = CGSizeMake(self.tableView.frame.size.width, [self.tableView contentHeight]);
    
    [super viewDidAppear:animated];
}

#pragma mark - Events

- (IBAction)addSensor:(id)sender
{
    BWSSettingsAddSensorViewController *addSensorVC = [[BWSSettingsAddSensorViewController alloc] initWithNibName:@"BWSSettingsAddSensorView" bundle:nil];
    [[self navigationController] pushViewController:addSensorVC animated:YES];
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TableView Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"SettingsDeviceCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    BWSCDDeviceDefinition *device = [[[self sensors] objectForKey:[NSNumber numberWithUnsignedInteger:indexPath.section]] objectAtIndex:indexPath.row];
    if ((device.name == nil) || [device.name isEqualToString:@""])
        [[cell textLabel] setText:@"<Unnamed>"];
    else
	    [[cell textLabel] setText:[device name]];
    if (device.item == NULL)
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@: %@", [device uri], NSLocalizedString(@"Unassociated", @"Not associated with any item")]];
    else
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@: %@ %@ (%@)",
                                         [device uri],
                                         device.item.person.firstName != nil ? device.item.person.firstName : @"<NFN>",
                                         device.item.person.lastName != nil ? device.item.person.lastName : @"<NLN>",
                                         device.item.submodality]];
    
    return (cell);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([[[self sensors] objectForKey:[NSNumber numberWithInteger:section]] count]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([[self sensors] count]);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ([BWSModalityMap stringForModality:section]);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BWSCDDeviceDefinition *device = [[[self sensors] objectForKey:[NSNumber numberWithUnsignedInteger:indexPath.section]] objectAtIndex:indexPath.row];
    return ([device item] == nil);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        
        // Delete device
        NSManagedObjectContext *moc = [(BWSAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        BWSCDDeviceDefinition *device = [[[self sensors] objectForKey:[NSNumber numberWithUnsignedInteger:indexPath.section]] objectAtIndex:indexPath.row];
        [moc deleteObject:device];
        [(BWSAppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
        
        // Reload table
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self setSensors:[self retrieveAllSensors]];
        
        [tableView endUpdates];
    }
    
    self.contentSizeForViewInPopover = CGSizeMake(self.tableView.frame.size.width, [self.tableView contentHeight]);
    self.navigationController.contentSizeForViewInPopover = CGSizeMake(self.tableView.frame.size.width, [self.tableView contentHeight]);
}

#pragma mark - CoreData Manipulation

- (NSDictionary *)retrieveAllSensors
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:kModality_COUNT];
    
    for (NSUInteger modality = 0; modality < kModality_COUNT; modality++)
        [dictionary setObject:[self retrieveSensorsForModality:modality] forKey:[NSNumber numberWithUnsignedInteger:modality]];
    
    return (dictionary);
}

- (NSArray *)retrieveSensorsForModality:(WSSensorModalityType)modality
{
    if (modality > kModality_COUNT)
        return ([[NSArray alloc] init]);
    
    NSManagedObjectContext *moc = [(BWSAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:kBWSEntityDeviceDefinition inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(modalities like %@)", [BWSModalityMap stringForModality:modality]];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setPredicate:predicate];
    
    //get a sorted list of the recent sensors
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    NSArray *retrievedSensors = [moc executeFetchRequest:request error:&error];
    if (error != nil || retrievedSensors == nil)
        DDLogBWSVerbose(@"%@", [error description]);
    
    return (retrievedSensors);
}

@end
