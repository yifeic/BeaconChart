//
//  ChartViewController.m
//  TestBackground
//
//  Created by Yifei Chen on 1/1/15.
//  Copyright (c) 2015 Robin. All rights reserved.
//

#import "ChartViewController.h"

@import CoreLocation;
#import "CYFBeaconManager.h"
#import "ReactiveCocoa.h"
#import "CYFBeaconDistanceSmoother.h"
#import "CYFBeacon.h"

@interface ChartViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UIWebView *webViewOri;
@property (nonatomic, strong) CYFBeaconManager *manager;
@property (nonatomic, strong) CYFBeaconDistanceSmoother *beaconJudger;

@property (nonatomic) NSInteger color;
@property (nonatomic, strong) NSMutableDictionary *keyToColor;

@end

@implementation ChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.keyToColor= [NSMutableDictionary dictionary];
    
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:nil];
    [self.webViewOri loadHTMLString:htmlString baseURL:nil];
    
    CLBeaconRegion *br = [self.class robinRegion];
    br.notifyEntryStateOnDisplay = YES;
    br.notifyOnEntry = YES;
    br.notifyOnExit = YES;
    
    CLBeaconRegion *br1 = [self.class estimoteRegion];
    br1.notifyEntryStateOnDisplay = YES;
    br1.notifyOnEntry = YES;
    br1.notifyOnExit = YES;
    
    CLBeaconRegion *br2 = [self.class ipadRegion];
    br2.notifyEntryStateOnDisplay = YES;
    br2.notifyOnEntry = YES;
    br2.notifyOnExit = YES;
    
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    self.manager = [[CYFBeaconManager alloc] initWithRegions:@[br, br1] locationManager:locationManager];
    
    
    [self.manager.rangedBeaconsSignal subscribeNext:^(NSArray *beacons) {
        
        NSLog(@"add beacons %ld", beacons.count);
        [self.beaconJudger addRangedBeacons:beacons];
        [self addBeacons:beacons toWebView:self.webViewOri];
    }];
    
    CYFBeaconDistanceSmoother *beaconJudger = [[CYFBeaconDistanceSmoother alloc] init];
    beaconJudger.refreshRate = 3;
    self.beaconJudger = beaconJudger;
    
    [[RACObserve(self, beaconJudger.smoothedBeacons) ignore:nil] subscribeNext:^(NSArray *sortedBeacons) {
        [self addBeacons:sortedBeacons toWebView:self.webView];
    }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    
    
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startRanging:(id)sender {
    


    [self.manager startMonitoringRegionsAndRangingBeacons];
}


- (void)addBeacons:(NSArray *)beacons toWebView:(UIWebView *)webView {

    
    NSArray *arg =
    [[beacons.rac_sequence map:^id(CYFBeacon *beacon) {
        
        NSString *key = [NSString stringWithFormat:@"%@:%@:%@", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor];
        
        NSNumber *color = self.keyToColor[key];
        if (color == nil) {
            color = @(self.color % 20);
            self.color++;
            self.keyToColor[key] = color;
        }
        
        NSString *name = [NSString stringWithFormat:@"%@:%@", beacon.major, beacon.minor];
        
        return @{@"bid": key, @"color": color, @"name": name, @"distance": @([[NSString stringWithFormat:@"%.2f", beacon.accuracy] floatValue])};
        
    }] array];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arg
                                                       options:0
                                                         error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *argString = [NSString stringWithFormat:@"tick(%@)", jsonString];
    
    NSLog(@"arg \n %@", argString);
    [webView stringByEvaluatingJavaScriptFromString:argString];
    
}

+ (CLBeaconRegion *)ipadRegion {
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:@"44F77920-EBF9-11E3-AC10-0800200C9A67"];
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"ipadRegion"];
}

+ (CLBeaconRegion *)estimoteRegion {
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"estimoteRegion"];
}

+ (CLBeaconRegion *)robinRegion {
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:@"44F77920-EBF9-11E3-AC10-0800200C9A66"];
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"robinRegion"];
}

@end
