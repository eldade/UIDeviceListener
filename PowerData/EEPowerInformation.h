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

#import <Foundation/Foundation.h>

@class EEPowerInformation;

@protocol EEPowerInformationDelegate <NSObject>

- (void) powerInformationUpdated: (EEPowerInformation * _Nonnull) powerInformation;

@end

@interface EEPowerInformation : NSObject
{
}

@property (nonatomic, weak, nullable) id<EEPowerInformationDelegate> delegate;

// ****************************************************************************************************
// dataTimestamp: This is timestamp of the currently available data. Data typically gets updated every
// ~20 seconds or so, but can be updated more frequently when the device is plugged in or out.
// ****************************************************************************************************
@property (readonly, nonnull) NSDate *dataTimestamp;

// ****************************************************************************************************
// When supported, this will provide last plugged-in timestamp (while the device is unplugged).
// This is only available for iOS 9, and for hardware released in 2014 and later.
// ****************************************************************************************************
@property (readonly, nullable) NSDate *pluggedInTimestamp;

// ****************************************************************************************************
// batteryCycleCount: This is the number of times the battery has been discharged the equivalent of
// 100% of its capacity. Note that partial discharges and recharge cycles are accumulated, and the
// counter gets eventually incremented.
// ****************************************************************************************************
@property (readonly) NSInteger batteryCycleCount;

// ****************************************************************************************************
// batterySerialNumber: This is the battery serial number. This value changes if the user replaces the
// device's battery.
// NOTE: Only supported on iOS 7.x.
// ****************************************************************************************************
@property (readonly, nullable) NSString *batterySerialNumber;

// ****************************************************************************************************
// batteryMfgDate: This is the battery's date of manufacture (extracted from the serial number).
// NOTE: Only supported on iOS 7.x.
// ****************************************************************************************************
@property (readonly, nullable) NSDate *batteryMfgDate;

// ****************************************************************************************************
// batteryDesignCapacity: This is the battery's original design capacity in mAh (milliamperes/hour)
// ****************************************************************************************************
@property (readonly) NSInteger batteryDesignCapacity;

// ****************************************************************************************************
// batteryMaximumCapacity: This is the battery's current maximum capacity, expressed in mAh.
// This is used to determine  how much capacity has been lost relative to the batteryDesignCapacity.
// Note that this value is an estimate made by the battery gas gauge and that it fluctuates quite wildly.
// ****************************************************************************************************
@property (readonly) NSInteger batteryMaximumCapacity;

// ****************************************************************************************************
// batteryHealth: This is the battery health percentage, with a value of 1.0 representing a perfect
// battery. This value is calculated as simply batteryMaximumCapacity / batteryDesignCapacity.
// ****************************************************************************************************
@property (readonly) float batteryHealth;

// ****************************************************************************************************
// batteryRawLevel: This is the raw battery level, eliminating Apple's algorithm designed to make
// the battery percentage look "pretty" by doing things like ensuring that every charge ends-up
// 100% and that during discharging the value stays at 100% for a while. The values appear to be close
// to the system reported value, but not identical.
// ****************************************************************************************************
@property (readonly) float batteryRawLevel;

// ****************************************************************************************************
// gasGaugeDetected: Reports if a gas gauge chip was detected for this device. A gas gauge chip is
// what provides detailed battery information such as device power consumption, battery cycle counting,
// and accurate maximum capacity information. Without a gas gauge, all of these properties will return
// 0. All iOS devices except for the iPod Touch have gas gauge chips. As of 2016 none of the iPod Touch
// products have a gas gauge chip.
// ****************************************************************************************************
@property (readonly) BOOL gasGaugeDetected;

// ****************************************************************************************************
// voltage: The voltage at the battery terminals. During charging this will be the voltage
// applied to the battery, and during discharge this will be the battery output voltage.
// ****************************************************************************************************
@property (readonly) float voltage;

// ****************************************************************************************************
// isPluggedIn: Indicates that the device is plugged-in.
// ****************************************************************************************************
@property (readonly) BOOL isPluggedIn;

// ****************************************************************************************************
// isCharging: Indicates that the device is currently charging. Note that in many cases a device can
// be isPluggedIn == YES, but isCharging == NO. This happens if the battery is too cold/hot, when the
// battery is full, when the power source has insufficient power, etc.
// ****************************************************************************************************
@property (readonly) BOOL isCharging;

// ****************************************************************************************************
// isFullyCharged: Indicates that the device is fully charged (only while isPluggedIn == YES)
// ****************************************************************************************************
@property (readonly) BOOL isFullyCharged;

// ****************************************************************************************************
// batteryTemperature: Indicates the battery's internal temperatures, in degrees celsius (C).
// ****************************************************************************************************
@property (readonly) float batteryTemperature;

// ****************************************************************************************************
// adapterAmperage: The currently plugged-in adapter's amperage (in mA).
// ****************************************************************************************************
@property (readonly) NSInteger adapterAmperage;

// ****************************************************************************************************
// adapterWattage: The currently plugged-in adapter's wattage (in watts).
// ****************************************************************************************************
@property (readonly) NSInteger adapterWattage;

// ****************************************************************************************************
// chargerConfiguration represents the current desired charging current, in mA. Actual charging current
// is likely going  to be lower, but this gives an idea of how fast the battery should be charging.
// For example, on devices with large batteries such as iPads, this figure will often exceed the
// adapterAmperage, which tells you that the device is not charging as quickly is it could.
//
// This returns 0 when the device is unplugged.
// ****************************************************************************************************
@property (readonly) NSInteger chargerConfiguration;

// ****************************************************************************************************
// chargingAmperage returns the actual charging amperage for your device (in mA) while it is charging.
// ****************************************************************************************************
@property (readonly) NSInteger chargingAmperage;

// ****************************************************************************************************
// dischargeAmperage: When the device is unplugged, this provides the discharge current in mA, as measured
// at the battery terminals.
// ****************************************************************************************************
@property (readonly) NSInteger dischargeAmperage;

// ****************************************************************************************************
// devicePowerConsumption: When the device is unplugged, this provides the device's power consumption, in
// watts.
// ****************************************************************************************************
@property (readonly) float devicePowerConsumption;

@end
