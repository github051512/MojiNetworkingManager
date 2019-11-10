//
//  MJNetworking.m
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/6.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//  MJRequestCacheManager

#import "MJNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "MJRequestCacheManager.h"
#import "MJNetworking+CacheManager.h"
#import "MJNetworking+RequestManager.h"

#define MJ_ERROR_IMFORMATION @"网络出现错误，请检查网络连接"

#define MJ_ERROR [NSError errorWithDomain:@"com.hMJ.MJNetworking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:MJ_ERROR_IMFORMATION}]

///请求池
static NSMutableArray   *requestTasksPool;

///请求头配置
static NSDictionary     *headers;

///当前网络状态
static MJNetworkStatus  networkStatus;

///默认网络超时设置
static NSTimeInterval   requestTimeout = 30.f;

@implementation MJNetworking

#pragma mark - manager
+ (AFHTTPSessionManager *)manager {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    ///证书配置
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [securityPolicy setValidatesDomainName:NO];
    [securityPolicy setAllowInvalidCertificates:YES];
    
    ///请求序列配置
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    requestSerializer.timeoutInterval = requestTimeout;

    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    //响应序列化配置
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*",
                                                                              @"application/octet-stream",
                                                                              @"application/zip"]];
    
    manager.securityPolicy = securityPolicy;
    manager.requestSerializer = requestSerializer;
    manager.responseSerializer= responseSerializer;

    [self checkNetworkStatus];
    
//每次网络请求的时候，检查此时磁盘中的缓存大小，阈值默认是40MB，如果超过阈值，则清理LRU缓存,同时也会清理过期缓存，缓存默认SSL是7天，磁盘缓存的大小和SSL的设置可以通过该方法[MJRequestCacheManager shareManager] setCacheTime: diskCapacity:]设置

    [[MJRequestCacheManager shareManager] clearLRUCache];
    
    return manager;
}

#pragma mark - 检查网络
+ (void)checkNetworkStatus {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager startMonitoring];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus = MJNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusUnknown:
                networkStatus = MJNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus = MJNetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus = MJNetworkStatusReachableViaWiFi;
                break;
            default:
                networkStatus = MJNetworkStatusUnknown;
                break;
        }
    }];
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasksPool == nil) requestTasksPool = [NSMutableArray array];
    });
    
    return requestTasksPool;
}

#pragma mark - get
+ (MJURLSessionTask *)getWithUrl:(NSString *)url
                  refreshRequest:(BOOL)refresh
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(MJGetProgress)progressBlock
                    successBlock:(MJResponseSuccessBlock)successBlock
                       failBlock:(MJResponseFailBlock)failBlock {
    
    //将session拷贝到堆中，block内部才可以获取得到session
    __block MJURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == MJNetworkStatusNotReachable) {
        ///美欧网络则返回请求失败信息
        if (failBlock) failBlock(MJ_ERROR);
        return session;
    }
    
    id responseObj = [[MJRequestCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
    
    ///如果是请求缓存数据并且有缓存数据则返回缓存数据
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager GET:url
                parameters:params
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount,
                                                       downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) successBlock(responseObject);
                      
                      if (cache) [[MJRequestCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                      
                      [[self allTasks] removeObject:session];
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      
                      if (failBlock) failBlock(error);
                      [[self allTasks] removeObject:session];
                  }];
    
    if ([self haveSameRequestInTasksPool:session] && !refresh) {
        //取消新请求
        [session cancel];
        return session;
    }else {
        //无论是否有旧请求，先执行取消旧请求，反正都需要刷新请求
        MJURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:session];
        if (oldTask) [[self allTasks] removeObject:oldTask];
        if (session) [[self allTasks] addObject:session];
        [session resume];
        return session;
    }
}

