//
//  DKNetworking.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKNetworkCache.h"
#import "NSDictionary+DKNetworking.h"

#ifndef DKLog
#ifdef DEBUG
#define DKLog(...) printf("[%s] %s 第%d行: %s\n", __TIME__, __func__, __LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define DKLog(...)
#endif
#endif

typedef NS_ENUM(NSUInteger, DKNetworkStatus) {
    /** 未知网络 */
    DKNetworkStatusUnknown,
    /** 无网络 */
    DKNetworkStatusNotReachable,
    /** 手机网络 */
    DKNetworkStatusReachableViaWWAN,
    /** WIFI网络 */
    DKNetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, DKRequestSerializer) {
    /** 请求数据为JSON格式 */
    DKRequestSerializerJSON,
    /** 请求数据为二进制格式 */
    DKRequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, DKResponseSerializer) {
    /** 响应数据为JSON格式*/
    DKResponseSerializerJSON,
    /** 响应数据为二进制格式*/
    DKResponseSerializerHTTP,
};

#pragma mark - Block

/** 请求回调Block */
typedef void(^DKHttpRequestBlock)(NSDictionary *responseObject, NSError *error);

/** 缓存的Block */
typedef void(^DKHttpRequestCacheBlock)(NSDictionary *responseCache);

/** 
 * 上传或者下载的进度回调
 * Progress.completedUnitCount : 当前大小
 * Progress.totalUnitCount : 总大小
 */
typedef void(^DKHttpProgressBlock)(NSProgress *progress);

/** 网络状态的Block */
typedef void(^DKNetworkStatusBlock)(DKNetworkStatus status);

@interface DKNetworking : NSObject

#pragma mark - Network Status

/**
 有网:YES, 无网:NO
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

/**
 GET请求，不缓存

 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                 callback:(DKHttpRequestBlock)callback;

/**
 GET请求，自动缓存

 @param URL 请求地址
 @param parameters 请求参数
 @param cacheBlock 缓存回调
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
               cacheBlock:(DKHttpRequestCacheBlock)cacheBlock
                 callback:(DKHttpRequestBlock)callback;

/**
 POST请求，不缓存
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)URL
               parameters:(NSDictionary *)parameters
                 callback:(DKHttpRequestBlock)callback;

/**
 POST请求，自动缓存
 
 @param URL 请求地址
 @param parameters 请求参数
 @param cacheBlock 缓存回调
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)URL
               parameters:(NSDictionary *)parameters
               cacheBlock:(DKHttpRequestCacheBlock)cacheBlock
                 callback:(DKHttpRequestBlock)callback;

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
                          progressBlock:(DKHttpProgressBlock)progressBlock
                               callback:(DKHttpRequestBlock)callback;

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
                            progressBlock:(DKHttpProgressBlock)progressBlock
                                 callback:(DKHttpRequestBlock)callback;

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
                        progressBlock:(DKHttpProgressBlock)progressBlock
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

#pragma mark - Reset SessionManager

/**
 设置网络请求参数的格式 : 默认为二进制格式

 @param requestSerializer DKRequestSerializerJSON:JSON格式, DKRequestSerializerHTTP:二进制格式
 */
+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer;

/**
 设置服务器响应数据格式 : 默认为JSON格式

 @param responseSerializer DKResponseSerializerJSON : JSON格式, DKResponseSerializerHTTP : 二进制格式
 */
+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer;

/**
 设置请求超时时间 : 默认10秒

 @param time 请求超时时长(秒)
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/**
 设置请求头
 */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
