//
//  DKNetworkLogManager.m
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/3/18.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworkLogManager.h"
#import "DKNetworkRequest.h"
#import "DKNetworkResponse.h"
#import "MJExtension.h"

#define KLOG_RESPONSE_PATH [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"DKN_ServerError_Response.html"]

@interface DKNetworkLogManager ()
@property (nonatomic, assign) BOOL isOpenLog;
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

- (void)openLog
{
    _isOpenLog = YES;
}

- (void)closeLog
{
    _isOpenLog = NO;
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

- (void)logRequest:(DKNetworkRequest *)request
{
    if (!_isOpenLog) return;
    
    DKLog(@"############################## DKN Request ##############################");
    DKLog(@"请求地址: %@", request.urlStr);
    DKLog(@"请求方法: %@", request.method);
    DKLog(@"请求参数：%@", request.params.mj_JSONString);
    DKLog(@"请求头: %@", request.header);
    DKLog(@"有无缓存: %@", request.cacheType == DKNetworkCacheTypeNetworkOnly ? @"无" : @"有" );
    DKLog(@"序列化格式: %@", request.requestSerializer == DKRequestSerializerHTTP ? @"二进制" : @"JSON");
    DKLog(@"超时时间: %1.f秒", request.requestTimeoutInterval);
    DKLog(@"#########################################################################");
}

- (void)logResponse:(DKNetworkResponse *)response
{
    DKLog(@"############################# DKN Response #############################");
    DKLog(@"HTTP状态码: %ld", response.httpStatusCode);
    DKLog(@"data: %@", [response.rawData mj_JSONString]);
    DKLog(@"error: %@", response.error.localizedDescription);
    DKLog(@"########################################################################");
}


@end
