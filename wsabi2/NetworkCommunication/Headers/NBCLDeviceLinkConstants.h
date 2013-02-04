/*
 *  NBCLSensorLinkConstants.h
 *  Wsabi
 *
 *  Created by Matt Aronoff on 11/30/10.
 *
 */
/*
 This software was developed at the National Institute of Standards and Technology by employees of the Federal Government
 in the course of their official duties. Pursuant to title 17 Section 105 of the United States Code this software is not 
 subject to copyright protection and is in the public domain. Wsabi is an experimental system. NIST assumes no responsibility 
 whatsoever for its use by other parties, and makes no guarantees, expressed or implied, about its quality, reliability, or 
 any other characteristic. We would appreciate acknowledgement if the software is used.
 */


//Operation types
typedef enum {
    kOpTypeRegister = 0,
    kOpTypeUnregister,
    kOpTypeLock,
    kOpTypeUnlock,
    kOpTypeStealLock,
    kOpTypeGetCommonInfo,
    kOpTypeGetDetailedInfo,
    kOpTypeInitialize,
    kOpTypeGetConfiguration,
    kOpTypeConfigure,
    kOpTypeGetContentType,
    kOpTypeCapture,
    kOpTypeDownload,
    kOpTypeThriftyDownload,
    kOpTypeCancel,
    kOpTypeConnectSequence,
    kOpTypeCaptureSequence,
    kOpTypeDisconnectSequence,
    kOpTypeRecoverySequence,
    kOpTypeAll

} SensorOperationType;

//Sequence types
typedef enum {
    kSensorSequenceNone = 0,
    kSensorSequenceRecovery,
    kSensorSequenceConnect,
    kSensorSequenceConfigure,
    kSensorSequenceConnectConfigure,
    kSensorSequenceCaptureDownload,
    kSensorSequenceConfigCaptureDownload,
    kSensorSequenceFull,
    kSensorSequenceDisconnect
    
} SensorSequenceType;

//Notification names
#define kSensorLinkOperationFailed @"Operation Failed"
#define kSensorLinkOperationCancelledByClient @"Operation Cancelled By Client"
#define kSensorLinkOperationCompleted @"Operation Completed"
#define kSensorLinkOperationCompleted @"Operation Completed"
#define kSensorLinkDownloadPosted @"Download Posted"
//Sequence notification names
#define kSensorLinkConnectedStatusChanged @"Connected Status Changed"
#define kSensorLinkConnectSequenceCompleted @"Connect Sequence Completed"
#define kSensorLinkConfigureSequenceCompleted @"Configure Sequence Completed"
#define kSensorLinkConnectConfigureSequenceCompleted @"Connect and Configure Sequence Completed"
#define kSensorLinkFullSequenceCompleted @"Full Sequence Completed"
#define kSensorLinkDisconnectSequenceCompleted @"Disconnect Sequence Completed"
#define kSensorLinkSequenceFailed @"Sequence Failed"


//
// Namespaces
//

/// WS-BD Namespace Declaration
static NSString * const kBCLWSBDNamespace = @"xmlns=\"urn:oid:2.16.840.1.101.3.9.3.1\"";
/// XML Schema Instance namespace declaration
static NSString * const kBCLSchemaInstanceNamespace = @"xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"";
/// XML Schema namespace declaration
static NSString * const kBCLSchemaNamespace = @"xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"";

//
// HTTP Methods
//

/// HTTP GET Method
static NSString * const kBCLMethodGET = @"GET";
/// HTTP POST Method
static NSString * const kBCLMethodPOST = @"POST";
/// HTTP PUT Method
static NSString * const kBCLMethodPUT = @"PUT";
/// HTTP DELETE Method
static NSString * const kBCLMethodDELETE = @"DELETE";

//
// HTTP Header
//

/// HTTP Content Type Header Key
static NSString * const kBCLHTTPHeaderKeyContentType = @"Content-Type";
/// XML Content Type Value for Content Type Header
static NSString * const kBCLHTTPHeaderValueXMLContentType = @"application/xml; charset=utf-8";

/// Whether or not failed downloads should be retried if they fail
// TODO: Retry pending downloads makes a better preference than constant.
static const BOOL kBWSShouldRetryDownloadIfPending = YES;