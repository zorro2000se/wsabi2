// This software was developed at the National Institute of Standards and
// Technology (NIST) by employees of the Federal Government in the course
// of their official duties. Pursuant to title 17 Section 105 of the
// United States Code, this software is not subject to copyright protection
// and is in the public domain. NIST assumes no responsibility whatsoever for
// its use by other parties, and makes no guarantees, expressed or implied,
// about its quality, reliability, or any other characteristic.

#import <UIKit/UIKit.h>

/// Sections within the settings table
typedef enum
{
    kWSSettingsSectionLogging = 0,
    kWSSettingsSectionSensors = 1
} kBWSSettingsSections;
/// Number of settings sections
static const NSUInteger kWSSettingsSectionsCount = 2;

/// Label for the navigation item
static NSString * const kWSSettingsLabel = @"Settings";

/// Label for logging settings section
static NSString * const kWSSettingsSectionLoggingLabel = @"Logging";
/// Label for sensors settings section
static NSString * const kWSSettingsSectionSensorsLabel = @"Sensors";

/// Rows within the logging options section
typedef enum {
    kWSSettingsLoggingTouchLoggingRow = 0,
    kWSSettingsLoggingMotionLoggingRow = 1,
    kWSSettingsLoggingNetworkLoggingRow = 2,
    kWSSettingsLoggingDeviceLoggingRow = 3,
    kWSSettingsLoggingVerboseLoggingRow = 4,
    kWSSettingsLoggingShowLoggingPanelRow = 5,
    kWSSettingsLoggingShowSavedLogsRow = 6
} kWSSettingsLoggingRows;
/// Number of logging section rows
static const NSUInteger kWSSettingsLoggingRowsCount = 7;

/// Label for touch logging settings row
static NSString * const kWSSettingsLoggingTouchLoggingRowLabel = @"Touch Logging";
/// Label for motion logging settings row
static NSString * const kWSSettingsLoggingMotionLoggingRowLabel = @"Motion Logging";
/// Label for network logging settings row
static NSString * const kWSSettingsLoggingNetworkLoggingRowLabel = @"Network Logging";
/// Label for device logging settings row
static NSString * const kWSSettingsLoggingDeviceLoggingRowLabel = @"Device Event Logging";
/// Label for verbose logging settings row
static NSString * const kWSSettingsLoggingVerboseLoggingRowLabel = @"Verbose Logging";
/// Label for showing the logging panel row
static NSString * const kWSSettingsLoggingShowLoggingPanelRowLabel = @"Show Logging Panel";
/// Label for showing saved logs row
static NSString * const kWSSettingsLoggingShowSavedLogsRowLabel = @"Show Saved Logs";

/// Rows within the sensors section
typedef enum {
    kWSSettingsSensorsShowSensorsRow = 0,
    kWSSettingsSensorsShowPendingOperationsRow = 1
} kWSSettingsSensorsRows;
/// Number of sensor section rows
static const NSUInteger kWSSettingsSensorsRowsCount = 2;

/// Label for showing sensors row
static NSString * const kWSSettingsSensorsShowSensorsRowLabel = @"Show Sensors";
/// Label for showing pending operations
static NSString * const kWSSettingsSensorsShowPendingOperationsRowLabel = @"Show Pending Operations";

@interface BWSSettingsViewController : UITableViewController <UIPopoverControllerDelegate>

@end
