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

#import "EEPowerInformation.h"
#import "UIDeviceListener.h"

@interface EEPowerInformation()
{
    NSDictionary *latestPowerDictionary;
    UIDeviceListener *listener;
}

@property (nullable, readonly) NSDictionary *chargerData;
@property (nullable, readonly) NSDictionary *adapterDetails;

@property (readonly) NSInteger instantAmperage;

@end

@implementation EEPowerInformation

- (instancetype) init
{
    self = [super init];
    
    listener = [UIDeviceListener sharedUIDeviceListener];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listenerDataUpdated:) name: kUIDeviceListenerNewDataNotification object:nil];
    
    [listener startListener];
    [listener stopListener];
    
    return self;
}

- (void) setDelegate:(id<EEPowerInformationDelegate>)delegate
{
    [listener stopListener];
    _delegate = delegate;
    
    if (delegate != nil)
    {
        [listener startListener];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kUIDeviceListenerNewDataNotification object: nil];
}

- (void) listenerDataUpdated: (NSNotification *) notification
{
    latestPowerDictionary = notification.userInfo;
    
    if (self.delegate != nil)
        [self.delegate powerInformationUpdated: self];
}

// This subdictionary provides additional charger details, but is only available for iOS 9, and for hardware
// released in 2014 and later (iPhone 6/6 Plus and later).
- (NSDictionary *) chargerData
{
    return latestPowerDictionary[@"ChargerData"];
}

- (NSDictionary *) adapterDetails
{
    return latestPowerDictionary[@"AdapterDetails"];
}

- (NSDate *) pluggedInTimestamp
{
    if (self.chargerData == nil)
        return nil;
    
    NSInteger updateTime = [self.chargerData[@"UpdateTime"] integerValue];
    return  [NSDate dateWithTimeIntervalSince1970: updateTime];
}

- (NSDate *) dataTimestamp
{
    return [NSDate dateWithTimeIntervalSince1970: [latestPowerDictionary[@"UpdateTime"] integerValue]];
}

- (NSInteger) batteryCycleCount
{
    return [latestPowerDictionary[@"CycleCount"] integerValue];
}

- (NSInteger) instantAmperage
{
    return [latestPowerDictionary[@"InstantAmperage"] integerValue];
}

- (NSInteger) batteryDesignCapacity
{
    return [latestPowerDictionary[@"DesignCapacity"] integerValue];
}

- (NSString *) batterySerialNumber
{
    return latestPowerDictionary[@"Serial"];
}

- (NSDate *) batteryMfgDate
{
    if (self.batterySerialNumber != nil && [self.batterySerialNumber length] > 0)
    {
        NSString *MfgDateSubString = nil;
        if ([self.batterySerialNumber length] == 17)
        {
            MfgDateSubString = [self.batterySerialNumber substringWithRange: NSMakeRange(3, 4)];
            
        }
        else if ([self.batterySerialNumber length] == 18)
        {
            MfgDateSubString = [self.batterySerialNumber substringWithRange: NSMakeRange(2, 4)];
        }
        
        if (MfgDateSubString != nil)
        {
            NSDate *currentDate = [NSDate date];
            NSCalendar* calendar = [NSCalendar currentCalendar];
            NSDateComponents* components = [calendar components:NSCalendarUnitYear fromDate:currentDate];
            NSInteger currentYear = [components year];
            
            NSString *currentYearPrefix = [[NSString stringWithFormat: @"%ld", (long)currentYear] substringWithRange:NSMakeRange(0, 3)];
            NSString *currentYearYearDigit = [[NSString stringWithFormat: @"%ld", (long)currentYear] substringWithRange: NSMakeRange(3, 1)];
            
            NSString *mfgDateYearDigit = [MfgDateSubString substringWithRange: NSMakeRange(0, 1)];
            
            if ([currentYearYearDigit integerValue] < [mfgDateYearDigit integerValue])
            {
                currentYearPrefix = [NSString stringWithFormat: @"%ld", [currentYearPrefix integerValue] - 1];
            }
            
            MfgDateSubString = [NSString stringWithFormat:@"%@%@", currentYearPrefix, MfgDateSubString];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
            formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
            [formatter setDateFormat:@"YYYYwwe"];
            
            NSDate *mfgDate = [formatter dateFromString: MfgDateSubString];
            return mfgDate;
        }
    }
    
    return nil;
}

- (BOOL) gasGaugeDetected
{
    if ((self.batteryMaximumCapacity == self.batteryDesignCapacity) && self.batteryCycleCount == 0)
        return NO;
    else
        return YES;
}

- (NSInteger) batteryMaximumCapacity
{
    return [latestPowerDictionary[@"AppleRawMaxCapacity"] integerValue];
}

- (float) batteryRawLevel
{
    float rawLevel = [latestPowerDictionary[@"AppleRawCurrentCapacity"] floatValue] / [latestPowerDictionary[@"AppleRawMaxCapacity"] floatValue];
    
    return MAX(MIN(rawLevel, 1.0), 0.0);
}

- (float) batteryHealth
{
    float rawHealth = [latestPowerDictionary[@"AppleRawMaxCapacity"] floatValue] / [latestPowerDictionary[@"DesignCapacity"] floatValue];
    
    return MAX(MIN(rawHealth, 1.0), 0.0);
}

- (BOOL) isPluggedIn
{
    return [latestPowerDictionary[@"ExternalConnected"] boolValue];
}

- (BOOL) isCharging
{
    return [latestPowerDictionary[@"IsCharging"] boolValue];
}

- (BOOL) isFullyCharged
{
    return [latestPowerDictionary[@"FullyCharged"] boolValue];
}

- (NSInteger) adapterAmperage
{
    return [self.adapterDetails[@"Amperage"] integerValue];
}

- (NSInteger) adapterWattage
{
    return [self.adapterDetails[@"Watts"] integerValue];
}

- (float) batteryTemperature
{
    return [latestPowerDictionary[@"Temperature"] floatValue] / 100.0;
}

- (float) voltage
{
    return [latestPowerDictionary[@"Voltage"] floatValue] / 1000.0;
}

- (NSInteger) chargerConfiguration
{
    return [latestPowerDictionary[@"ChargerConfiguration"] integerValue];
}

- (NSInteger) chargingAmperage
{
    if (self.instantAmperage > 0) {
        return self.instantAmperage;
    }
    
    return 0;
}

- (NSInteger) dischargeAmperage
{
    if (self.instantAmperage < 0) {
        return -self.instantAmperage;
    }
    
    return 0;
}

- (float) devicePowerConsumption
{
    if (self.dischargeAmperage == 0)
        return 0;
    
    return (float) self.dischargeAmperage * self.voltage / 1000.0;
}

@end
