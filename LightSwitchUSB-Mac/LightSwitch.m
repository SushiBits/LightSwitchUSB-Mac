//
//  LightSwitch.m
//  LightSwitchUSB-Mac
//
//  Created by Max Chan on 21/10/2017.
//  Copyright © 2017 Max Chan. All rights reserved.
//

#import "LightSwitch.h"
#import <HIDAPI/HIDAPI.h>

@implementation LightSwitch
{
    uint16_t _point_value;
    BOOL _updating;
}

- (instancetype)init
{
    if (!(self = [super init]))
        return self = nil;
    
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(brightness))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    _point_value = 0;
    _updating = NO;
    
    return self;
}

- (void)sync
{
    if (!self.device)
        return;
    
    if (_updating)
        return;
    
    NSData *value = [self.device readReportWithLength:2
                                            untilDate:NSDate.distantFuture
                                                error:NULL];
    if (value.length == 2)
    {
        const uint16_t *new_value = value.bytes;
        if (_point_value != *new_value)
        {
            _point_value = *new_value;
            self.brightness = (_point_value * 1.0) / (UINT16_MAX * 1.0);
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (!self.device)
        return;
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(brightness))])
    {
        _updating = YES;
        
        uint16_t new_point_value = MAX(self.brightness * UINT16_MAX, 1);
        if (new_point_value != _point_value)
        {
            NSData *data = [NSData dataWithBytes:&new_point_value length:2];
            [self.device writeReport:data error:NULL];
            _point_value = new_point_value;
        }
        
        _updating = NO;
    }
}

@end
