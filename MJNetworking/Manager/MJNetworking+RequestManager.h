//
//  MJNetworking+RequestManager.h
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/6.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJNetworking.h"

NS_ASSUME_NONNULL_BEGIN

@interface MJNetworking (RequestManager)

/**
 *  判断网络请求池中是否有相同的请求
 *
 *  @param task 网络请求任务
 *
 *  @return bool
 */
+ (BOOL)haveSameRequestInTasksPool:(MJURLSessionTask *)task;

/**
 *  如果有旧请求则取消旧请求
 *
 *  @param task 新请求
 *
 *  @return 旧请求
 */
+ (MJURLSessionTask *)cancleSameRequestInTasksPool:(MJURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
