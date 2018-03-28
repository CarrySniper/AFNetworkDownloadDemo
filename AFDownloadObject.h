//
//  AFDownloadObject.h
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLDownloadState) {
    CLDownloadStateWaiting,
    CLDownloadStateRunning,
    CLDownloadStateSuspended,
    CLDownloadStateCanceling,
    CLDownloadStateCompleted
};

/** 下载状态Block */
typedef void (^CLDownloadStateBlock)(CLDownloadState state);
/** 下载进度Block */
typedef void (^CLDownloadProgressBlock)(NSString *receivedSize, NSString *expectedSize, NSString *speed, CGFloat progress);
/** 下载完成（成功／失败）Block */
typedef void (^CLDownloadCompletionBlock)(BOOL successful, NSString *filePath, NSError *error);

@interface AFDownloadObject : NSObject

@property (nonatomic, copy) NSString *directoryPath;            // 下载完成后保存的目录
@property (nonatomic, strong) NSString *urlString;              // URL完整链接
@property (nonatomic, strong) NSOutputStream *outputStream;     // 输出流
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;   // 会话数据任务

// 计算速度
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *speed;                    // 每秒下载到大小
@property (nonatomic, assign) NSInteger readLength;
// 计算进度
@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic, copy) CLDownloadStateBlock stateBlock;
@property (nonatomic, copy) CLDownloadProgressBlock progressBlock;
@property (nonatomic, copy) CLDownloadCompletionBlock completionBlock;

- (instancetype)initWithUrlString:(NSString *)urlString beginRange:(NSUInteger)length withPath:(NSString *)directory;

// MARK: - 保存文件
- (void)openOutputStream;

- (void)closeOutputStream;

@end
