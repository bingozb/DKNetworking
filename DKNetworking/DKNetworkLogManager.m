//
//  DKNetworkLogManager.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkLogManager.h"
#import "DKNetworkLogWebViewController.h"
#import "DKNetworkResponse.h"
#import "MJExtension.h"

#define KLOG_RESPONSE_PATH [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"DKN_ServerError_Response.html"]

@interface DKNetworkLogManager ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation DKNetworkLogManager

static DKNetworkLogManager *_logManager;

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logManager = [super allocWithZone:zone];
    });
    return _logManager;
}

+ (instancetype)defaultManager
{
    if (_logManager == nil) {
        _logManager = [[self alloc] init];
    }
    return _logManager;
}

- (NSString *)logDateTime
{
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

- (void)setupDateFormat:(NSString *)formatStr
{
    [self.dateFormatter setDateFormat:formatStr];
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss.SSS"];
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (void)showErrorLogWithResponse:(DKNetworkResponse *)response
{
    [self saveLogToHTMLWithResponse:response completion:^{
        [self alertToShowLogWebViewController];
    }];
}

- (void)saveLogToHTMLWithResponse:(DKNetworkResponse *)response completion:(void(^)())completion
{
    if (response.error) {
        for (id value in response.error.userInfo.allValues) {
            if ([value isKindOfClass:[NSError class]]) {
                NSError *error = value;
                [error.userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSData class]]) {
                        NSData *data = (NSData *)obj;
                        [data writeToFile:KLOG_RESPONSE_PATH atomically:YES];
                        *stop = YES;
                        if (completion) {
                            completion();
                        }
                    }
                }];
            }
        };
    }
}

- (void)alertToShowLogWebViewController
{
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        DKNetworkLogWebViewController *vc = [[DKNetworkLogWebViewController alloc] init];
        vc.logFilePath = KLOG_RESPONSE_PATH;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:vc animated:YES completion:nil];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"DKNetworking" message:@"\n服务器异常响应，是否查看异常信息" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:confirmAction];
    [alertController addAction:cancelAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
