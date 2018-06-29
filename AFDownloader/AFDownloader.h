//
//  AFDownloader.h
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "AFDownloadObject.h"

#define CLCachesDirectory       [[AFDownloader manager] cachesDirectory]  // 缓存路径
#define CLFileName(URL)         [URL lastPathComponent] // 根据URL获取文件名，xxx.zip
#define CLFilePath(URL)         [CLCachesDirectory stringByAppendingPathComponent:CLFileName(URL)]
#define CLFilesPlistPath        [CLCachesDirectory stringByAppendingPathComponent:@"CLFilesSize.plist"]

/** 下载完成（成功／失败）Block */
typedef void (^CLDownloaderBlock)(AFDownloadObject *object);

@interface AFDownloader : NSObject

/** 最大并发数，0为不限制，默认3 */
@property (nonatomic, assign) NSInteger maxConcurrentCount;

// 内部属性，不需设置
@property (nonatomic, strong) AFURLSessionManager *sessionManager;                              // 会话对象
@property (nonatomic, strong) NSFileManager *fileManager;                                       // 文件管理
@property (nonatomic, strong) NSString *cachesDirectory;                                        // 文件目录
@property (nonatomic, strong) NSMutableArray<AFDownloadObject *> *downloadingArray;             // 下载中队列
@property (nonatomic, strong) NSMutableArray<AFDownloadObject *> *waitingArray;                 // 待下载队列
@property (nonatomic, strong) NSMutableDictionary<NSString *, AFDownloadObject *> *downloadsSet;// 全部下载集合（下载中/待下载/暂停/已下载……）

#pragma mark - Class
+ (instancetype)manager;

/**
 获取某条下载数据
 */
- (NSDictionary *)downloadObjectWithUrlString:(NSString *)urlString;

/**
 获取下载列表数据
 */
- (NSArray *)downloadList;

/**
 下载文件
 
 @param urlString URL链接
 @param directory 文件下载完成后保存的目录，如果为nil，默认保存到“.../Library/Caches/AFDownloader”
 @param state 回调-下载状态
 @param progress 回调-下载进度
 @param completion 回调-下载完成
 */
- (void)downloadURL:(NSString *)urlString
          directory:(NSString *)directory
              state:(CLDownloadStateBlock)state
           progress:(CLDownloadProgressBlock) progress
         completion:(CLDownloadCompletionBlock)completion;


#pragma mark - Downloads
/**
 下载下一个文件
 */
- (void)toDowloadNextObject;

/**
 挂起指定下载任务
 */
- (void)suspendDownload:(NSString *)urlString;

/**
 挂起全部下载任务
 */
- (void)suspendAllDownloads;

/**
 恢复指定下载任务
 */
- (void)resumeDownload:(NSString *)urlString;

/**
 恢复全部下载任务
 */
- (void)resumeAllDownloads;

/**
 删除指定下载任务
 */
- (void)deleteDownload:(NSString *)urlString;

/**
 删除全部下载任务
 */
- (void)deleteAllDownloads;

#pragma mark - Files
/**
 文件绝对路径
 */
- (NSString *)fileAbsolutePath:(NSString *)urlString;

/**
 格式化文件大小
 */
- (NSString *)formatByteCount:(long long)size;

@end


