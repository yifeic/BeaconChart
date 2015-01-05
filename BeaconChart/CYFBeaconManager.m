//
//  RBIBeaconManager.m
//  Identity
//
//  Created by Yifei Chen on 12/21/14.
//  Copyright (c) 2014 Robin Powered. All rights reserved.
//

#import "CYFBeaconManager.h"
#import "ReactiveCocoa.h"
#import "CYFBeaconDistanceSmoother.h"
#import "CYFBeacon.h"

@import CoreLocation;

@interface CYFBeaconManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end



@implementation CYFBeaconManager

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager
{
    self = [super init];
    if (self) {
        _locationManager = locationManager;
        _locationManager.delegate = self;
        
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _locationManager.distanceFilter = 35;
        
        _regions = regions;
        
        
//        NSDictionary *map = @{
//                              
//                              @"D57092AC-DFAA-446C-8EF3-C81AA22815B5:5:5000": @"WORK AREA",
//                              @"44F77920-EBF9-11E3-AC10-0800200C9A66:9:83": @"WORK AREA",
//                              @"44F77920-EBF9-11E3-AC10-0800200C9A66:5:82": @"KITCHEN",
//                              @"44F77920-EBF9-11E3-AC10-0800200C9A66:5:80": @"HAL's Nook",
//                              @"44F77920-EBF9-11E3-AC10-0800200C9A66:10:50": @"Whiskey Room",
//                              @"44F77920-EBF9-11E3-AC10-0800200C9A66:5:78": @"Conference Room"
//                              };
//        
        
        
        RACSignal *regionEnterSignal =
            [[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                filter:^BOOL(RACTuple *tuple) {
                    return [tuple.second integerValue] == CLRegionStateInside;
                }];
        
        [regionEnterSignal subscribeNext:^(id x) {
            [self.locationManager startUpdatingLocation];
        }];
        
        
        RACSignal *rangedBeaconsSignal = [self rac_signalForSelector:@selector(locationManager:didRangeBeacons:inRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)];
        NSArray *regionsRangedBeaconsSignals =
            [[self.regions.rac_sequence map:^id(CLBeaconRegion *region) {
                return
                    [[rangedBeaconsSignal
                        filter:^BOOL(RACTuple *tuple) { //tuple consits of CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *region
                            return [tuple.third isEqual:region];
                        }]
                        reduceEach:^(CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *_) {
                            return beacons;
                        }];
            }] array];
        
        
        RACSignal *combinedRangedBeaonsSignal =
            [[[RACSignal combineLatest:regionsRangedBeaconsSignals] throttle:0.3] map:^id(RACTuple *regionsRangedBeacons) {
                return
                    [regionsRangedBeacons.rac_sequence foldLeftWithStart:[NSMutableArray arrayWithCapacity:20] reduce:^id(NSMutableArray *result, NSArray *rangedBeacons) {
                        
                        NSArray *filtered =
                        [[rangedBeacons.rac_sequence filter:^BOOL(CLBeacon *beacon) {
                            if ([beacon.major isEqual:@19] && [beacon.minor isEqual:@20]) {
                                return NO;
                            }
                            return YES;
                        }] array];
                        
                        [result addObjectsFromArray:filtered];
                        return result;
                    }];
            }];
        _rangedBeaconsSignal = combinedRangedBeaonsSignal;
        
        
        //if ranged beaons are empty for 4 times, stopUpdatingLocation which disables background ranging.
        RACSignal *noBeaconsNearbySignal =
            [[combinedRangedBeaonsSignal scanWithStart:@0 reduce:^id(NSNumber *zeroCount, NSArray *next) {
                if (next.count == 0) {
                    return @([zeroCount integerValue]+1);
                }
                return @1;
            }] filter:^BOOL(NSNumber *count) {
                return [count integerValue] > 3;
            }];
        
        [noBeaconsNearbySignal subscribeNext:^(id x) {
            [self.locationManager stopUpdatingLocation];
        }];
        

    }
    return self;
}

- (void)startMonitoringRegionsAndRangingBeacons {
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
    

    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager startMonitoringForRegion:region];
        [self.locationManager requestStateForRegion:region];
        [self.locationManager startRangingBeaconsInRegion:region];
    }
    
}




@end
