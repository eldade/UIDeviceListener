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

#define __kCFAllocatorGCObjectMemory 0x400      /* GC:  memory needs to be finalized. */

@interface UIDeviceListener : NSObject
{
    NSThread *listenerThread;
    
    Class dictionaryClass;
    
    void (^ dictReadyBlock)(CFDictionaryRef powerDict);
}

+ (instancetype) sharedUIDeviceListener;
- (void) startListenerWithNotificationBlock: (void (^)(CFDictionaryRef))dictReadyBlockParam;

@end
