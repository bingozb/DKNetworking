//
//  DKNetworking.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MJExtension.h"
#import "DKNetworkEnum.h"
#import "DKNetworkCache.h"
#import "DKNetworkRequest.h"
#import "DKNetworkResponse.h"
#import "DKNetworkLogManager.h"
#import "NSDictionary+DKNetworking.h"

#if __has_include(<ReactiveCocoa/ReactiveCocoa.h>)
#import <ReactiveCocoa/ReactiveCocoa.h>
#else
#if __has_include("ReactiveCocoa.h")
#import "ReactiveCocoa.h"
#endif
#endif

#define DKNetworkManager [DKNetworking networkManager]

#ifdef RAC
typedef RACStream *(^DKNetworkFlattenMapBlock)(RACTuple *tuple);
#endif

typedef NSTimeInterval DKRequestTimeoutInterval;

/** 网络状态的Block */
typedef void(^DKNetworkStatusBlock)(DKNetworkStatus status);

/** 请求回调Block */
typedef void(^DKNetworkBlock)(DKNetworkRequest *request, DKNetworkResponse *response);

/** 
 上传或者下载的进度回调Block
    Progress.completedUnitCount : 当前大小
    Progress.totalUnitCount     : 总大小
 */
typedef void(^DKNetworkProgressBlock)(NSProgress *progress);

/**
 基于 AFN + YYCache 的网络层封装类
 */
@interface DKNetworking : NSObject

/** 缓存方式 */
@property (nonatomic, assign, readonly) DKNetworkCacheType networkCacheType;
/** 请求序列化格式 */
@property (nonatomic, assign, readonly) DKRequestSerializer networkRequestSerializer;
/** 响应反序列化格式 */
@property (nonatomic, assign, readonly) DKResponseSerializer networkResponseSerializer;
/** 请求超时时间 */
@property (nonatomic, assign, readonly) DKRequestTimeoutInterval networkRequestTimeoutInterval;
/** 请求头 */
@property (nonatomic, strong, readonly) NSDictionary *networkHeader;

/**
 单例对象
 */
+ (instancetype)networkManager;

/**
 设置接口根路径, 设置后所有的网络访问都使用相对路径
    baseURL的路径一定要有"/"结尾
 @param baseURL 根路径
 */
+ (void)setupBaseURL:(NSString *)baseURL;

/**
 设置缓存类型
 DKNetworkCacheTypeNetworkOnly : 只加载网络数据
 DKNetworkCacheTypeCacheNetwork : 先加载缓存,然后加载网络
 @param cacheType 缓存类型
 */
+ (void)setupCacheType:(DKNetworkCacheType)cacheType;

#pragma mark - Network Status

/**
 有网络:YES, 无网络:NO
 */
+ (BOOL)isNetworking;

/**
 手机网络:YES, 非手机网络:NO
 */
+ (BOOL)isWWANNetwork;

/**
 WiFi网络:YES, 非WiFi网络:NO
 */
+ (BOOL)isWiFiNetwork;

/**
 实时获取网络状态，通过Block回调实时获取
 */
+ (void)networkStatusWithBlock:(DKNetworkStatusBlock)networkStatusBlock;

#pragma mark - Log

/**
 开启日志打印 (Debug)
 */
+ (void)openLog;

/**
 关闭日志打印
 */
+ (void)closeLog;

#pragma mark - Request Method

#pragma mark 链式调用

/** 链式调用 */
- (DKNetworking *(^)(NSString *url))get;
- (DKNetworking *(^)(NSString *url))post;
- (DKNetworking *(^)(NSString *url))put;
- (DKNetworking *(^)(NSString *url))delete;
- (DKNetworking *(^)(NSString *url))patch;
- (DKNetworking *(^)(NSDictionary *params))params;
- (DKNetworking *(^)(NSDictionary *header))header;
- (DKNetworking *(^)(DKNetworkCacheType cacheType))cacheType;
- (DKNetworking *(^)(DKRequestSerializer requestSerializer))requestSerializer;
- (DKNetworking *(^)(DKResponseSerializer responseSerializer))responseSerializer;
- (DKNetworking *(^)(DKRequestTimeoutInterval requestTimeoutInterval))requestTimeoutInterval;
- (void(^)(DKNetworkBlock networkBlock))callback;

