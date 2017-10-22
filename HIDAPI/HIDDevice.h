//
//  HIDDevice.h
//  HIDAPI
//
//  Created by Max Chan on 21/10/2017.
//  Copyright © 2017 Max Chan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef uint16_t HIDDeviceID;

/**
 HIDDevice instances represents a single USB Human-Interface Device.
 */
@interface HIDDevice : NSObject

/**
 Unavailable. Do not initialize HID device directly. Please always enumerate the
 devices first.

 @return <tt>nil</tt>
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Tell if two devices are equal.

 @param device The other device to compare to.
 @return Whether the two devices are equal or not.
 */
- (BOOL)isEqualToDevice:(HIDDevice *)device;

/// @name HID Device Information

/// USB Vendor ID
@property (readonly) HIDDeviceID vendorID;
/// USB Product ID
@property (readonly) HIDDeviceID productID;
/// Device node path
@property (readonly, copy) NSString *path;
/// Device release number
@property (readonly) NSUInteger releaseNumber;
/// USB Manufacturer String
@property (readonly, copy) NSString *manufacturerName;
/// USB Product String
@property (readonly, copy) NSString *productName;
/// HID Usage Page
@property (readonly) NSUInteger usagePage;
/// HID Usage
@property (readonly) NSUInteger usage;
/// USB Interface ID
@property (readonly) NSInteger interfaceID;
/// USB Serial Number String
@property (nullable, readonly) NSString *serialNumber;

/// @name Device Enumeration

/// Enumerates all HID devices.
@property (readonly, class) NSArray<HIDDevice *> *enumerate;

/**
 Enumerates devices based on VID and PID.

 @param VID VID to search for. Pass 0 to ignore.
 @param PID PID to search for. Pass 0 to ignore.
 @return An array of devices found in the search.
 */
+ (NSArray<HIDDevice *> *)enumerateWithVendorID:(HIDDeviceID)VID productID:(HIDDeviceID)PID;

/// @name Sending and receiving reports

/**
 Send a HID Report.

 @param data Contents of the HID Report.
 @param error Output parameter. Error accessing the report, if any.
 @return YES if the report is send, NO otherwise.
 */
- (BOOL)writeReport:(NSData *)data error:(out NSError **)error;

/**
 Receive a HID Report.

 @param length Length of the anticipated report.
 @param timeout Timeout before the report is received. <tt>NSDate.distantFuture</tt> if no timeout given.
 @param error Output parameter. Error accessing the report, if any.
 @return Contents of the HID Report if successful, <tt>nil</tt> otherwise.
 */
- (nullable NSData *)readReportWithLength:(NSUInteger)length untilDate:(NSDate *)timeout error:(out NSError **)error;

/// @name Sending and receiving feature reports

/**
 Send a HID Feature Report.
 
 @param data Contents of the HID Feature Report.
 @param error Output parameter. Error accessing the report, if any.
 @return YES if the report is send, NO otherwise.
 */
- (BOOL)writeFeatureReport:(NSData *)data error:(out NSError **)error;

/**
 Receive a HID Feature Report.
 
 @param length Length of the anticipated report.
 @param error Output parameter. Error accessing the report, if any.
 @return Contents of the HID Feature Report if successful, <tt>nil</tt> otherwise.
 */
- (nullable NSData *)readFeatureReportWithLength:(NSUInteger)length error:(out NSError **)error;

/// @name HID Strings

/**
 Read HID strings with index

 @param index Index of the string.
 @param error utput parameter. Error accessing the string, if any.
 @return HID string at the index if successful, <tt>nil</tt> otherwise.
 */
- (nullable NSString *)stringAtIndex:(NSUInteger)index error:(out NSError **)error;

@end

NS_ASSUME_NONNULL_END
