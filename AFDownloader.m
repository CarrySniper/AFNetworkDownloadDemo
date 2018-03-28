//
//  AFDownloader.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "AFDownloader.h"
#import "AFDownloader+Plist.h"

#define CLCachesDirectory       [[AFDownloader manager] cachesDirectory]  // 缓存路径

#define CLFileName(URL)         [URL lastPathComponent] // 根据URL获取文件名，xxx.zip

#define CLFilePath(URL)         [CLCachesDirectory stringByAppendingPathComponent:CLFileName(URL)]

#define CLFilesPlistPath        [CLCachesDirectory stringByAppendingPathComponent:@"CLFilesSize.plist"]

@interface AFDownloader ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AFDownloadObject *> *downloadsSet;
@property (nonatomic, strong) NSMutableArray *downloadingArray;
@property (nonatomic, strong) NSMutableArray *waitingArray;

@end

@implementation AFDownloader

+ (instancetype)manager {
    return [[self alloc] init];
}

static AFDownloader *instance = nil;
static dispatch_once_t onceToken;
- (instancetype)init
{
    dispatch_once(&onceToken, ^{
        instance = [super init];
        
        [self setDataHandle];
        
        self.maxConcurrentCount = 0;
        self.fileManager = [NSFileManager defaultManager];
        self.downloadsSet = [NSMutableDictionary dictionary];
        self.downloadingArray = [NSMutableArray array];
        self.waitingArray = [NSMutableArray array];
        
        // 创建下载目录
        NSString *cachesDirectory = [self cachesDirectory];
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isExists = [fileManager fileExistsAtPath:cachesDirectory isDirectory:&isDirectory];
        if (!isExists || !isDirectory) {
            [fileManager createDirectoryAtPath:cachesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    return instance;
}

- (void)downloadURL:(NSString *)urlString
          directory:(NSString *)directory
              state:(CLDownloadStateBlock)state
           progress:(CLDownloadProgressBlock) progress
         completion:(CLDownloadCompletionBlock)completion
{
    if (!urlString) {
        return;
    }
    
    NSString *encodedString = [self encodedString:urlString];
    NSInteger length = [self downloadedLength:encodedString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    // 判断urlString的文件名是否已经下载完成
    if ([self isDownloadCompleted:encodedString]) {
        if (state) {
            state(CLDownloadStateCompleted);
        }
        if (progress) {
            progress([self formatByteCount:length], [self formatByteCount:length], [self formatByteCount:0.0], 1.0);
        }
        if (completion) {
            completion(YES, [self fileAbsolutePath:encodedString], nil);
        }
        return;
    }
    
    // 判断是否在下载集合里面，存在则不创建新的
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];//键为文件名
    if (object) {
        return;
    }
    
    // 实例化 新的下载对象
    object = [[AFDownloadObject alloc]initWithUrlString:encodedString beginRange:length withPath:directory];
    object.dataTask.taskDescription = CLFileName(URL);//键为文件名
    object.stateBlock = state;
    object.progressBlock = progress;
    object.completionBlock = completion;
    
    self.downloadsSet[object.dataTask.taskDescription] = object;
    
    // 添加到待下载列表，进行下载
    [self.waitingArray addObject:object];
    [self toDowloadNextObject];

    
//    NSURL *URL = [NSURL URLWithString:encodedString];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
//
//    // Range
//    // bytes=x-y ==  x byte ~ y byte
//    // bytes=x-  ==  x byte ~ end
//    // bytes=-y  ==  head ~ y byte
//    NSInteger length = [self downloadedLength:[URL absoluteString]];
//    [request setValue:[NSString stringWithFormat:@"bytes=%ld-", (long)length] forHTTPHeaderField:@"Range"];
//
//    __block NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
//
//    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
//
//    }];
//
//    [dataTask resume];
//
//    NSString *absolutePath = [self fileAbsolutePathOfURL:URL];
//
//    AFDownloadObject *object = [[AFDownloadObject alloc]init];
//    object.urlString = [URL absoluteString];
//    object.outputStream = [NSOutputStream outputStreamToFileAtPath:absolutePath append:YES];
//    object.dataTask = dataTask;
//    self.downloadsSet[dataTask.taskDescription] = object;
    
//    NSURLSessionDownloadTask *downloadTask;
//    downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//
//    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//        NSString *filePath = [[weakSelf cachesDirectory] stringByAppendingPathComponent:response.suggestedFilename];
//        return [NSURL fileURLWithPath:filePath];
//    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//
//    }];
//
//    [downloadTask resume];
}

#pragma mark - 下载列表数据
- (NSDictionary *)downloadObjectWithUrlString:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    return [self getOneDataWithPlist:CLFilesPlistPath urlString:encodedString];
}
- (NSArray *)downloadList {
    return [self getAllDataWithPlist:CLFilesPlistPath];
}

#pragma mark - 数据处理
- (void)setDataHandle {
    __weak typeof(self) weakSelf = self;
    // 完成会话任务回调
    [self.sessionManager setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
        NSLog(@"setTaskDidCompleteBlock %zd",task.state);
        
        // Error Domain=NSURLErrorDomain Code=-999 "Canceled/已取消"
        if (error && error.code == -999) {
            return;
        }
        
        AFDownloadObject *object = weakSelf.downloadsSet[task.taskDescription];
        if (object) {
            
            // 关闭输出
            [object closeOutputStream];
            
            [weakSelf.downloadsSet removeObjectForKey:task.taskDescription];
            [weakSelf.downloadingArray removeObject:object];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([weakSelf isDownloadCompleted:object.urlString]) {
                    NSString *destPath = object.directoryPath;
                    NSString *fullPath = [weakSelf fileAbsolutePath:object.urlString];
                    if (destPath) {
                        NSError *error;
                        if (![weakSelf.fileManager moveItemAtPath:fullPath toPath:destPath error:&error]) {
                            NSLog(@"moveItemAtPath error: %@", error);
                        }
                    }
                    if (object.stateBlock) {
                        object.stateBlock(CLDownloadStateCompleted);
                    }
                    if (object.completionBlock) {
                        object.completionBlock(YES, destPath ?: fullPath, nil);
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
    
    // 接收到请求响应时回调
    [self.sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        NSLog(@"setDataTaskDidReceiveResponseBlock %zd",dataTask.state);
        AFDownloadObject *object = weakSelf.downloadsSet[dataTask.taskDescription];
        if (object) {
            // 开启输出
            [object openOutputStream];
            // 记录时间
            object.date = [NSDate date];
            
            // 计算保存已下载大小 expectedContentLength：预计要下载长度 + 已下载文件长度
            NSUInteger downloadLength = [weakSelf downloadedLength:object.urlString];
            NSUInteger totalLength = (long)response.expectedContentLength + downloadLength;
            object.totalLength = totalLength;
            // 将长度写入Plist文件
            [weakSelf writeLengthWithPlist:CLFilesPlistPath urlString:object.urlString downloadLength:downloadLength totalLength:totalLength];
        }
        
        return NSURLSessionResponseAllow;
    }];
    
    // 数据接收回调
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        
        NSLog(@"DidReceiveData %zd",dataTask.state);
        AFDownloadObject *object = weakSelf.downloadsSet[dataTask.taskDescription];
        if (!object) {
            [dataTask cancel];
            return;
        }
        // 保存文件
        [object.outputStream write:data.bytes maxLength:data.length];
        // 更新Plist数据
        [weakSelf updateWithPlist:CLFilesPlistPath urlString:object.urlString addDownloadLength:data.length];
        
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
                NSUInteger receivedSize = [weakSelf downloadedLength:object.urlString];
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

#pragma mark - Assist Methods
#pragma mark 可以恢复下载
- (BOOL)canBeginDownload {
    // 最大的并发下载数量，0没有限制。
    if (self.maxConcurrentCount == 0) {
        return YES;
    }
    if (self.downloadingArray.count >= self.maxConcurrentCount) {
        return NO;
    }
    return YES;
}

#pragma mark 下载下一个
- (void)toDowloadNextObject {
    if (self.waitingArray.count == 0) {
        return;
    }
    
    AFDownloadObject *object = self.waitingArray.firstObject;
    
    if ([self canBeginDownload]) {
        [self.waitingArray removeObject:object];
        [self.downloadingArray addObject:object];
        
        [object.dataTask resume];
        if (object.stateBlock) {
            object.stateBlock(CLDownloadStateRunning);
        }
    }else{
        for (AFDownloadObject *downloadObjec in self.waitingArray) {
            if (downloadObjec.stateBlock) {
                downloadObjec.stateBlock(CLDownloadStateWaiting);
            }
        }
    }
}

#pragma mark - Downloads
#pragma mark 挂起指定下载任务
- (void)suspendDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }

    if ([self.waitingArray containsObject:object]) {
        [self.waitingArray removeObject:object];
    } else {
        [object.dataTask suspend];
        [self.downloadingArray removeObject:object];
    }
    if (object.stateBlock) {
        object.stateBlock(CLDownloadStateSuspended);
    }
    
    [self toDowloadNextObject];
}

#pragma mark 挂起全部下载任务
- (void)suspendAllDownloads {
    if (self.downloadsSet.count == 0) {
        return;
    }

    if (self.waitingArray.count > 0) {
        for (AFDownloadObject *object in self.waitingArray) {
            if (object.stateBlock) {
                object.stateBlock(CLDownloadStateSuspended);
            }
        }
        [self.waitingArray removeAllObjects];
    }

    if (self.downloadingArray.count > 0) {
        for (AFDownloadObject *object in self.waitingArray) {
            [object.dataTask suspend];
            if (object.stateBlock) {
                object.stateBlock(CLDownloadStateSuspended);
            }
        }
        [self.downloadingArray removeAllObjects];
    }
}

#pragma mark 恢复指定下载任务
- (void)resumeDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }
    
    [self.waitingArray addObject:object];
    [self toDowloadNextObject];
}

#pragma mark 恢复全部下载任务
- (void)resumeAllDownloads {

    if (self.downloadsSet.count == 0) {
        return;
    }

    NSArray *downloads = self.downloadsSet.allValues;
    for (AFDownloadObject *object in downloads) {
        [self.waitingArray addObject:object];
        [self toDowloadNextObject];
    }
}

#pragma mark 删除指定下载任务
- (void)deleteDownload:(NSString *)urlString {
    NSString *encodedString = [self encodedString:urlString];
    NSURL *URL = [NSURL URLWithString:encodedString];
    if (!URL) {
        return;
    }
    AFDownloadObject *object = self.downloadsSet[CLFileName(URL)];
    if (!object) {
        return;
    }
    
    [object closeOutputStream];
    [object.dataTask cancel];
    
    if (object.stateBlock) {
        object.stateBlock(CLDownloadStateCanceling);
    }
    
    // 删除保存到数据
    if ([self.waitingArray containsObject:object]) {
        [self.waitingArray removeObject:object];
    } else {
        [self.downloadingArray removeObject:object];
    }
    [self.downloadsSet removeObjectForKey:CLFileName(URL)];
    [self deleteOneWithPlist:CLFilesPlistPath urlString:urlString];
    
    [self toDowloadNextObject];
}

#pragma mark 删除全部下载任务
- (void)deleteAllDownloads {
    if (self.downloadsSet.count == 0) {
        return;
    }
    
    NSArray *objects = self.downloadsSet.allValues;
    for (AFDownloadObject *object in objects) {
        [object closeOutputStream];
        [object.dataTask cancel];
        if (object.stateBlock) {
            object.stateBlock(CLDownloadStateCanceling);
        }
    }
    
    [self.waitingArray removeAllObjects];
    [self.downloadingArray removeAllObjects];
    [self.downloadsSet removeAllObjects];
    [self deleteAllWithPlist:CLFilesPlistPath];
}

#pragma mark - Files
#pragma mark 文件缓存目录
- (NSString *)cachesDirectory {
    NSString *defaultPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:NSStringFromClass([self class])];
    return defaultPath;
}

#pragma mark 文件绝对路径
- (NSString *)fileAbsolutePath:(NSString *)urlString {
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [NSURL URLWithString:encodedString];
    return CLFilePath(URL);
}

#pragma mark 文件是否已下载
- (BOOL)isDownloadCompleted:(NSString *)urlString {
    NSInteger totalLength = [self totalLengthWithPlist:CLFilesPlistPath urlString:urlString];
    if (totalLength != 0) {
        if (totalLength == [self downloadedLength:urlString]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark 文件已经下载的大小
- (NSUInteger)downloadedLength:(NSString *)urlString {
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:[self fileAbsolutePath:urlString] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

#pragma mark 格式化文件大小
- (NSString *)formatByteCount:(long long)size {
    return [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}

#pragma mark 转换带特殊字符的Url
- (NSString *)encodedString:(NSString *)urlString {
    return [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];;
}

#pragma mark - Lazy Loading
#pragma mark AFURLSessionManager 请求会话
- (AFURLSessionManager *)sessionManager {
    if (!_sessionManager) {
        //默认配置
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        //AFN3.0+基于封住URLSession的句柄
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        _sessionManager = manager;
    }
    return _sessionManager;
}

@end

