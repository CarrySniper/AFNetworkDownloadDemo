//
//  AFDownloadObject.h
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/** 下载状态NS_ENUM */
typedef NS_ENUM(NSInteger, CLDownloadState) {
    CLDownloadStateWaiting,     // 等待下载
    CLDownloadStateRunning,     // 下载中
    CLDownloadStateSuspended,   // 挂起，暂停下载
    CLDownloadStateCanceling,   // 取消，不再下载
    CLDownloadStateCompleted    // 下载完成（成功／失败）
};

/** 下载状态Block */
typedef void (^CLDownloadStateBlock)(CLDownloadState state);

/**
 下载进度Block

 @param receivedSize 已接收数据大小（已下载 1KB/1MB）
 @param expectedSize 预计下载数据大小（总大小 1KB/1MB）
 @param speed 速度（每秒下载大小 1KB/1MB。不带“/秒”单位，自己拼上去1MB/s 1MB/S）
 @param progress 下载进度
 */
typedef void (^CLDownloadProgressBlock)(NSString *receivedSize, NSString *expectedSize, NSString *speed, CGFloat progress);

/**
 下载完成（成功／失败）Block

 @param successful 是否下载成功
 @param filePath 成功文件路径
 @param error 失败原因
 */
typedef void (^CLDownloadCompletionBlock)(BOOL successful, NSString *filePath, NSError *error);

#pragma mark - Class
@interface AFDownloadObject : NSObject

@property (nonatomic, copy) NSString *directoryPath;            // 下载完成后保存的目录
@property (nonatomic, strong) NSString *urlString;              // URL完整链接
@property (nonatomic, strong) NSOutputStream *outputStream;     // 输出流
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;   // 会话数据任务

// 计算速度
@property (nonatomic, copy) NSString *speed;                    // 每秒下载到大小
@property (nonatomic, copy) NSDate *date;                       // 时间-辅助计算下载速度
@property (nonatomic, assign) NSInteger readLength;             // 长度-辅助计算下载速度
// 计算进度
@property (nonatomic, assign) NSInteger totalLength;

// block
@property (nonatomic, copy) CLDownloadStateBlock stateBlock;
@property (nonatomic, copy) CLDownloadProgressBlock progressBlock;
@property (nonatomic, copy) CLDownloadCompletionBlock completionBlock;

/**
 不允许使用
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 实例化方法

 @param urlString 下载链接
 @param beginlocation 下载起始位置
 @param directoryPath 下载文件目录位置
 @return 对象
 */
- (instancetype)initWithUrlString:(NSString *)urlString
                       beginRange:(NSUInteger)beginlocation
					directoryPath:(NSString *)directoryPath NS_DESIGNATED_INITIALIZER;

// MARK: - 保存文件
- (void)openOutputStream;

- (void)closeOutputStream;

@end
