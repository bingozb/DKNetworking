# DKNetworking
基于 AFNetworking + YYCache 的二次封装，支持缓存策略的网络请求框架


## 前言

网络层是 APP 架构的一个重要部分，苹果的 CFNetwork 框架极其难用，导致基于 CFN 的框架 ASI 已经放弃维护。后来苹果推出了 NSURLSession，许多开源的框架都是基于它进行封装，例如我选用的 AFNetworking，运行效率没有 ASI 高，使用比 ASI 简单。但是，从使用的角度来看，还需要继续封装。于是，我依赖于 AFN + YYCache + MJExtension 封装出了 DKNetworking 框架。


## 特点

- DKNetworkSessionManager 对 AFHTTPSessionManager 进行封装，以便以后可以轻易换掉依赖的 AFN。封装一层底层方法，包括网络请求、文件上传、文件下载这三个方法。其中网络请求调用了 AFN 的私有 API，把 GET、POST、PUT、DELETE、PATCH 这五个方法封成了一个 request 方法。

- 拥有 AFN 大部分常用功能，包括网络状态监听等，提供类方法和实例方法调用。

- 根据 JavaWeb 中 HttpServlet 的设计思想，把网络请求的回调封装成了 request 和 response 两个对象。

- 支持界面多级缓存。

- 支持链式调用。

- 支持配合 RAC 框架使用链式调用，支持自定义信号的返回值。

## 安装

### 支持 Cocoapods 安装

```objc
pod 'DKNetworking'
```

### 或者下载 Demo 项目

- 将根目录下的 DKNetworking 和 Vendor 文件夹拉进项目，其中 Vendor 文件夹有 AFNetworking、MJExtension、YYCache 和 ReactiveCocoa，前三个是必须依赖的，ReactiveCocoa 是可选的。

- 必须在 Target -> Build Phases -> Link Binary With Libraries 中添加 `libsqlite3.0.tbd`，这是 YYCache 框架所需的。

## 使用

绝大部分方法都可以直接看 DKNetworking.h 中的声明以及注释。

### 获取单例对象

```objc
DKNetworking *networking = [DKNetworking networkManager];
```

从 1.1.0 版本开始提供了一个单例对象宏 `DKNetworkManager`。

### DKN 配置

#### 设置请求根路径

```objc
[DKNetworking setupBaseURL:@"https://m.sfddj.com/app/v1/"];
```
baseURL 的路径一定要有“/”结尾，设置后所有的网络访问都使用相对路径。

#### 设置日志

##### 开启日志打印

```objc
[DKNetworking openLog];
```

##### 关闭日志打印

```objc
[DKNetworking closeLog];
```

#### 设置缓存

##### 设置缓存方式

```objc
/**
 设置缓存方式
 DKNetworkCacheTypeNetworkOnly : 只加载网络数据
 DKNetworkCacheTypeCacheNetwork : 先加载缓存,然后加载网络
 @param cacheType 缓存类型
 */
+ (void)setupCacheType:(DKNetworkCacheType)cacheType;

```

##### 获取缓存大小

```objc
/**
 获取网络缓存的总大小 动态单位(GB,MB,KB,B)

 @return 网络缓存的总大小
 */
+ (NSString *)cacheSize;
```

##### 清除缓存

```objc
[DKNetworkCache clearCache];
```

#### 设置序列化格式
##### 设置请求序列化格式

```objc
/**
 设置网络请求参数的格式 : 默认为二进制格式

 @param requestSerializer DKRequestSerializerJSON:JSON格式, DKRequestSerializerHTTP:二进制格式
 */
+ (void)setRequestSerializer:(DKRequestSerializer)requestSerializer;
```
##### 设置响应反序列化格式

```objc
/**
 设置服务器响应数据格式 : 默认为JSON格式

 @param responseSerializer DKResponseSerializerJSON:JSON格式, DKResponseSerializerHTTP:二进制格式
 */
+ (void)setResponseSerializer:(DKResponseSerializer)responseSerializer;
```

#### 设置请求超时时间

```objc
/**
 设置请求超时时间 : 默认10秒

 @param time 请求超时时长(秒)
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;
```

#### 设置 Header
##### 设置一对请求头参数

```objc
/**
 设置一对请求头参数

 @param value 请求头参数值
 @param field 请求头参数名
 */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
```
##### 设置多对请求头参数

```objc
/**
 设置多对请求头参数

 @param networkHeader 请求头参数字典
 */
+ (void)setNetworkHeader:(NSDictionary *)networkHeader;
```

### 网络状态

#### 监听网络状态

