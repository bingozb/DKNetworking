//
//  ViewController.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "ViewController.h"
#import "DKNetworking.h"
#import "MJExtension.h"
#import "MyHttpResponse.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *networkTextView;
@property (weak, nonatomic) IBOutlet UITextField *apiTextField;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 开启日志打印
    [DKNetworking openLog];
    
    // 清除缓存
//    [DKNetworkCache clearCache];
    
    // 获取网络缓存大小
    DKLog(@"cacheSize = %@",[DKNetworkCache cacheSize]);
    
    // 实时监测网络状态
    [self monitorNetworkStatus];
    
    // 获取当前网络状态
//    [self getCurrentNetworkStatus];
    
    // 设置回调的信号的return值，根据不同项目进行配置
    [DKNetworking setupResponseSignalWithFlattenMapBlock:^RACStream *(RACTuple *tuple) {
        DKNetworkResponse *response = tuple.second; // 框架默认返回的response
        // MyHttpResponse
        MyHttpResponse *myResponse = [[MyHttpResponse alloc] init];
        myResponse.result = response.rawData;
        myResponse.message = @"some message in data";
        myResponse.errorCode = @"200";
        
        return [RACSignal return:RACTuplePack(tuple.first, myResponse)];
    }];
    
    DKNetworkManager.setupGlobalRequestSerializer(DKRequestSerializerHTTP);
}

#pragma mark - POST

- (void)postWithCache:(BOOL)isOn url:(NSString *)url
{
    [DKNetworkManager.get(url).cacheType(isOn ? DKNetworkCacheTypeCacheNetwork : DKNetworkCacheTypeNetworkOnly).executeSignal subscribeNext:^(RACTuple *x) {
//        DKNetworkResponse *response = x.second;
//        self.networkTextView.text = [self jsonTextWithData:response.rawData];
        MyHttpResponse *myResponse = x.second;
        self.networkTextView.text = [self jsonTextWithData:myResponse.result];
    } error:^(NSError *error) {
        self.networkTextView.text = error.description;
    }];
}

/**
 实时监测网络状态
 */
- (void)monitorNetworkStatus
{
    [DKNetworking setupNetworkStatusWithBlock:^(DKNetworkStatus status) {
        
        switch (status) {
            case DKNetworkStatusUnknown:
            case DKNetworkStatusNotReachable:
                self.networkTextView.text = @"网络异常...";
                break;
            case DKNetworkStatusReachableViaWWAN:
            case DKNetworkStatusReachableViaWiFi:
                self.networkTextView.text = @"网络正常，正在请求网络数据";
                [self postWithCache:self.cacheSwitch.isOn url:self.apiTextField.text];
                break;
        }
    }];
}

///**
// 获取当前网络状态
// */
//- (void)getCurrentNetworkStatus
//{
//    if ([DKNetworking isNetworking]) {
//        DKLog(@"有网络");
//        if ([DKNetworking isWWANNetwork]) {
//            DKLog(@"手机网络");
//        } else if ([DKNetworking isWiFiNetwork]) {
//            DKLog(@"WiFi网络");
//        }
//    } else {
//        DKLog(@"无网络");
//    }
//}

- (IBAction)post
{
    self.networkTextView.text = @"Loading...";
    [self postWithCache:self.cacheSwitch.isOn url:self.apiTextField.text];
}

- (IBAction)isCache:(UISwitch *)sender
{
    self.cacheStatusLabel.text = sender.isOn ? @"Cache Open" : @"Cache Close";
}

#pragma mark - private

- (NSString *)jsonTextWithData:(NSData *)data
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

@end
