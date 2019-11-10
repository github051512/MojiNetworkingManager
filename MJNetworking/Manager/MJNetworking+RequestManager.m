//
//  MJNetworking+RequestManager.m
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/6.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJNetworking+RequestManager.h"

@interface NSURLRequest (decide)

//判断是否是同一个请求（依据是请求url和参数是否相同）
- (BOOL)isTheSameRequest:(NSURLRequest *)request;

@end

@implementation NSURLRequest (decide)

- (BOOL)isTheSameRequest:(NSURLRequest *)request {
    if ([self.HTTPMethod isEqualToString:request.HTTPMethod]) {
        if ([self.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
            if ([self.HTTPMethod isEqualToString:@"GET"]||[self.HTTPBody isEqualToData:request.HTTPBody]) {
                return YES;
            }
        }
    }
    return NO;
}

@end


@implementation MJNetworking (RequestManager)

+ (BOOL)haveSameRequestInTasksPool:(MJURLSessionTask *)task {
    __block BOOL isSame = NO;
    [[self currentRunningTasks] enumerateObjectsUsingBlock:^(MJURLSessionTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([task.originalRequest isTheSameRequest:obj.originalRequest]) {
            isSame  = YES;
            *stop = YES;
        }
    }];
    return isSame;
}

+ (MJURLSessionTask *)cancleSameRequestInTasksPool:(MJURLSessionTask *)task {
    __block MJURLSessionTask *oldTask = nil;
    
    [[self currentRunningTasks] enumerateObjectsUsingBlock:^(MJURLSessionTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([task.originalRequest isTheSameRequest:obj.originalRequest]) {
            if (obj.state == NSURLSessionTaskStateRunning) {
                [obj cancel];
                oldTask = obj;
            }
            *stop = YES;
        }
    }];
    
    return oldTask;
}

@end
