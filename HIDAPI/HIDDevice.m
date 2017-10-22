//
//  HIDDevice.m
//  HIDAPI
//
//  Created by Max Chan on 21/10/2017.
//  Copyright © 2017 Max Chan. All rights reserved.
//

#import "HIDDevice.h"
#include "hidapi/hidapi.h"

@interface HIDWeakContainer : NSObject
@property (weak) HIDDevice *device;
- (instancetype)initWithDevie:(HIDDevice *)device NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@implementation HIDWeakContainer
@synthesize device = _device;
- (instancetype)initWithDevie:(HIDDevice *)device
{
    if (self = [super init])
    {
        _device = device;
    }
    return self;
}
@end

static NSMutableDictionary<NSString *, HIDWeakContainer *> *devices;

@interface HIDDevice ()

@property (readonly) hid_device *device;

- (instancetype)initWithHIDInfo:(struct hid_device_info *)info NS_DESIGNATED_INITIALIZER;

@end

@implementation HIDDevice
{
    hid_device *_device;
    
    HIDDeviceID _vendorID;
    HIDDeviceID _productID;
    NSString *_path;
    NSUInteger _releaseNumber;
    NSString *_manufacturerName;
    NSString *_productName;
    NSUInteger _usagePage;
    NSUInteger _usage;
    NSInteger _interfaceID;
    NSString *_serialNumber;
    
    errno_t _errno;
}

@synthesize vendorID = _vendorID;
@synthesize productID = _productID;
@synthesize path = _path;
@synthesize releaseNumber = _releaseNumber;
@synthesize manufacturerName = _manufacturerName;
@synthesize productName = _productName;
@synthesize usagePage = _usagePage;
@synthesize usage = _usage;
@synthesize interfaceID = _interfaceID;
@synthesize serialNumber = _serialNumber;

+ (void)initialize
{
    if (self == [HIDDevice class])
    {
        hid_init();
        atexit((void (*)(void))hid_exit);
    }
    
    if (!devices)
    {
        devices = [NSMutableDictionary dictionary];
    }
}

- (instancetype)init
{
    return self = nil;
}

- (instancetype)initWithHIDInfo:(struct hid_device_info *)info
{
    if (self = [super init])
    {
        if (!info)
            return self = nil;
        
        _path = @(info->path);
        
        HIDWeakContainer *container = devices[_path];
        if (container)
        {
            HIDDevice *previousDevice = container.device;
            if (previousDevice)
            {
                self = nil;
                return previousDevice;
            }
            else
            {
                container.device = self;
            }
        }
        else
        {
            container = [[HIDWeakContainer alloc] initWithDevie:self];
            devices[_path] = container;
        }
        
        _vendorID = info->vendor_id;
        _productID = info->product_id;
        _releaseNumber = info->release_number;
        _manufacturerName = [[NSString alloc] initWithBytes:info->manufacturer_string
                                                     length:wcslen(info->manufacturer_string) * sizeof(wchar_t)
                                                   encoding:NSUTF32LittleEndianStringEncoding];
        _productName = [[NSString alloc] initWithBytes:info->product_string
                                                length:wcslen(info->product_string) * sizeof(wchar_t)
                                              encoding:NSUTF32LittleEndianStringEncoding];
        _usage = info->usage;
        _usagePage = info->usage_page;
        _interfaceID = info->interface_number;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[HIDDevice class]])
        return [self isEqualToDevice:object];
    else
        return NO;
}

- (BOOL)isEqualToDevice:(HIDDevice *)device
{
    return [self.path isEqualToString:device.path];
}

+ (NSArray<HIDDevice *> *)enumerate
{
    return [self enumerateWithVendorID:0 productID:0];
}

