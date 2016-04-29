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


#import "UIDeviceListener.h"
#include <UIKit/UIKit.h>
#include <set>
#include <objc/runtime.h>

@interface UIDeviceListener()
{
}

// The allocations std::set is what we use to track all CoreFoundation allocations made on this thread.
// Once UIDevice receives a notification from IOKit, it will call IOKit to get a copy of the most
// recent dictionary from the IORegistry. That object is going to get allocated using the default
// CoreFoundation allocator (which is our allocator), which will be trapped in our set.
//
// When UIDevice updates the public properties (batteryState and batteryLevel), we take that opportunity
// and use the KVO to grab that moment, traverse all allocations in the set, and find the one dictionary
// we're looking for. This works because at the moment that UIDevice updates the properties, it is still
// holding on to the IOKit dictionary.
//
// NOTE: Why use STL when there's NSSet, you ask? Because NSSet uses the default allocator to allocate
// all of its objects, which would cause infinite recursion into our default allocator. Therefore, we use
// STL std::set which is functionally equivalent but doesn't rely on any CF/NS objects.
//
// NOTE (2): Not worried about thread safety for our std::set as the set is only accessed by this allocator
// which is only used on the listener thread.
@property std::set<void *> *allocations;

@property CFAllocatorRef defaultAllocator;
@property CFAllocatorRef myAllocator;

@end


@implementation UIDeviceListener

#if DEBUG==1
NSThread *listenerThreadDbg;

void verifyListenerThread()
{
    if ([NSThread currentThread] != listenerThreadDbg)
    {
        NSLog(@"ERROR: myAllocator code was executed on the wrong thread!");
        __builtin_trap();
    }
}

#define VERIFY_LISTENER_THREAD() verifyListenerThread()
#else
#define VERIFY_LISTENER_THREAD()
#endif

void * myAlloc (CFIndex allocSize, CFOptionFlags hint, void *info)
{
    VERIFY_LISTENER_THREAD();
    
    void *newAllocation = CFAllocatorAllocate([UIDeviceListener sharedUIDeviceListener].defaultAllocator, allocSize, hint);
    
    if (newAllocation == NULL)
        return newAllocation;
    
    if (hint & __kCFAllocatorGCObjectMemory)
    {
        [UIDeviceListener sharedUIDeviceListener].allocations->insert(newAllocation);
    }
    return newAllocation;
}

void *	myRealloc(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
    VERIFY_LISTENER_THREAD();

    [UIDeviceListener sharedUIDeviceListener].allocations->erase(ptr);
    void *newAllocation = CFAllocatorReallocate([UIDeviceListener sharedUIDeviceListener].defaultAllocator, ptr, newsize, hint);
    
    if (newAllocation == NULL)
        return newAllocation;
    
    if (hint & __kCFAllocatorGCObjectMemory)
        [UIDeviceListener sharedUIDeviceListener].allocations->insert(newAllocation);
    
    return newAllocation;
}

void myFree(void *ptr, void *info)
{
    VERIFY_LISTENER_THREAD();

    CFAllocatorDeallocate([UIDeviceListener sharedUIDeviceListener].defaultAllocator, ptr);

    [UIDeviceListener sharedUIDeviceListener].allocations->erase(ptr);
}


// This guy needs to be a singleton because UIDevice will not accept more than one listener
// thread (batteryMonitoringEnabled = YES crashes if it's called on more than one thread)
+ (instancetype) sharedUIDeviceListener
{
    static UIDeviceListener *listener;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        listener = [[UIDeviceListener alloc] init];
    });
    
    return listener;
}

- (instancetype) init
{
    self = [super init];
    
    CFDictionaryRef dict = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
    dictionaryClass = object_getClass((__bridge id) dict);
    CFRelease(dict);
    
    _allocations = new std::set<void *>;
    _defaultAllocator = CFAllocatorGetDefault();
    
    listenerThread = [[NSThread alloc] initWithTarget: self selector: @selector(listenerThreadMain) object: nil];
    listenerThread.name = @"UIDeviceListener";
    
#if DEBUG==1
    listenerThreadDbg = listenerThread;
#endif
    
    // Start the listener thread. Actual listening to UIDevice won't start until we
    // invoke startListenerWithNotificationBlock:
    [listenerThread start];
    
    return self;
}

- (void) startListenerWithNotificationBlock: (void (^)(NSDictionary *powerDataDictionary))dictReadyBlockParam
{
    [self performSelector: @selector(startListenerWorker:) onThread:listenerThread withObject:dictReadyBlockParam waitUntilDone:NO];
}

- (void) stopListener
{
    [self performSelector: @selector(stopListenerWorker) onThread:listenerThread withObject:nil waitUntilDone:NO];
}

- (void) startListenerWorker: (id) block
{
    VERIFY_LISTENER_THREAD();
    
    if ([UIDevice currentDevice].isBatteryMonitoringEnabled == NO)
    {
        [[UIDevice currentDevice] addObserver: self forKeyPath: @"batteryState" options:NSKeyValueObservingOptionNew context: nil];
        [[UIDevice currentDevice] addObserver: self forKeyPath: @"batteryLevel" options:NSKeyValueObservingOptionNew context: nil];
        
        dictReadyBlock = block;
        
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;   
    }
}

