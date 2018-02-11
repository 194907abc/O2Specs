//
//  ViewController.h
//  runtime
//
//  Created by 吴文鹏 on 2017/11/17.
//  Copyright © 2017年 DocIn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol myDelegate

@required
- (void) bixuzuode;

@optional

- (void) keyizuode;

@end


@interface ViewController : UIViewController

- (void) myFirstMethod;

@end

