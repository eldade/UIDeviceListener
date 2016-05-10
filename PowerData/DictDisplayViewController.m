/*
 *
 *    Copyright (C) 2016 Eldad Eilam
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This Program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with PowerData.  If not, see <http://www.gnu.org/licenses/>.
 *
 */


#import "DictDisplayViewController.h"
#import "UIDeviceListener.h"
#import "EEPowerInformation.h"

@interface DictDisplayViewController () <EEPowerInformationDelegate>
{
    EEPowerInformation *powerInformation;
}

@end

@implementation DictDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    powerInformation = [[EEPowerInformation alloc] init];
    powerInformation.delegate = self;
}

- (void) powerInformationUpdated: (EEPowerInformation *) powerInfo
{
    self.textView.text = [NSString stringWithFormat:@"\n\nData updated on %@\n"
                                                    @"batteryDesignCapacity=%ld\n"
                                                    @"batteryCycleCount=%ld\n"
                                                    @"batteryMaximumCapacity=%ld\n"
                                                    @"batteryHealth=%f\n"
                                                    @"batteryRawBatteryLevel=%f\n"
                                                    @"voltage=%f\n"
                                                    @"isPluggedIn=%d\n"
                                                    @"isCharging=%d\n"
                                                    @"isFullyCharged=%d\n"
                                                    @"batteryTemperature=%f\n"
                                                    @"adapterAmperage=%ld\n"
                                                    @"adapterWattage=%ld\n"
                                                    @"chargerConfiguration=%ld\n"
                                                    @"chargingAmperage=%ld\n"
                                                    @"dischargeAmperage=%ld\n"
                                                    @"devicePowerConsumption=%f\n",
                                                    [powerInformation.dataTimestamp descriptionWithLocale: [NSLocale currentLocale]],
                                                    powerInformation.batteryDesignCapacity,
                                                    powerInformation.batteryCycleCount,
                                                    powerInformation.batteryMaximumCapacity,
                                                    powerInformation.batteryHealth,
                                                    powerInformation.batteryRawLevel,
                                                    powerInformation.voltage,
                                                    powerInformation.isPluggedIn,
                                                    powerInformation.isCharging,
                                                    powerInformation.isFullyCharged,
                                                    powerInformation.batteryTemperature,
                                                    powerInformation.adapterAmperage,
                                                    powerInformation.adapterWattage,
                                                    powerInformation.chargerConfiguration,
                                                    powerInformation.chargingAmperage,
                                                    powerInformation.dischargeAmperage,
                                                    powerInformation.devicePowerConsumption];
    
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

@end
