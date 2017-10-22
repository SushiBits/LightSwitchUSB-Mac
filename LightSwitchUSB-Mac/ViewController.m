//
//  ViewController.m
//  LightSwitchUSB-Mac
//
//  Created by Max Chan on 21/10/2017.
//  Copyright © 2017 Max Chan. All rights reserved.
//

#import "ViewController.h"
#import <HIDAPI/HIDAPI.h>
#import "LightSwitch.h"

@interface ViewController ()

@property double brightnessRatio;

@property NSArray<HIDDevice *> *devices;
@property NSMutableArray<LightSwitch *> *switches;

@property (weak) LightSwitch *currentLightSwitch;
@property (null_resettable, nonatomic) NSTimer *syncTimer;

@property (weak) IBOutlet NSPopUpButton *selector;

@end

@implementation ViewController

@synthesize currentLightSwitch = _currentLightSwitch;
@synthesize syncTimer = _syncTimer;

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self sync:self];
    [[NSRunLoop mainRunLoop] addTimer:self.syncTimer forMode:NSRunLoopCommonModes];
}

- (void)viewDidDisappear
{
    [self.syncTimer invalidate];
    self.syncTimer = nil;
    [super viewDidDisappear];
}

- (IBAction)sync:(id)sender
{
    NSArray *devices = [HIDDevice enumerateWithVendorID:0x0002 productID:0xc001];
    if (![devices isEqualToArray:self.devices])
    {
        self.devices = devices;
        NSMutableArray *remainingDevices = self.devices.mutableCopy;
        
        if (!self.switches)
            self.switches = [NSMutableArray array];
        
        for (NSInteger idx = self.switches.count - 1; idx >= 0; idx--)
        {
            LightSwitch *lightSwitch = self.switches[idx];
            if (lightSwitch.device && [self.devices containsObject:lightSwitch.device])
            {
                [remainingDevices removeObject:lightSwitch.device];
                //[lightSwitch sync];
            }
            else
                [self.switches removeObjectAtIndex:idx];
        }
        
        for (HIDDevice *device in remainingDevices)
        {
            LightSwitch *lightSwitch = [[LightSwitch alloc] init];
            lightSwitch.device = device;
            [self.switches addObject:lightSwitch];
            [lightSwitch sync];
        }
        
        [self.switches sortUsingComparator:^NSComparisonResult(LightSwitch *_Nonnull obj1, LightSwitch *_Nonnull obj2) {
            return [obj1.device.serialNumber compare:obj2.device.serialNumber];
        }];
        
        [self.selector removeAllItems];
        self.selector.enabled = YES;
        for (LightSwitch *lightSwitch in self.switches)
        {
            [self.selector addItemWithTitle:lightSwitch.device.serialNumber];
        }
        
        if (self.currentLightSwitch)
        {
            NSUInteger selectedIndex = [self.switches indexOfObject:self.currentLightSwitch];
            if (selectedIndex != NSNotFound)
            {
                [self.selector selectItemAtIndex:selectedIndex];
            }
        }
        else if (self.switches.count)
        {
            self.currentLightSwitch = self.switches.firstObject;
            [self.selector selectItemAtIndex:0];
        }
        else
        {
            self.selector.enabled = NO;
        }
    }
    else
    {
        //for (LightSwitch *lightSwitch in self.switches)
        //{
        //    [lightSwitch sync];
        //}
    }
}

- (IBAction)selectSwitch:(id)sender
{
    NSInteger index = self.selector.indexOfSelectedItem;
    if (index >= 0)
        self.currentLightSwitch = self.switches[index];
}

- (NSTimer *)syncTimer
{
    if (!_syncTimer)
        _syncTimer = [NSTimer timerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(sync:)
                                               userInfo:nil
                                                repeats:YES];
    
    return _syncTimer;
}

@end
