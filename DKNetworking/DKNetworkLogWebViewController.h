//
//  DKNetworkLogWebViewController.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/5/26.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKNetworkLogWebViewController : UIViewController

@property (nonatomic, copy) NSString *logFilePath;

@property (nonatomic, strong, readonly) UIWebView *webView;

@end
