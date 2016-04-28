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

@interface DictDisplayViewController ()

@end

@implementation DictDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    void (^dictUpdatedBlock)(CFDictionaryRef newDict) = ^void(CFDictionaryRef newDict) {
        NSDictionary *dict = CFBridgingRelease(newDict);
        self.textView.text = [dict description];
    };
    
    UIDeviceListener *listener = [UIDeviceListener sharedUIDeviceListener];
    
    [listener startListenerWithNotificationBlock: dictUpdatedBlock];
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
