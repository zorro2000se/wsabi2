// This software was developed at the National Institute of Standards and
// Technology (NIST) by employees of the Federal Government in the course
// of their official duties. Pursuant to title 17 Section 105 of the
// United States Code, this software is not subject to copyright protection
// and is in the public domain. NIST assumes no responsibility whatsoever for
// its use by other parties, and makes no guarantees, expressed or implied,
// about its quality, reliability, or any other characteristic.

#import <Foundation/Foundation.h>

#import "WSBDResult.h"
#import "NBCLDeviceLinkConstants.h"

@class WSDeviceLink;

@protocol WSDeviceLinkDelegate <NSObject>

@optional

- (void)sensorOperationDidFail:(SensorOperationType)opType
                      fromLink:(WSDeviceLink*)link
                      deviceID:(NSURL*)deviceID
                     withError:(NSError*)error;

- (void)sensorOperationWasCancelledByService:(SensorOperationType)opType
                                    fromLink:(WSDeviceLink *)link
                              deviceID:(NSURL *)deviceID
                                  withResult:(WSBDResult *)result;

- (void)sensorOperationWasCancelledByClient:(SensorOperationType)opType
                                   fromLink:(WSDeviceLink *)link
                                   deviceID:(NSURL *)deviceID;

- (void)sensorOperationCompleted:(SensorOperationType)opType
                        fromLink:(WSDeviceLink *)link
                        deviceID:(NSURL *)deviceID
                      withResult:(WSBDResult *)result;

- (void)sensorConnectionStatusChanged:(BOOL)connectedAndReady
                             fromLink:(WSDeviceLink *)link
                             deviceID:(NSURL *)deviceID;

/* These are sequences of actions that we'll need to perform */

//NOTE: The result object will be the result from the last performed step.
- (void)connectSequenceCompletedFromLink:(WSDeviceLink *)link 
                              withResult:(WSBDResult *)result 
                                deviceID:(NSURL *)deviceID;

- (void)configureSequenceCompletedFromLink:(WSDeviceLink *)link
                                withResult:(WSBDResult *)result
                                  deviceID:(NSURL *)deviceID;

- (void)connectConfigureSequenceCompletedFromLink:(WSDeviceLink *)link
                                       withResult:(WSBDResult *)result 
                                         deviceID:(NSURL *)deviceID;

//The array of results in these sequences contains WSBDResults for each captureId.
//The tag is used to ID the UI element that made the request, so we can pass it the resulting data.

- (void)configCaptureDownloadSequenceCompletedFromLink:(WSDeviceLink *)link
                                           withResults:(NSMutableArray *)results 
                                              deviceID:(NSURL *)deviceID;

- (void)fullSequenceCompletedFromLink:(WSDeviceLink *)link
                          withResults:(NSMutableArray *)results
                             deviceID:(NSURL *)deviceID;

- (void)disconnectSequenceCompletedFromLink:(WSDeviceLink *)link
                                 withResult:(WSBDResult *)result 
                                   deviceID:(NSURL *)deviceID;

- (void)sequenceDidFail:(SensorSequenceType)sequenceType
               fromLink:(WSDeviceLink *)link
             withResult:(WSBDResult *)result 
               deviceID:(NSURL *)deviceID;

@end