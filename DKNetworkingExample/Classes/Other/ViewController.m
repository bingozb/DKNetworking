//
//  ViewController.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "ViewController.h"
#import "DKNetworking.h"

static NSString * const urlStr = @"https://www.shhyxypsx.com/app/v1/material/findMaterial";
static NSString * const downloadUrlStr = @"https://cdn.bingo.ren/protect/scp.png";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *networkData;
@property (weak, nonatomic) IBOutlet UITextView *cacheData;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatus;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
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
    DKLog(@"cache = %.2fKB",[DKNetworkCache getAllHttpCacheSize] / 1024.f);
    // 清理缓存 [DKNetworkCache removeAllHttpCache];
    
    // 实时监测网络状态
    [self monitorNetworkStatus];
    
    [self getCurrentNetworkStatus];
    
}

#pragma mark - POST

- (void)getData:(BOOL)isOn url:(NSString *)url
{
    if (isOn) { // 自动缓存
        self.cacheStatus.text = @"缓存打开";
        self.cacheSwitch.on = YES;
        [DKNetworking POST:url parameters:nil cacheBlock:^(id responseCache) {
            // 先加载缓存数据
            self.cacheData.text = [self jsonToString:responseCache];
        } callback:^(id responseObject, NSError *error) {
            if (!error) {
                // 再请求网络数据
                self.networkData.text = [self jsonToString:responseObject];
            }
        }];
        
    } else { // 无缓存
        self.cacheStatus.text = @"缓存关闭";
        self.cacheSwitch.on = NO;
        self.cacheData.text = @"";
        
        [DKNetworking POST:url parameters:nil callback:^(id responseObject, NSError *error) {
            if (!error) {
                self.networkData.text = [self jsonToString:responseObject];
            }
        }];
    }
}

#pragma mark - 实时监测网络状态

- (void)monitorNetworkStatus
{
    // 网络状态改变一次, networkStatusWithBlock就会响应一次
    [DKNetworking networkStatusWithBlock:^(DKNetworkStatus status) {
        
        switch (status) {
                // 未知网络
            case DKNetworkStatusUnknown:
                // 无网络
            case DKNetworkStatusNotReachable:
                self.networkData.text = @"没有网络";
                [self getData:YES url:urlStr];
                DKLog(@"无网络,加载缓存数据");
                break;
                // 手机网络
            case DKNetworkStatusReachableViaWWAN:
                // 无线网络
            case DKNetworkStatusReachableViaWiFi:
                [self getData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:urlStr];
                DKLog(@"有网络,请求网络数据");
                break;
        }
        
    }];
    
}

#pragma mark - 获取当前最新网络状态

- (void)getCurrentNetworkStatus
{
    if ([DKNetworking isNetwork]) {
        DKLog(@"有网络");
        if ([DKNetworking isWWANNetwork]) {
            DKLog(@"手机网络");
        } else if ([DKNetworking isWiFiNetwork]) {
            DKLog(@"WiFi网络");
        }
    } else {
        DKLog(@"无网络");
    }
}

#pragma mark - 下载

- (IBAction)download:(UIButton *)sender
{
    static NSURLSessionTask *task = nil;
    
    if (!self.isDownload) { // 开始下载
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];
        
        task = [DKNetworking downloadWithURL:downloadUrlStr fileDir:@"Download" progressBlock:^(NSProgress *progress) {
            CGFloat stauts = 100.f * progress.completedUnitCount/progress.totalUnitCount;
            self.progress.progress = stauts/100.f;
            DKLog(@"下载进度 :%.2f%%,,%@",stauts,[NSThread currentThread]);
            
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
        self.progress.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }
}

#pragma mark - 缓存开关

- (IBAction)isCache:(UISwitch *)sender
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];
    
    [self getData:sender.isOn url:urlStr];
}

/**
 *  json转字符串
 */
- (NSString *)jsonToString:(NSDictionary *)dic
{
    if(!dic){
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
