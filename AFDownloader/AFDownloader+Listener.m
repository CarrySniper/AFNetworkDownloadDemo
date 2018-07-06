//
//  AFDownloader+Listener.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/29.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloader+Listener.h"
#import "AFDownloader+Plist.h"

@implementation AFDownloader (Listener)

#pragma mark - 数据处理
- (void)setSessionManagerListener {
    __weak typeof(self) weakSelf = self;
    // MARK: 完成会话任务回调
    [self.sessionManager setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
        NSLog(@"下载结束");
        // Error Domain=NSURLErrorDomain Code=-999 "Canceled/已取消"
        if ((error && error.code == -999) || task.state == NSURLSessionTaskStateCanceling) {
            return;
        }
        
        AFDownloadObject *object = weakSelf.downloadsSet[task.taskDescription];
        if (object) {
            // 关闭输出
            [object closeOutputStream];
            // 移除出下载中数组
            [weakSelf.downloadingArray removeObject:object];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([weakSelf isDownloadCompleted:object.urlString]) {
					NSString *filePath = [weakSelf fileAbsolutePath:object.urlString];
					if (object.directoryPath) {// 这个是替换的地址
						filePath = [object.directoryPath stringByAppendingPathComponent:[filePath lastPathComponent]];
					}
                    if (object.stateBlock) {
                        object.stateBlock(CLDownloadStateCompleted);
                    }
                    if (object.completionBlock) {
                        object.completionBlock(YES, filePath, nil);
                    }
                } else {
                    if (object.stateBlock) {
                        object.stateBlock(CLDownloadStateCanceling);
                    }
                    if (object.completionBlock) {
                        object.completionBlock(NO, nil, error);
                    }
                }
            });
            // 下载下一个
            [weakSelf toDowloadNextObject];
        }
    }];
    
    // MARK: 接收到请求响应时回调
    [self.sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        AFDownloadObject *object = weakSelf.downloadsSet[dataTask.taskDescription];
        if (object) {
            // 开启输出
            [object openOutputStream];
            // 记录时间
            object.date = [NSDate date];
            
            // 计算保存已下载大小 expectedContentLength：预计要下载长度 + 已下载文件长度
			NSUInteger downloadLength = [weakSelf downloadLengthPlistWithUrlString:object.urlString];
            NSUInteger totalLength = (long)response.expectedContentLength + downloadLength;
            object.totalLength = totalLength;
            // 将长度写入Plist文件
			[weakSelf addPlistWithUrlString:object.urlString directoryPath:object.directoryPath downloadLength:downloadLength totalLength:totalLength];
        }
        
        return NSURLSessionResponseAllow;
    }];
    
	// MARK: 数据接收回调
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        
        AFDownloadObject *object = weakSelf.downloadsSet[dataTask.taskDescription];
        if (!object) {
            [dataTask cancel];
            return;
        }
        // 保存文件
        [object.outputStream write:data.bytes maxLength:data.length];
        // 更新Plist数据
        [weakSelf updatePlistWithUrlString:object.urlString addDownloadLength:data.length];
        
        /** 计算下载速度 最快要计算1秒内的速度，所以要+=累积 */
        object.readLength += data.length;
        NSDate *currentDate = [NSDate date];
        if ([currentDate timeIntervalSinceDate:object.date] >= 1) {
            NSTimeInterval time = [currentDate timeIntervalSinceDate:object.date];
            double speed = object.readLength / time;
            object.speed = [weakSelf formatByteCount:speed];
            object.date = currentDate;
            object.readLength = 0;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (object.progressBlock) {
                NSUInteger receivedSize = [weakSelf downloadLengthPlistWithUrlString:object.urlString];
                NSUInteger expectedSize = object.totalLength;
                if (expectedSize == 0) {
                    return;
                }
                CGFloat progress = 1.0 * receivedSize / expectedSize;
                object.progressBlock([weakSelf formatByteCount:receivedSize],
                                     [weakSelf formatByteCount:expectedSize],
                                     object.speed,
                                     progress);
            }
        });
    }];
    
    //    [self.sessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
    //
    //    }];
    //    [self.sessionManager setDownloadTaskDidResumeBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t fileOffset, int64_t expectedTotalBytes) {
    //
    //    }];
}

@end