```objc
[DKNetworking networkStatusWithBlock:^(DKNetworkStatus status) {
    switch (status) {
        case DKNetworkStatusUnknown: // 网络状态未知
            break;
        case DKNetworkStatusNotReachable: // 无网络
            break;
        case DKNetworkStatusReachableViaWWAN: // 手机网络（蜂窝）
            break;
        case DKNetworkStatusReachableViaWiFi: // WIFI网络
            break;
    }
}];
```

#### 获取当前网络状态

```objc
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
```

### 网络请求

#### 常规调用

**以 POST 方法为例，方法定义：**

```objc
/**
 POST请求
 
 @param URL 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @return 返回的对象可取消请求,调用cancel方法
 */
+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
- (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters callback:(DKNetworkBlock)callback;
```

**调用：**

```objc
[DKNetworking POST:url parameters:@{@"name":@"bingo"} callback:^(DKNetworkRequest *request, DKNetworkResponse *response) {
    // ...
}];
```

#### 链式调用

**方法定义：**

```objc
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
```

**调用：**

```objc
DKNetworkManager.post(url).params(@{@"name":@"bingo"}).callback(^(DKNetworkRequest *request, DKNetworkResponse *response) {
    // ...
});
```

#### RAC 链式调用

**方法定义：**

在原链式方法的基础上补充了一个 executeSignal 方法，返回信号。

```objc
#ifdef RAC
/** RAC链式发送请求 */
- (RACSignal *)executeSignal;
#endif
```

**调用：**

```objc
[DKNetworkManager.post(url).params(@{@"name":@"bingo"}).executeSignal subscribeNext:^(RACTuple *x) {
    DKNetworkResponse *response = x.second;
    // ...
} error:^(NSError *error) {
    // ...
}];
```

#### RAC 链式调用 自定义信号的返回值

**方法定义：**

```objc
#ifdef RAC
/**
 设置响应结果回调，可以设置信号返回的value为自己想要的值，比如用MJExtension框架，将DKNetworkResponse对象的rawData字典转为自己项目的实体类再返回
 
 @param flattenMapBlock 结果映射的设置回调block，其中RACTuple的first为DKNetworkRequest对象，second为DKNetworkResponse对象
 */
+ (void)setupResponseSignalWithFlattenMapBlock:(DKNetworkFlattenMapBlock)flattenMapBlock;
#endif
```

**使用：**

考虑到代码执行顺序的问题，建议在项目中创建一个继承自 NSObject 的类 DKNetworkConfig，在 + load 方法中调用 DKN 的配置方法，设置回调的信号的 return 值，根据不同项目进行配置。

```objc
[DKNetworking setupResponseSignalWithFlattenMapBlock:^RACStream *(RACTuple *tuple) {
    DKNetworkResponse *response = tuple.second; // 框架默认返回的response
    MyHttpResponse *myResponse = [MyHttpResponse mj_objectWithKeyValues:response.rawData]; // 项目需要的response
    myResponse.rawData = response.rawData;
    myResponse.error = response.error;
    return [RACSignal return:RACTuplePack(tuple.first, myResponse)];
}];
```

**调用：**

经过上面的`setupResponseSignalWithFlattenMapBlock:`方法设置后，信号返回的 RACTuple 的 second 为自定义的 response 对象。

```objc
[DKNetworkManager.post(url).executeSignal subscribeNext:^(RACTuple *x) {
//        DKNetworkResponse *response = x.second;
    MyHttpResponse *myResponse = x.second;
    // ...
} error:^(NSError *error) {
    // ...
}];
```

#### 取消请求

```objc
/**
 取消所有HTTP请求
 */
+ (void)cancelAllRequest;

/**
 取消指定URL的HTTP请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL;
```

#### 上传

##### 上传文件

```objc
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
```

##### 上传图片

```objc
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
```

#### 下载

```objc
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
```

## TODO

- 链式编程虽然好看一点，但是没有常规调用方便，不能像以往一样敲两个字母 Xcode 就智能补全整个方法，并且可能会出现 `.get().post().get().post()` 这种没有意义的链式调用的情况。

- 用面向协议（接口）的函数式编程可以解决上面的问题，但是网络层工具的调用是可以没有顺序的，比如 `.params().post()` 跟 `.post().params()` 应该是都可以的，这样的话会让协议很难制定，还是会出现上面的问题。

- 日志保存文件

- 考虑添加 UI 层分类，让网络请求的错误日志以一种更友好的方式展示。

- 与服务端的通讯加密，考虑添加 RSA 非对称加密等方法。