+ (NSArray<HIDDevice *> *)enumerateWithVendorID:(HIDDeviceID)VID productID:(HIDDeviceID)PID
{
    NSMutableArray<HIDDevice *> *results = [NSMutableArray array];
    
    struct hid_device_info *devices, *devp;
    devices = hid_enumerate(VID, PID);
    devp = devices;
    
    while (devp)
    {
        HIDDevice *device = [[self alloc] initWithHIDInfo:devp];
        [results addObject:device];
        devp = devp->next;
    }
    
    hid_free_enumeration(devices);
    return [NSArray arrayWithArray:results];
}

- (hid_device *)device
{
    if (!_device)
    {
        errno_t errno_orig = errno;
        errno = 0;
        
        _device = hid_open_path(self.path.UTF8String);
        
        _errno = errno;
        errno = errno_orig;
    }
    
    return _device;
}

- (void)dealloc
{
    if (_device)
    {
        hid_close(_device);
    }
}

- (NSString *)serialNumber
{
    if (!_serialNumber)
    {
        if (!self.device)
            return nil;
        
        wchar_t *buf = calloc(BUFSIZ, sizeof(wchar_t));
        if (hid_get_serial_number_string(self.device, buf, BUFSIZ) < 0)
        {
            free(buf);
            return nil;
        }
        
        _serialNumber = [[NSString alloc] initWithBytesNoCopy:buf
                                                       length:wcslen(buf) * sizeof(wchar_t)
                                                     encoding:NSUTF32LittleEndianStringEncoding
                                                 freeWhenDone:YES];
    }
    return _serialNumber;
}

- (BOOL)writeReport:(NSData *)data error:(out NSError * _Nullable __autoreleasing *)error
{
    _errno = 0;
    if (!self.device)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return NO;
    }
    
    if (hid_write(self.device, data.bytes, data.length) < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return NO;
    }
    
    return YES;
}

- (NSData *)readReportWithLength:(NSUInteger)length untilDate:(NSDate *)timeout error:(out NSError * _Nullable __autoreleasing *)error
{
    _errno = 0;
    if (!self.device)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return nil;
    }
    
    NSMutableData *receivedData = [NSMutableData dataWithLength:length];
    NSInteger actualLength = -1;
    
    if ([timeout isEqualToDate:NSDate.distantFuture])
        actualLength = hid_read(self.device, receivedData.mutableBytes, length);
    else
        actualLength = hid_read_timeout(self.device, receivedData.mutableBytes, length, timeout.timeIntervalSinceNow * 1000);
    
    if (actualLength < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return nil;
    }
    
    return [receivedData subdataWithRange:NSMakeRange(0, actualLength)];
}

- (BOOL)writeFeatureReport:(NSData *)data error:(out NSError * _Nullable __autoreleasing *)error
{
    _errno = 0;
    if (!self.device)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return NO;
    }
    
    if (hid_send_feature_report(self.device, data.bytes, data.length) < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return NO;
    }
    
    return YES;
}

- (NSData *)readFeatureReportWithLength:(NSUInteger)length error:(out NSError * _Nullable __autoreleasing *)error
{
    _errno = 0;
    if (!self.device)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return nil;
    }
    
    NSMutableData *receivedData = [NSMutableData dataWithLength:length];
    NSInteger actualLength = -1;
    
    actualLength = hid_get_feature_report(self.device, receivedData.mutableBytes, length);
    
    if (actualLength < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return nil;
    }
    
    return [receivedData subdataWithRange:NSMakeRange(0, actualLength)];
}

- (NSString *)stringAtIndex:(NSUInteger)index error:(out NSError * _Nullable __autoreleasing *)error
{
    _errno = 0;
    if (!self.device)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        return nil;
    }
    
    wchar_t *buf = calloc(BUFSIZ, sizeof(wchar_t));
    if (hid_get_indexed_string(self.device, (int)index, buf, BUFSIZ) < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:_errno
                                     userInfo:nil];
        free(buf);
        return nil;
    }
    
    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:wcslen(buf) * sizeof(wchar_t)
                                        encoding:NSUTF32LittleEndianStringEncoding
                                    freeWhenDone:YES];
}

@end
