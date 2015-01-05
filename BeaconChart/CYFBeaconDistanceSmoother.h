//
//  RBINearestBeaconJudger.h
//  Identity
//
//  Created by Victor on 12/22/14.
//  Copyright (c) 2014 Robin Powered. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Calculate running average of beacons' distance(accuracy).
 *  Feed smoother with CLBeacon by calling -addRangedBeacons:. Smoother will update smoothedBeacons at refreshRate.
 *  For example, if refreshRate is 3, then smoother updates smoothedBeacons every 3 times -addRangedBeacons: is called.
 */
@interface CYFBeaconDistanceSmoother : NSObject

/// Feed smoother with raw CLBeacons.
- (void)addRangedBeacons:(NSArray *)beacons;

@property (nonatomic) NSInteger refreshRate;

/// An array of CYFBeacon.
@property (nonatomic, strong, readonly) NSArray *smoothedBeacons;

@end
