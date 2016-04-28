# PowerData
PowerData is a sample program that displays device power information for iOS devices. 

PowerData presents raw data from the system regarding battery capacity, cycle count, state of charge, and much much more. PowerData also presents other information regarding the currently plugged in power adapter. None of this is currently (as of iOS 9) available in any public API.

###No private APIs!

The information presented by this program can be gathered relatively easily using IOKit, and is available in the IORegistry. What's unique about PowerData is that it obtains this data without invoking any private APIs of any kind (!!). This is not a case of obfuscation or any kind of trickery where we're just hiding or covertly calling private APIs. They're just not called.

###Can this be used on the App Store?
I have successfully used this in production code on the App Store, but YMMV. 

The App Store generally has two levels of private API tests. One test takes place at the moment of submission, and is essentially a simple static check to make sure your binary contains to references to any private APIs. PowerData will pass this test because it simply doesn't rely on any private APIs. The second test, which appears to only be performed on apps that are deemed suspicious by the App Store team, will also not detect PowerData. Again, PowerData obtains "private" data, but it does so without invoking any private interfaces.

###So can I go ahead and submit a battery/charging information app that presents this data to end-users?
Go ahead, but you're still likely to get rejected by Apple. Even though PowerData is likely to pass any technical tests Apple runs on your App, the App Review team consists of human beings who are likely to detect that your app presents information that Apple doesn't deem "end-user appropriate"... This ultimately happened to me, and the rejection comes in as section 2.19:
>  2.19       Apps that provide incorrect diagnostic or other inaccurate device data will be rejected
Of course, the data presented is about as accurate as it could ever be, but clearly Apple has decided that for now they're not willing to present this data to end-users, and so expect to get this rejection.

###What kind of power data can I get?
Pretty much every datapoint regarding battery and power known to the system is exposed. This includes the following:
- Battery design capacity
- Battery current raw capacity (in mAh)
- Battery cycle count
- Current battery temperature
- Current battery voltage
- Current battery discharge rate (device power consumption), in mA

When the device is plugged in, there is rich information regarding the currently plugged in power source:
- The wattage and amperage of the currently plugged in adapter
- The actual battery charging rate (in mA), if the device is charging
- Confirmation that the device is actually charging. On some power hungry iOS devices you will often see devices consuming *some* battery power even though they are plugged in.

### Sample dictionaries
Here are a couple of sample dictionaries of actual output from PowerData. The dictionaries have different structures depending on what version of iOS the device is running. For iOS 8 and later, the dictionary is structured as follows:

