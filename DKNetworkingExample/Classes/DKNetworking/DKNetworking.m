//
//  DKNetworking.m
//  DKNetworkingExample
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import "DKNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation DKNetworking

static BOOL _isOpenLog;
static NSMutableArray<NSURLSessionTask *> *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

#pragma mark - 监听网络

/**
 监听网络状态

 @param networkStatusBlock 网络状态回调
 */
+ (void)networkStatusWithBlock:(DKNetworkStatusBlock)networkStatusBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusUnknown);
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusNotReachable);
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusReachableViaWWAN);
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (networkStatusBlock) networkStatusBlock(DKNetworkStatusReachableViaWiFi);
                    break;
            }
        }];
    });
}

+ (BOOL)isNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork
{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

+ (void)openLog
{
    _isOpenLog = YES;
}

+ (void)closeLog
{
    _isOpenLog = NO;
}

+ (void)cancelAllRequest
{
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL
{
    if (!URL) return;
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - GET请求 无缓存

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKHttpRequestBlock)callback
{
    return [self GET:URL parameters:parameters cacheBlock:nil callback:callback];
}

#pragma mark - POST请求 无缓存

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKHttpRequestBlock)callback
{
    return [self POST:URL parameters:parameters cacheBlock:nil callback:callback];
}

#pragma mark - GET请求 自动缓存

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters cacheBlock:(DKHttpRequestCacheBlock)cacheBlock callback:(DKHttpRequestBlock)callback
{
    // 读取缓存
    if (cacheBlock) cacheBlock([DKNetworkCache httpCacheForURL:URL parameters:parameters]);
    
    NSURLSessionTask *sessionTask = [_sessionManager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DKLog(@"%@",_isOpenLog ? [NSString stringWithFormat:@"responseObject = %@",[self jsonToString:responseObject]] : nil);
        [[self allSessionTask] removeObject:task];
        
        if (callback) callback(responseObject, nil);
        // 对数据进行异步缓存
        if (cacheBlock) [DKNetworkCache setHttpCache:responseObject URL:URL parameters:parameters];

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) DKLog(@"%@",[NSString stringWithFormat:@"error = %@",error]);
        
        [[self allSessionTask] removeObject:task];
        
        if (callback) callback(nil, error);
    }];
    
    // 添加sessionTask到数组
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - POST请求 自动缓存

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters cacheBlock:(DKHttpRequestCacheBlock)cacheBlock callback:(DKHttpRequestBlock)callback
{
    // 读取缓存
    if (cacheBlock) cacheBlock([DKNetworkCache httpCacheForURL:URL parameters:parameters]);
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DKLog(@"%@",_isOpenLog ? [NSString stringWithFormat:@"responseObject = %@",[self jsonToString:responseObject]] : nil);
        [[self allSessionTask] removeObject:task];
        
        if (callback) callback(responseObject, nil);
        // 对数据进行异步缓存
        if (cacheBlock) [DKNetworkCache setHttpCache:responseObject URL:URL parameters:parameters];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) DKLog(@"%@",[NSString stringWithFormat:@"error = %@",error]);
        
        [[self allSessionTask] removeObject:task];
        
        if (callback) callback(nil, error);
    }];
    
    // 添加sessionTask到数组
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - 上传文件

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progressBlock:(DKHttpProgressBlock)progressBlock callback:(DKHttpRequestBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        if (error && callback) {
            callback(nil, error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        // 上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (_isOpenLog)
            DKLog(@"%@",[NSString stringWithFormat:@"responseObject = %@",[self jsonToString:responseObject]]);
        // 移除任务
        [[self allSessionTask] removeObject:task];
        // 成功回调
        if (callback)
            callback(responseObject, nil);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {
            DKLog(@"%@",[NSString stringWithFormat:@"error = %@",error]);
        }
        [[self allSessionTask] removeObject:task];
        if (callback)
            callback(nil, error);
    }];
    
    // 添加sessionTask到数组
    [[self allSessionTask] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark - 上传多张图片

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(NSDictionary *)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progressBlock:(DKHttpProgressBlock)progressBlock callback:(DKHttpRequestBlock)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"] : imageFileName
                                    mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        // 上传进度回调
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(uploadProgress);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog)
            DKLog(@"%@",[NSString stringWithFormat:@"responseObject = %@",[self jsonToString:responseObject]]);
        
        [[self allSessionTask] removeObject:task];
        
        if (callback)
            callback(responseObject, nil);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {
            DKLog(@"%@",[NSString stringWithFormat:@"error = %@",error]);
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (callback)
            callback(nil, error);
    }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - 下载文件

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progressBlock:(DKHttpProgressBlock)progressBlock callback:(void (^)(NSString *, NSError *))callback
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock)
                progressBlock(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // 拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        // 打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        // 拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        // 返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self allSessionTask] removeObject:downloadTask];
        
        if (error && callback) {
            callback(nil, error);
            return ;
        }
        
        if (callback) {
            /** NSURL->NSString*/
            callback(filePath.absoluteString, nil);
        }
    }];
    
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    [[self allSessionTask] addObject:downloadTask];
    
    return downloadTask;
}

/**
 json转字符串
 */
+ (NSString *)jsonToString:(id)data
{
    if(!data) return nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 存储着所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask
{
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - 初始化 AFHTTPSessionManager 相关属性

/**
 开始监测网络状态
 */
+ (void)load
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 */
+ (void)initialize
{
    _sessionManager = [AFHTTPSessionManager manager];
    // 设置请求的超时时间
    _sessionManager.requestSerializer.timeoutInterval = 10.f;
    // 设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 重置 AFHTTPSessionManager 相关属性

+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer
{
    _sessionManager.requestSerializer = requestSerializer==DKRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer
{
    _sessionManager.responseSerializer = responseSerializer==DKResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time
{
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

@end
