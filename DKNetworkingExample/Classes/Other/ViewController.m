//
//  ViewController.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "ViewController.h"
#import "DKNetworking.h"

static NSString * const urlStr = @"https://m.sfddj.com/app/v1/material/findMaterial";
static NSString * const downloadUrlStr = @"https://cdn.bingo.ren/protect/scp.png";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *networkTextView;
@property (weak, nonatomic) IBOutlet UITextView *cacheTextView;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

/** 是否开启缓存 */
@property (nonatomic, assign, getter=isCache) BOOL cache;
/** 是否开始下载 */
@property (nonatomic, assign, getter=isDownload) BOOL download;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 开启日志打印
    [DKNetworking openLog];
    
    // 获取网络缓存大小
    DKLog(@"cacheSize = %@",[DKNetworkCache cacheSize]);
    
    // 清理缓存
//    [DKNetworkCache clearCache];
    
    // 实时监测网络状态
    [self monitorNetworkStatus];
    
    // 获取当前网络状态
//    [self getCurrentNetworkStatus];
    
}

#pragma mark - POST

- (void)postWithCache:(BOOL)isOn url:(NSString *)url
{
    if (isOn) { // 自动缓存
        self.cacheStatusLabel.text = @"缓存打开";
        self.cacheSwitch.on = YES;
        [DKNetworking POST:url parameters:nil cacheBlock:^(id responseCache) {
            // 加载缓存数据
            self.cacheTextView.text = [responseCache dk_jsonString];
        } callback:^(id responseObject, NSError *error) {
            if (!error) {
                // 请求网络数据
                self.networkTextView.text = [responseObject dk_jsonString];
            }
        }];
        
    } else { // 无缓存
        self.cacheStatusLabel.text = @"缓存关闭";
        self.cacheSwitch.on = NO;
        self.cacheTextView.text = @"";
        
        [DKNetworking POST:url parameters:nil callback:^(id responseObject, NSError *error) {
            if (!error) {
                self.networkTextView.text = [responseObject dk_jsonString];
            }
        }];
    }
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
                self.networkTextView.text = @"没有网络，只加载缓存数据";
                [self postWithCache:YES url:urlStr];
                break;
            case DKNetworkStatusReachableViaWWAN:
            case DKNetworkStatusReachableViaWiFi:
                self.networkTextView.text = @"有网络了，正在请求网络数据";
                [self postWithCache:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:urlStr];
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

/** 下载 */
- (IBAction)download
{
    static NSURLSessionTask *task = nil;
    
    if (!self.isDownload) { // 开始下载
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];
        
        task = [DKNetworking downloadWithURL:downloadUrlStr fileDir:@"Download" progressBlock:^(NSProgress *progress) {
            CGFloat stauts = 100.f * progress.completedUnitCount / progress.totalUnitCount;
            self.progressView.progress = stauts / 100.f;
            DKLog(@"下载进度:%.2f%%",stauts);
        } callback:^(NSString *filePath, NSError *error) {
            if (!error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成!" message:[NSString stringWithFormat:@"文件路径:%@",filePath] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alertView show];
                [self.downloadBtn setTitle:@"重新下载" forState:UIControlStateNormal];
                DKLog(@"filePath = %@",filePath);
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载失败" message:[NSString stringWithFormat:@"%@",error] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alertView show];
                DKLog(@"error = %@",error);
            }
        }];
    } else { // 暂停下载
        self.download = NO;
        [task suspend];
        self.progressView.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }
}

#pragma mark - 缓存开关

- (IBAction)isCache:(UISwitch *)sender
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];
    
    [self postWithCache:sender.isOn url:urlStr];
}

@end
