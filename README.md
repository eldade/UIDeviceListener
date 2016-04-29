## PowerData (sample program for `UIDeviceListener`)
PowerData is a sample program that displays device power information for iOS devices. The magic is that this is done without relying on any private APIs. The underlying library, `UIDeviceListener`, is extremely easy to use and runs well on all recent versions of iOS.

PowerData presents raw data from the system regarding battery capacity, cycle count, state of charge, and much much more. PowerData also presents detailed information regarding the currently plugged in power adapter. None of this is currently (as of iOS 9) available in any public API.

###No private APIs!

The information provided by `UIDeviceListener` is available in the IORegistry and could be gathered relatively easily by directly calling IOKit. Unfortunately, IOKit is considered a private framework and so using it almost guarantees that your app would be rejected by Apple's App Review team if you were to submit it to the App Store. `UIDeviceListener` doesn't use IOKit, neither directly nor indirectly. `UIDeviceListener` also doesn't rely on any other private API. Please see the [How it works](###How does it work?) section below to learn more.

###Usage

Using `UIDeviceListener` is quite simple. First, copy the source files (`UIDeviceListener.h` and `UIDeviceListener.mm`) to your project. Then, initialize the listener as follows:

```
    UIDeviceListener *listener = [UIDeviceListener sharedUIDeviceListener];
    
    [listener startListenerWithNotificationBlock:^(NSDictionary *powerDataDictionary) {
      NSLog([powerDataDictionary description]);
     }];

```

That's all there is to it. The block will be called when you first call startListenerWithNotificationBlock: and then periodically, as the power data is updated. On most devices this happens every 20 seconds or so, but it also happens in real-time as the device is plugged in and out. See below for a sample of the kind of data contained in the dictionary.

###Can this be used on the App Store?
I have seen this code successfully deployed in production code on the App Store, but YMMV. 

The App Store generally has two levels of private API tests. One test takes place at the moment when a binary is submitted, and is essentially a simple static check to make sure your binary contains no references to any private API symbols. `UIDeviceListener` will pass this test because it simply doesn't rely on any private APIs. The second test, which appears to only be performed on apps that are deemed 'suspicious' by the App Store Review team, will also not detect `UIDeviceListener`. 

Again, `UIDeviceListener` does obtain "private" data, but it does so without invoking any private interfaces. Essentially, it is using public APIs to "steal" the relevant data from `UIDevice` in runtime.

###So can I go ahead and submit a battery/charging app that presents this data to my end-users?
Go ahead, but you're still likely to get rejected by Apple. Even though `UIDeviceListener` is likely going to pass any technical tests Apple runs on your App, the App Review team consists of human beings who are likely to detect that your app presents information that Apple doesn't deem "end-user appropriate"... The most likely outcome is your app getting rejected under section 2.19 of the App Review Guidelines:
>  2.19       Apps that provide incorrect diagnostic or other inaccurate device data will be rejected

Of course, the data presented is about as accurate as it could ever be, but clearly Apple has decided that for now they're not willing to present this data to end-users, and so expect to get this rejection. Still, `UIDeviceListener` can be useful for apps where the data obtained is not directly presented to the end-user.

###What kind of power data can I get?
Pretty much every datapoint regarding battery and power known to the system is exposed. This includes the following:
- Battery design capacity
- Battery current raw capacity (in mAh)
- Battery cycle count
- Current battery temperature
- Current battery voltage
- Current battery discharge rate (device power consumption), in mA

Additionally, when the device is plugged in there is rich information regarding the currently plugged in power source:
- The wattage and amperage of the currently plugged in adapter. This will even detect the new 29W USB-C adapter that's supported by the 12.9" iPad Pro.
- The actual battery charging rate (in mA), if the device is charging
- Confirmation that the device is actually charging. On some power hungry iOS devices you will often see devices consuming *some* battery power even though they are plugged in.

### Sample Dictionary
Here is a sample dictionary showing actual output from PowerData. Unfortunately the dictionaries have slight differences for different versions of iOS. Certain basic parameters are identical across all versions, but there are bits of data that are quite different across versions. Still, basics such as `AdapterDetails`, `AppleRawCurrentCapacity`, `AppleRawMaxCapacity`, and `CycleCount` are identical across all supported versions (so far tested iOS 7 through 9.3.1).

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
`UIDeviceListener` has been extensively tested and runs well on essentially **any** iOS device (iPod Touch, iPad, and iPhone). `UIDeviceListener` supports iOS 7 and later, with 9.3.1 being the most recent version that's been tested.

###How does it work?
`UIDeviceListener` essentially hijacks the power data from iOS. We use [UIDevice](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/), which is a public API for getting system information. Internally, `UIDevice` utilizes IOKit (and the specific power dictionary we're after) in order to get information for two specific properties: [batteryLevel](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryLevel) and [batteryState](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryState).

`UIDeviceListener` relies on a CoreFoundation feature called `CFAllocator`, whereby apps are allowed to replace the default allocator for a given thread. We replace the default allocator with our own. That allows us to keep track of allocations being made on this one thread, at a very specific point in time (see below). This allows us to capture CF allocations made by anyone (including system components), and then examine those allocations, looking for our specific object.

After it replaces the default allocator, `UIDeviceListener` tells `UIDevice` to listen for updates to the `batteryLevel` and `batteryState` properties (it does so by setting the [batteryMonitoringEnabled](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/batteryMonitoringEnabled) property to `YES`). 

As updates come in on those two properties, the default CF allocator traps all CF objects created by `UIDevice`. Then, we configure `UIDevice` to notify us whenever new values have been set for `batteryLevel` and `batteryState` (we do that by installing a Key-Value Observer (KVO) on those two properties). In the KVO, we scan our default allocator's data structure, looking for our particular `CFDictionary`. Because `UIDevice` is still holding a reference to our desired CFDictionary while it sets the value of the properties, we are able to hijack that dictionary and get to the data.
###How reliable is that approach?
This is obviously a hack. The approach works perfectly on iOS 7 through iOS 9.3.1, but that does not guarantee that future iOS updates won't break it. It relies on a number of implementation details in `UIDevice` that are definitely subject to change by Apple without warning. In that sense using this library is equivalent to using a private API, so consider yourself warned... 