####iOS 8 and later dictionary
```
{
    AbsoluteCapacity = 7473;
    AdapterDetails =     {
        AdapterVoltage = 5000;
        Amperage = 500;
        Description = "usb host";
        FamilyCode = "-536854528";
        PMUConfiguration = 470;
        Watts = 2;
    };
    AdapterInfo = 16384;
    Amperage = 500;
    AppleChargeRateLimitIndex = 0;
    AppleRawAdapterDetails =     (
                {
            AdapterVoltage = 5000;
            Amperage = 500;
            Description = "usb host";
            FamilyCode = "-536854528";
            PMUConfiguration = 470;
            Watts = 2;
        },
                {
            AdapterVoltage = 5000;
            Amperage = 0;
            Description = batt;
            FamilyCode = 0;
            PMUConfiguration = 0;
            Watts = 0;
        }
    );
    AppleRawBrickIDVoltages =     (
                (
            39,
            39
        ),
                (
        )
    );
    AppleRawCurrentCapacity = 6984;
    AppleRawExternalConnected = 1;
    AppleRawMaxCapacity = 7321;
    AtCriticalLevel = 0;
    AtWarnLevel = 0;
    BatteryInstalled = 1;
    BatteryKey = "0003-default";
    BestAdapterIndex = 0;
    BootBBCapacity = 5199;
    BootCapacityEstimate = 72;
    BootVoltage = 3990;
    CFBundleIdentifier = "com.apple.driver.AppleARMPlatform";
    ChargerConfiguration = 2720;
    CurrentCapacity = 7252;
    CycleCount = 8;
    DesignCapacity = 7161;
    ExternalChargeCapable = 1;
    ExternalConnected = 1;
    FullyCharged = 0;
    IOClass = AppleARMPMUCharger;
    IOFunctionParentA1000000 = <>;
    IOGeneralInterest = "IOCommand is not serializable";
    IOMatchCategory = IODefaultMatchCategory;
    IONameMatch = charger;
    IONameMatched = charger;
    IOPowerManagement =     {
        CapabilityFlags = 32832;
        CurrentPowerState = 2;
        DevicePowerState = 2;
        MaxPowerState = 2;
    };
    IOProbeScore = 1000;
    IOProviderClass = IOService;
    InstantAmperage = "-670";
    IsCharging = 1;
    Location = 0;
    Manufacturer = 6;
    MaxCapacity = 7400;
    Model = "0003-6";
    NominalChargeCapacity = 7681;
    PresentDOD = 953;
    Temperature = 2480;
    TimeRemaining = 0;
    UpdateTime = 1461830544;
    Voltage = 4260;
    "built-in" = 1;
}
```
####iOS 7 dictionary
```
{
    AdapterDetails =     {
        Amperage = 1000;
        Description = "usb host";
        FamilyCode = "-536854528";
        PMUConfiguration = 1000;
        Watts = 5;
    };
    AdapterInfo = 16384;
    Amperage = 1000;
    AppleRawCurrentCapacity = 1279;
    AppleRawMaxCapacity = 1275;
    AtCriticalLevel = 0;
    AtWarnLevel = 0;
    BatteryData =     {
        BatterySerialNumber = REDACTED;
        ChemID = 355;
        CycleCount = 524;
        DesignCapacity = 1420;
        Flags = 640;
        FullAvailableCapacity = 1325;
        ManufactureDate = REDACTED;
        MaxCapacity = 1273;
        MfgData = REDACTED;
        QmaxCell0 = 1350;
        StateOfCharge = 100;
        Voltage = 4194;
    };
    BatteryInstalled = 1;
    BatteryKey = "0003-default";
    BootBBCapacity = 52;
    BootCapacityEstimate = 2;
    BootVoltage = 3518;
    CFBundleIdentifier = "com.apple.driver.AppleD1815PMU";
    ChargerConfiguration = 990;
    CurrentCapacity = 1275;
    CycleCount = 524;
    DesignCapacity = 1420;
    ExternalChargeCapable = 1;
    ExternalConnected = 1;
    FullyCharged = 1;
    IOClass = AppleD1815PMUPowerSource;
    IOFunctionParent64000000 = <>;
    IOGeneralInterest = "IOCommand is not serializable";
    IOInterruptControllers =     (
        IOInterruptController34000000,
        IOInterruptController34000000,
        IOInterruptController34000000,
        IOInterruptController34000000
    );
    IOInterruptSpecifiers =     (
        <03000000>,
        <26000000>,
        <04000000>,
        <24000000>
    );
    IOMatchCategory = AppleD1815PMUPowerSource;
    IOPowerManagement =     {
        CurrentPowerState = 2;
        DevicePowerState = 2;
        MaxPowerState = 2;
    };
    IOProbeScore = 0;
    IOProviderClass = AppleD1815PMU;
    InstantAmperage = 0;
    IsCharging = 0;
    Location = 0;
    Manufacturer = A;
    MaxCapacity = 1275;
    Model = "0003-A";
    Serial = REDACTED;
    Temperature = 2590;
    TimeRemaining = 0;
    UpdateTime = 1461830702;
    Voltage = 4182;
    "battery-data" =     {
        "0003-default" = <...>;
        "0004-default" = <...>;
        "0005-default" = <...};
    "built-in" = 1;
}
```

###System Requirements
PowerData has been extensively tested and runs well on essentially **any** iOS device (iPod Touch, iPad, and iPhone). PowerData supports iOS 7 and later, with 9.3.1 being the most recent version that's been tested.

###How does it work?
PowerData essentially hijacks the power data from iOS. We use [UIDevice](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/), which is a public API for getting system information. Internally, UIDevice utilizes IOKit (and the specific power dictionary we're after) in order to get information for two specific properties: [batteryLevel](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryLevel) and [batteryState](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryState).
PowerData's primary class is called `UIDeviceListener`. `UIDeviceListener` tells `UIDevice` to listen for updates to those two properties (it does so by setting the [batteryMonitoringEnabled](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryMonitoringEnabled) property to `YES`. 
As updates come in on those two properties, 
###How reliable is that approach?
This is obviously a hack. The approach works perfectly on iOS 7 through iOS 9.3.1, but that does not guarantee that future iOS updates won't break it. It relies on a number of implementation details in `UIDevice` that are definitely subject to change by Apple without warning. In this sense using this library is equivalent to using a private API.