#ifdef RAC
/** RAC链式发送请求 */
- (RACSignal *)executeSignal;
#endif

#pragma mark 常规调用

/**
 发起一个请求

 @param request 请求对象
 @param callback 请求响应回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)request:(DKNetworkRequest *)request callback:(DKNetworkBlock)callback;

/**
 GET请求

 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;

/**
 POST请求
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;

/**
 PUT请求
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)PUT:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;

/**
 DELETE请求
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)DELETE:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;

/**
 PATCH请求
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)PATCH:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;

/**
 上传文件

 @param URL 请求地址
 @param parameters 请求参数
 @param name 文件对应服务器上的字段
 @param filePath 文件本地的沙盒路径
 @param progressBlock 上传进度回调
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                             parameters:(NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)filePath
                          progressBlock:(DKNetworkProgressBlock)progressBlock
                               callback:(void(^)(DKNetworkResponse *response))callback;

/**
 上传图片

 @param URL 请求地址
 @param parameters 请求参数
 @param name 图片对应服务器上的字段
 @param images 图片数组
 @param fileNames 图片文件名数组，传入nil时数组内的文件名默认为当前日期时间戳+索引
 @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
 @param imageType 图片文件的类型，例:png、jpg(默认类型)....
 @param progressBlock 上传进度回调
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(NSDictionary *)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                            progressBlock:(DKNetworkProgressBlock)progressBlock
                                 callback:(void(^)(DKNetworkResponse *response))callback;

/**
 下载文件

 @param URL 请求地址
 @param fileDir 文件存储目录(默认存储目录为Download)
 @param progressBlock 文件下载的进度回调
 @param callback 请求回调，filePath为文件保存路径
 @return 返回 NSURLSessionDownloadTask 实例，可用于暂停继续，暂停调用 suspend 方法，开始下载调用 resume 方法
 */
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                        progressBlock:(DKNetworkProgressBlock)progressBlock
                             callback:(void(^)(NSString *filePath, NSError *error))callback;

#pragma mark - Cancel Request

/**
 取消所有HTTP请求
 */
+ (void)cancelAllRequest;

/**
 取消指定URL的HTTP请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL;

#pragma mark - Config Result
#ifdef RAC
/**
 设置响应结果回调，可以设置信号返回的value为自己想要的值，比如用MJExtension框架，将DKNetworkResponse对象的rawData字典转为自己需要用的实体类再返回
 
 @param flattenMapBlock 结果映射的设置回调block，其中RACTuple的first为DKNetworkRequest对象，second为DKNetworkResponse对象
 */
+ (void)setupResponseSignalWithFlattenMapBlock:(DKNetworkFlattenMapBlock)flattenMapBlock;
#endif
#pragma mark - Reset SessionManager

/**
 设置网络请求参数的格式 : 默认为二进制格式

 @param requestSerializer DKRequestSerializerJSON:JSON格式, DKRequestSerializerHTTP:二进制格式
 */
+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer;

/**
 设置服务器响应数据格式 : 默认为JSON格式

 @param responseSerializer DKResponseSerializerJSON:JSON格式, DKResponseSerializerHTTP:二进制格式
 */
+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer;

/**
 设置请求超时时间 : 默认10秒

 @param time 请求超时时长(秒)
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/**
 设置一对请求头参数

 @param value 请求头参数值
 @param field 请求头参数名
 */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 设置多对请求头参数

 @param networkHeader 请求头参数字典
 */
+ (void)setNetworkHeader:(NSDictionary *)networkHeader;

@end
