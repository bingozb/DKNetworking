//
//  DKNetworking.h
//  DKNetworking
//
//  Created by 庄槟豪 on 2017/2/25.
//  Copyright © 2017年 cn.dankal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DKNetworkCache.h"
#import "DKNetworkEnum.h"
#import "DKNetworkLogManager.h"
#import "NSDictionary+DKNetworking.h"
#import "DKNetworkResponse.h"

@class DKNetworkRequest;

#pragma mark - Block

/** 请求回调Block */
typedef void(^DKNetworkBlock)(DKNetworkResponse *response);

/** 
 * 上传或者下载的进度回调Block
 * Progress.completedUnitCount : 当前大小
 * Progress.totalUnitCount : 总大小
 */
typedef void(^DKNetworkProgressBlock)(NSProgress *progress);

/** 网络状态的Block */
typedef void(^DKNetworkStatusBlock)(DKNetworkStatus status);

/**
 基于 AFN + YYCache 的第一层封装类
 */
@interface DKNetworking : NSObject

/**
 单例对象
 */
+ (instancetype)networkManager;

/**
 设置缓存类型

 @param cacheType 缓存类型
 */
+ (void)setupCacheType:(DKNetworkCacheType)cacheType;

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

#pragma mark 链式调用

/** 链式调用 */
- (DKNetworking * (^)())get;
- (DKNetworking * (^)())post;
- (DKNetworking * (^)())put;
- (DKNetworking * (^)())delete;
- (DKNetworking * (^)())patch;
- (DKNetworking * (^)(NSString *url))url;
- (DKNetworking * (^)(NSDictionary *params))params;
- (DKNetworking * (^)(NSDictionary *header))header;
- (DKNetworking * (^)(DKNetworkCacheType cacheType))cacheType;
- (DKNetworking * (^)(DKRequestSerializer requestSerializer))requestSerializer;
- (void (^)(DKNetworkBlock networkBlock))callback;

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
                               callback:(DKNetworkBlock)callback;

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
                                 callback:(DKNetworkBlock)callback;

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
 设置请求头
 */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