- (void) stopListenerWorker
{
    VERIFY_LISTENER_THREAD();
    if ([UIDevice currentDevice].isBatteryMonitoringEnabled == YES)
    {
        [UIDevice currentDevice].batteryMonitoringEnabled = NO;
        
        [[UIDevice currentDevice] removeObserver: self forKeyPath: @"batteryState"];
        [[UIDevice currentDevice] removeObserver: self forKeyPath: @"batteryLevel"];
        
        dictReadyBlock = nil;
    }
}

- (void) dummyTimer: (NSTimer *) timer
{
    NSLog(@"Should never be called");
}

- (void) listenerThreadMain
{
    // The following NSTimer will never be called and is installed simply to keep this thread's
    // run loop running in perpetuity.
    [NSTimer scheduledTimerWithTimeInterval: [NSDate distantFuture].timeIntervalSinceNow target: self selector: @selector(dummyTimer:) userInfo:nil repeats:YES];
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(_defaultAllocator, (kCFRunLoopAfterWaiting), YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        // A source is about to fire. On this thread there are no sources other than the UIDevice IOKit
        // notification port... All we do here is just clear the allocations set. That way when our
        // KVO callback is called, we'll have fewer allocations to inspect:
        _allocations->clear();
    });
    
    CFRunLoopRef mainLoop = CFRunLoopGetCurrent();
    CFRunLoopAddObserver(mainLoop, observer, kCFRunLoopCommonModes);
    
    CFAllocatorContext context;
    
    CFAllocatorGetContext(_defaultAllocator, &context);
    context.allocate = myAlloc;
    context.reallocate = myRealloc;
    context.deallocate = myFree;
    
    _myAllocator = CFAllocatorCreate(NULL, &context);
    CFAllocatorSetDefault(_myAllocator);
    
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL) isValidCFDictionary: (void *) object
{
    Class testPointerClass = object_getClass((__bridge id) object);
    
    if (dictionaryClass == testPointerClass &&
        CFGetTypeID(object) == CFDictionaryGetTypeID())
        return YES;
    else
        return NO;
}

- (BOOL) isChargerDictionary: (CFDictionaryRef) candidateDict
{
    CFStringRef ioClass = (CFStringRef) CFDictionaryGetValue(candidateDict, CFSTR("IOClass"));
    if (ioClass == nil)
        return NO;
    
    if (CFStringCompare(ioClass, CFSTR("AppleARMPMUCharger"), 0) == kCFCompareEqualTo)
    {
        // This is what we get for iOS 8/9.
        return YES;
    }
    else
    {
        // The following is for iOS 7 only:
        
        // The actual IOClass string in iOS 7 depends on the platform name (something like
        // AppleD1815PMUPowerSource, etc.), so we just search for the 'PMUPowerSource' substring:
        CFRange result = CFStringFind(ioClass, CFSTR("PMUPowerSource"), kCFCompareCaseInsensitive);
        
        if (result.location != kCFNotFound)
            return YES;
    }
    
    return NO;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([change objectForKey: NSKeyValueChangeNewKey] != nil)
    {
        std::set<void *>::iterator it;
        for (it=_allocations->begin(); it!=_allocations->end(); ++it)
        {
            CFAllocatorRef *ptr = (CFAllocatorRef *) (NSUInteger)*it;
            void * ptrToObject = (void *) ((NSUInteger)*it + sizeof(CFAllocatorRef));
            
            if (*ptr == _myAllocator && // Just a sanity check to make sure the first field is a pointer to our allocator
                [self isValidCFDictionary: ptrToObject])   // Check for valid CFDictionary
            {
                CFDictionaryRef dict = (CFDictionaryRef) ptrToObject;
                
                if ([self isChargerDictionary: dict]) // Check if this is the charger dictionary
                {
                    // Found our dictionary. Let's clear the allocations array:
                    _allocations->clear();

                    // We make a deep copy of the dictionary using the default allocator so we don't
                    // get callbacks when this object and any of its descendents get freed from the
                    // wrong thread:
                    
                    CFDictionaryRef latestDictionary = (CFDictionaryRef) CFPropertyListCreateDeepCopy(_defaultAllocator, dict, kCFPropertyListImmutable);
                    
                    if (dictReadyBlock != nil && latestDictionary != nil)
                    {
                        // Notify that new data is available, but that has to happen on the main thread.
                        // Because of the CFAllocator replacement, we generally shouldn't
                        // do ANYTHING on this thread other than stealing this dictionary from UIDevice...
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            // Pass ownership of the CFDictionary to the main thread (using ARC):
                            NSDictionary *newPowerDataDictionary = CFBridgingRelease(latestDictionary);
                            dictReadyBlock(newPowerDataDictionary);
                        });
                    }
                    
                    return;
                }
            }
        }
    }
}


@end
