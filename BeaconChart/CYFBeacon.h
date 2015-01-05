//
//  CYFBeacon.h
//  Identity
//
//  Created by Victor on 12/30/14.
//  Copyright (c) 2014 Robin Powered. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYFBeacon : NSObject

@property (readonly, nonatomic, strong) NSUUID *proximityUUID;

@property (readonly, nonatomic, strong) NSNumber *major;

@property (readonly, nonatomic, strong) NSNumber *minor;

@property (readonly, nonatomic, strong) NSString *key;

@property (nonatomic) double accuracy;

- (instancetype)initWithUUID:(NSUUID *)UUID major:(NSNumber *)major minor:(NSNumber *)minor accuracy:(double)accuracy;

@end
