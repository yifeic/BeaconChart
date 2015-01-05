//
//  RBIBeaconManager.h
//  Identity
//
//  Created by Yifei Chen on 12/21/14.
//  Copyright (c) 2014 Robin Powered. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;
@class RACSignal;

@interface CYFBeaconManager : NSObject

@property (nonatomic, readonly) NSArray *regions;
@property (nonatomic, strong, readonly) RACSignal *rangedBeaconsSignal;

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager;
- (void)startMonitoringRegionsAndRangingBeacons;

@end
