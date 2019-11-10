//
//  MJNetworking.h
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/6.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  网络状态
 */
typedef NS_ENUM(NSInteger, MJNetworkStatus) {
    /**
     *  未知网络
     */
    MJNetworkStatusUnknown             = 1 << 0,
    /**
     *  无法连接
     */
    MJNetworkStatusNotReachable        = 1 << 1,
    /**
     *  WLAN网络
     */
    MJNetworkStatusReachableViaWWAN    = 1 << 2,
    /**
     *  WiFi网络
     */
    MJNetworkStatusReachableViaWiFi    = 1 << 3
};

/**
 *  请求任务
 */
typedef NSURLSessionTask MJURLSessionTask;

/**
 *  成功回调
 *
 *  @param response 成功后返回的数据
 */
typedef void(^MJResponseSuccessBlock)(id response);

/**
 *  失败回调
 *
 *  @param error 失败后返回的错误信息
 */
typedef void(^MJResponseFailBlock)(NSError *error);

/**
 *  下载进度
 *
 *  @param bytesRead              已下载的大小
 *  @param totalBytes             总下载大小
 */
typedef void (^MJDownloadProgress)(int64_t bytesRead,int64_t totalBytes);

/**
 *  下载成功回调
 *
 *  @param url                       下载存放的路径
 */
typedef void(^MJDownloadSuccessBlock)(NSURL *url);

/**
 *  上传进度
 *
 *  @param bytesWritten              已上传的大小
 *  @param totalBytes                总上传大小
 */

typedef void(^MJUploadProgressBlock)(int64_t bytesWritten,int64_t totalBytes);

/**
 *  多文件上传成功回调
 *
 *  @param responses 成功后返回的数据
 */
typedef void(^MJMultUploadSuccessBlock)(NSArray *responses);

/**
 *  多文件上传失败回调
 *
 *  @param errors 失败后返回的错误信息
 */
typedef void(^MJMultUploadFailBlock)(NSArray *errors);

typedef MJDownloadProgress MJGetProgress;

typedef MJDownloadProgress MJPostProgress;

typedef MJResponseFailBlock MJDownloadFailBlock;


@interface MJNetworking : NSObject

/**
 *  正在运行的网络任务
 *
 *  @return task
 */
+ (NSArray *)currentRunningTasks;

/**
 *  配置请求头
 *
 *  @param httpHeader 请求头
 */
+ (void)configHttpHeader:(NSDictionary * __nullable)httpHeader;

/**
 *  取消请求
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/**
 *  取消所有请求
 */
+ (void)cancleAllRequest;

/**
 *  设置超时时间
 *
 *  @param timeout 超时时间
 */
+ (void)setupTimeout:(NSTimeInterval)timeout;

/**
 *  GET请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          是否刷新请求(遇到重复请求，若为YES，则会取消旧的请求，用新的请求，若为NO，则忽略新请求，用旧请求)
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (MJURLSessionTask *)getWithUrl:(NSString *)url
                  refreshRequest:(BOOL)refresh
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(MJGetProgress)progressBlock
                    successBlock:(MJResponseSuccessBlock)successBlock
                       failBlock:(MJResponseFailBlock)failBlock;




/**
 *  POST请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          解释同上
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (MJURLSessionTask *)postWithUrl:(NSString *)url
                   refreshRequest:(BOOL)refresh
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(MJPostProgress)progressBlock
                     successBlock:(MJResponseSuccessBlock)successBlock
                        failBlock:(MJResponseFailBlock)failBlock;




/**
 *  文件上传
 *
 *  @param url              上传文件接口地址
 *  @param data             上传文件数据
 *  @param type             上传文件类型
 *  @param name             上传文件服务器文件夹名
 *  @param mimeType         mimeType
 *  @param progressBlock    上传文件路径
 *    @param successBlock     成功回调
 *    @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (MJURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(MJUploadProgressBlock)progressBlock
                           successBlock:(MJResponseSuccessBlock)successBlock
                              failBlock:(MJResponseFailBlock)failBlock;


/**
 *  多文件上传
 *
 *  @param url           上传文件地址
 *  @param datas         数据集合
 *  @param type          类型
 *  @param name          服务器文件夹名
 *  @param mimeTypes      mimeTypes
 *  @param progressBlock 上传进度
 *  @param successBlock  成功回调
 *  @param failBlock     失败回调
 *
 *  @return 任务集合
 */
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(MJUploadProgressBlock)progressBlock
                      successBlock:(MJMultUploadSuccessBlock)successBlock
                         failBlock:(MJMultUploadFailBlock)failBlock;

/**
 *  文件下载
 *
 *  @param url           下载文件接口地址
 *  @param progressBlock 下载进度
 *  @param successBlock  成功回调
 *  @param failBlock     下载回调
 *
 *  @return 返回的对象可取消请求
 */
+ (MJURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(MJDownloadProgress)progressBlock
                         successBlock:(MJDownloadSuccessBlock)successBlock
                            failBlock:(MJDownloadFailBlock)failBlock;

@end

NS_ASSUME_NONNULL_END