#pragma mark - post
+ (MJURLSessionTask *)postWithUrl:(NSString *)url
                   refreshRequest:(BOOL)refresh
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(MJPostProgress)progressBlock
                     successBlock:(MJResponseSuccessBlock)successBlock
                        failBlock:(MJResponseFailBlock)failBlock {
   
    __block MJURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == MJNetworkStatusNotReachable) {
        if (failBlock) failBlock(MJ_ERROR);
        return session;
    }
    
    id responseObj = [[MJRequestCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
    
    if (responseObj && cache) {
        if (successBlock) successBlock(responseObj);
    }
    
    session = [manager POST:url
                 parameters:params
                   progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      
                       if (successBlock) successBlock(responseObject);
                       
                       if (cache) [[MJRequestCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                       
                       if ([[self allTasks] containsObject:session]) {
                           [[self allTasks] removeObject:session];
                       }
                       
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       if (failBlock) failBlock(error);
                       [[self allTasks] removeObject:session];
                       
                   }];
    
    
    if ([self haveSameRequestInTasksPool:session] && !refresh) {
        [session cancel];
        return session;
    }else {
        MJURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:session];
        if (oldTask) [[self allTasks] removeObject:oldTask];
        if (session) [[self allTasks] addObject:session];
        [session resume];
        return session;
    }
}

#pragma mark - 文件上传
+ (MJURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(MJUploadProgressBlock)progressBlock
                           successBlock:(MJResponseSuccessBlock)successBlock
                              failBlock:(MJResponseFailBlock)failBlock {
    __block MJURLSessionTask *session = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
    if (networkStatus == MJNetworkStatusNotReachable) {
        if (failBlock) failBlock(MJ_ERROR);
        return session;
    }
    
    session = [manager POST:url
                 parameters:nil
  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
      
      NSString *fileName = nil;
      
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      
      NSString *day = [formatter stringFromDate:[NSDate date]];
      
      fileName = [NSString stringWithFormat:@"%@.%@",day,type];
      
      [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
      
  } progress:^(NSProgress * _Nonnull uploadProgress) {
      
      if (progressBlock) progressBlock (uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
      
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      
      if (successBlock) successBlock(responseObject);
      [[self allTasks] removeObject:session];
      
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      
      if (failBlock) failBlock(error);
      [[self allTasks] removeObject:session];
  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
}

#pragma mark - 多文件上传
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(MJUploadProgressBlock)progressBlock
                      successBlock:(MJMultUploadSuccessBlock)successBlock
                         failBlock:(MJMultUploadFailBlock)failBlock {
    
    if (networkStatus == MJNetworkStatusNotReachable) {
        if (failBlock) failBlock(@[MJ_ERROR]);
        return nil;
    }
    
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    NSInteger count = datas.count;
    for (int i = 0; i < count; i++) {
        __block MJURLSessionTask *session = nil;
        
        dispatch_group_enter(uploadGroup);
        
        session = [self uploadFileWithUrl:url
                                 fileData:datas[i]
                                     type:type name:name
                                 mimeType:mimeTypes
                            progressBlock:^(int64_t bytesWritten, int64_t totalBytes) {
                                if (progressBlock) progressBlock(bytesWritten,
                                                                 totalBytes);
                                
                            } successBlock:^(id response) {
                                [responses addObject:response];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                                
                            } failBlock:^(NSError *error) {
                                NSError *Error = [NSError errorWithDomain:url code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
                                
                                [failResponse addObject:Error];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                            }];
        
        [session resume];
        
        if (session) [sessions addObject:session];
    }
    
    [[self allTasks] addObjectsFromArray:sessions];
    
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (successBlock) {
                successBlock([responses copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
        if (failResponse.count > 0) {
            if (failBlock) {
                failBlock([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
    });
    
    return [sessions copy];
}

#pragma mark - 下载
+ (MJURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(MJDownloadProgress)progressBlock
                         successBlock:(MJDownloadSuccessBlock)successBlock
                            failBlock:(MJDownloadFailBlock)failBlock {
    NSString *type = nil;
    NSArray *subStringArr = nil;
    __block MJURLSessionTask *session = nil;
    
    NSURL *fileUrl = [[MJRequestCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
    
    if (fileUrl) {
        if (successBlock) successBlock(fileUrl);
        return nil;
    }
    
    if (url) {
        subStringArr = [url componentsSeparatedByString:@"."];
        if (subStringArr.count > 0) {
            type = subStringArr[subStringArr.count - 1];
        }
    }
    
    AFHTTPSessionManager *manager = [self manager];
    //响应内容序列化为二进制
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    session = [manager GET:url
                parameters:nil
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                   
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      
                      if (successBlock) {
                          NSData *dataObj = (NSData *)responseObject;
                          
                          [[MJRequestCacheManager shareManager] storeDownloadData:dataObj requestUrl:url];
                          
                          NSURL *downFileUrl = [[MJRequestCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
                          
                          successBlock(downFileUrl);
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                      if (failBlock) {
                          failBlock (error);
                      }
                  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
    
}

#pragma mark - other method
+ (void)setupTimeout:(NSTimeInterval)timeout {
  
    requestTimeout = timeout;
}

+ (void)cancleAllRequest {
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(MJURLSessionTask  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if ([obj isKindOfClass:[MJURLSessionTask class]]) {
                [obj cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) return;
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(MJURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[MJURLSessionTask class]]) {
                if ([obj.currentRequest.URL.absoluteString hasSuffix:url]) {
                    [obj cancel];
                    *stop = YES;
                }
            }
        }];
    }
}

+ (void)configHttpHeader:(NSDictionary *)httpHeader {
    headers = httpHeader;
}

+ (NSArray *)currentRunningTasks {
    return [[self allTasks] copy];
}

@end

