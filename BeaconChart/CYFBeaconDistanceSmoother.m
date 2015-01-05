//
//  RBINearestBeaconJudger.m
//  Identity
//
//  Created by Victor on 12/22/14.
//  Copyright (c) 2014 Robin Powered. All rights reserved.
//

#import "CYFBeaconDistanceSmoother.h"
@import CoreLocation;
#import "CYFBeacon.h"
#import "ReactiveCocoa.h"

static const float kAccuracyFar = 10;

@interface CYFBeaconHistory : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *history;
@property (nonatomic, readonly) NSUInteger historyMaxLength;
@property (nonatomic, readonly) NSUInteger historyMinLength;
@property (nonatomic, strong, readonly) CLBeacon *beacon;
@property (nonatomic) NSUInteger missingCount;
@property (nonatomic, strong, readonly) CLBeacon *missingBeacon;

///Average accuracy or -1 if the beacon is missing
@property (nonatomic) double averageAccuracy;

@end

@implementation CYFBeaconHistory

- (instancetype)initWithBeacon:(CLBeacon *)beacon maxHistoryLength:(NSUInteger)maxLength minHistoryLength:(NSUInteger)minLength
{
    self = [super init];
    if (self) {

        _history = [NSMutableArray arrayWithCapacity:maxLength];
        _historyMaxLength = maxLength;
        _beacon = beacon;
        _missingBeacon = [[CLBeacon alloc] init];
        _historyMinLength = minLength;
        
    }
    return self;
}

- (void)addBeaconRecord:(CLBeacon *)beacon {
    
    if (self.history.count >= self.historyMaxLength) {
        [self.history removeLastObject];
    }
    
    [self.history insertObject:beacon atIndex:0];
}

- (void)addBeaconMissingRecord {
    [self.history insertObject:self.missingBeacon atIndex:0];
}


///Calculate average accuracy over the last historyMaxLength beacon records and set result to _averageAccuracy
- (void)refreshAverageAccuracy {
    
    //Not enough history to calc average accuracy. Treat it as kAccuracyFar.
    if (self.history.count < self.historyMinLength) {
        self.averageAccuracy = kAccuracyFar;
        return;
    }
    
    int undeterminedAccuracyCount = 0;
    int accuracyMissingCount = 0;
    
    double total = 0;
    int divider = 0;
    for (NSUInteger i = 0; i < self.history.count; i++) {
        CLBeacon *record = self.history[i];
        
        if (record == self.missingBeacon) {
            accuracyMissingCount++;
        }
        else if (record.accuracy < 0) {
            undeterminedAccuracyCount++;
        }
        else {
            total += record.accuracy;
            divider++;
        }
    }
    
    //The beacon is missing more than once. Treat it as missing.
    if (accuracyMissingCount > 1) {
        self.averageAccuracy = -1;
        return;
    }
    
    //All the accuracy are either undetermined or missing
    if (divider == 0) {
        self.averageAccuracy = kAccuracyFar;
        return;
    }
    
    self.averageAccuracy = total / divider;
}

@end


@interface CYFBeaconDistanceSmoother ()

@property (nonatomic, strong) NSMutableDictionary *beaconToHistory;

@property (nonatomic) NSInteger counter;

@property (nonatomic, strong) NSArray *smoothedBeacons;

@end

@implementation CYFBeaconDistanceSmoother

- (instancetype)init
{
    self = [super init];
    if (self) {
        _beaconToHistory = [NSMutableDictionary dictionaryWithCapacity:30];
        _refreshRate = 3;
    }
    return self;
}

- (NSString *)keyOfBeacon:(CLBeacon *)beacon {
    NSString *key = [NSString stringWithFormat:@"%@:%@:%@", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor];
    return key;
}

- (void)addRangedBeacons:(NSArray *)beacons
{
    self.counter++;
    
    NSMutableSet *newBeaconKeys = [NSMutableSet setWithCapacity:20];
    
    for (CLBeacon *beacon in beacons) {
        
        NSString *key = [self keyOfBeacon:beacon];
        [newBeaconKeys addObject:key];
        
        CYFBeaconHistory *history = self.beaconToHistory[key];
        
        if (!history) {
            history = [[CYFBeaconHistory alloc] initWithBeacon:beacon maxHistoryLength:5 minHistoryLength:3];
            self.beaconToHistory[key] = history;
        }
        
        [history addBeaconRecord:beacon];
    }
    
    //check if any beacon in beaconToHistory is missing in this update
    for (NSString *key in self.beaconToHistory) {
        CYFBeaconHistory *history = self.beaconToHistory[key];
        
        if (![newBeaconKeys containsObject:key]) {
            NSLog(@"does not contain %@ %@", history.beacon.major, history.beacon.minor);
            [history addBeaconMissingRecord];
        }
    }
    
    if (self.counter > self.refreshRate) {
        self.counter = 0;
        [self smoothBeacons];
    }
}

- (void)smoothBeacons {
    

    NSMutableArray *historyToRemove = [NSMutableArray array];
    for (CYFBeaconHistory *history in self.beaconToHistory.allValues) {
        [history refreshAverageAccuracy];
        if (history.averageAccuracy < 0) {
            [historyToRemove addObject:[self keyOfBeacon:history.beacon]];
        }
    }
    
    for (NSString *key in historyToRemove) {
        [self.beaconToHistory removeObjectForKey:key];
    }
    
    self.smoothedBeacons =
        [[self.beaconToHistory.allValues.rac_sequence map:^id(CYFBeaconHistory *history) {
            
            return [[CYFBeacon alloc] initWithUUID:history.beacon.proximityUUID major:history.beacon.major minor:history.beacon.minor accuracy:history.averageAccuracy];
            
        }] array];

}



@end
