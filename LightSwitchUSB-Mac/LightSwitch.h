//
//  LightSwitch.h
//  LightSwitchUSB-Mac
//
//  Created by Max Chan on 21/10/2017.
//  Copyright © 2017 Max Chan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HIDDevice;

@interface LightSwitch : NSObject

@property double brightness;
@property (weak) HIDDevice *device;
@property NSInteger tag;

- (void)sync;

@end

NS_ASSUME_NONNULL_END
