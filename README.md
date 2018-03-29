# AFNetworkDownloadDemo
基于AFNetworking封装的下载库，实现多文件断点续传。配合YYModel实现数据显示

### 同时下载文件个数
```
/** 最大并发数，0为不限制，默认3 */
@property (nonatomic, assign) NSInteger maxConcurrentCount;
```

### 开始下载
```
/**
 下载文件
 
 @param urlString URL链接
 @param directory 文件下载完成保存的目录，如果为nil，默认保存到“.../Library/Caches/CLDownloader”
 @param state 回调-下载状态
 @param progress 回调-下载进度
 @param completion 回调-下载完成
 */
- (void)downloadURL:(NSString *)urlString
          directory:(NSString *)directory
              state:(CLDownloadStateBlock)state
           progress:(CLDownloadProgressBlock) progress
         completion:(CLDownloadCompletionBlock)completion;
```

### 获取已下载文件数据
[[AFDownloader manager] downloadObjectWithUrlString:urlString];
