//
//  MJMemoryCache.m
//  MojiCustomerClient
//
//  Created by 刘志伟 on 2019/11/7.
//  Copyright © 2019 liuzhiwei. All rights reserved.
//

#import "MJMemoryCache.h"

static NSCache *shareCache;

@implementation MJMemoryCache

+ (NSCache *)shareCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shareCache == nil) shareCache = [[NSCache alloc] init];
        
    });
    
    //当收到内存警报时，清空内存缓存
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [shareCache removeAllObjects];
    }];
    
    return shareCache;
}

+ (void)writeData:(id)data forKey:(NSString *)key {
    assert(data);
    
    assert(key);
    
    NSCache *cache = [MJMemoryCache shareCache];
    
    [cache setObject:data forKey:key];
    
    NSLog(@"%@",[cache objectForKey:key]);
    
}

+ (id)readDataWithKey:(NSString *)key {
    assert(key);
    
    id data = nil;
    
    NSCache *cache = [MJMemoryCache shareCache];
    
    data = [cache objectForKey:key];
    
    return data;
}

- (void)dealloc {
  
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end
