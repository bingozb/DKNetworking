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
@property (weak, nonatomic) IBOutlet UITextField *downloadUrlTextField;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
/** 是否开始下载 */
@property (nonatomic, assign, getter=isDownloading) BOOL downloading;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 开启日志打印
    [DKNetworking openLog];
    
    // 设置缓存方式
    [DKNetworking setupCacheType:DKNetworkCacheTypeCacheNetwork];
    
    // 设置请求根路径
//    [DKNetworking setupBaseURL:@"https://m.sfddj.com/app/v1/"];
    
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
        MyHttpResponse *myResponse = [MyHttpResponse mj_objectWithKeyValues:response.rawData]; // 项目需要的response
        myResponse.rawData = response.rawData;
        myResponse.error = response.error;
        return [RACSignal return:RACTuplePack(tuple.first, myResponse)];
    }];
    
    // 把DELETE方法的参数放到body(移除了默认的DELETE)
    [DKNetworking setupSessionManager:^(DKNetworkSessionManager *sessionManager) {
        sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    }];
}

#pragma mark - POST

- (void)postWithCache:(BOOL)isOn url:(NSString *)url
{
    [DKNetworking setupCacheType:isOn ? DKNetworkCacheTypeCacheNetwork : DKNetworkCacheTypeNetworkOnly];
    
    // 常规调用
//    [DKNetworking POST:url parameters:nil callback:^(DKNetworkRequest *request, DKNetworkResponse *response) {
//        self.networkTextView.text = !response.error ? response.error.description : [response.rawData dk_jsonString];
//    }];
    
    // 链式调用
//    DKNetworkManager.post(url).callback(^(DKNetworkRequest *request, DKNetworkResponse *response) {
//        self.networkTextView.text = !response.error ? response.error.description : [response.rawData dk_jsonString];
//    });
    
    // RAC 链式调用
    [DKNetworkManager.post(url).executeSignal subscribeNext:^(RACTuple *x) {
//        DKNetworkResponse *response = x.second;
        MyHttpResponse *myResponse = x.second;
        self.networkTextView.text = [myResponse.rawData dk_jsonString];
    } error:^(NSError *error) {
        self.networkTextView.text = error.description;
    }];
}

/**
 实时监测网络状态
 */
- (void)monitorNetworkStatus
{
    [DKNetworking networkStatusWithBlock:^(DKNetworkStatus status) {
        
        switch (status) {
            case DKNetworkStatusUnknown:
            case DKNetworkStatusNotReachable:
                self.networkTextView.text = @"网络异常，只加载缓存数据";
                [self postWithCache:YES url:self.apiTextField.text];
                break;
            case DKNetworkStatusReachableViaWWAN:
            case DKNetworkStatusReachableViaWiFi:
                self.networkTextView.text = @"网络正常，正在请求网络数据";
                [self postWithCache:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:self.apiTextField.text];
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
    [self postWithCache:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:self.apiTextField.text];
}

/** 下载 */
- (IBAction)download
{
    static NSURLSessionTask *task = nil;
    
    if (!self.isDownloading) { // 开始下载
        self.downloading = YES;
        [self.downloadBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        
        task = [DKNetworking downloadWithURL:self.downloadUrlTextField.text fileDir:@"Download" progressBlock:^(NSProgress *progress) {
            CGFloat stauts = 100.f * progress.completedUnitCount / progress.totalUnitCount;
            self.progressView.progress = stauts / 100.f;
            DKLog(@"下载进度:%.2f%%",stauts);
        } callback:^(NSString *filePath, NSError *error) {
            if (!error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成!" message:[NSString stringWithFormat:@"文件路径:%@",filePath] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alertView show];
                [self.downloadBtn setTitle:@"Re Download" forState:UIControlStateNormal];
                DKLog(@"filePath = %@",filePath);
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载失败" message:[NSString stringWithFormat:@"%@",error] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alertView show];
                DKLog(@"error = %@",error);
            }
        }];
    } else { // 停止下载
        self.downloading = NO;
        [task suspend];
        self.progressView.progress = 0;
        [self.downloadBtn setTitle:@"Download" forState:UIControlStateNormal];
    }
}

#pragma mark - 缓存开关

- (IBAction)isCache:(UISwitch *)sender
{
    self.cacheStatusLabel.text = sender.isOn ? @"Cache Open" : @"Cache Close";
    self.cacheSwitch.on = sender.isOn;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];
}

@end
