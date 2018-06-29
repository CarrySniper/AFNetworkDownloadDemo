//
//  DownloadTableViewCell.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/8.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "DownloadTableViewCell.h"
#import "AFDownloader.h"

@implementation DownloadTableViewCell

- (void)setModel:(CommonModel *)model {
    _model = model;
    
    if (_model.isStop == YES) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    // 第二步：设置下载及回调
	
	
	// 设置下载路径。文件夹不存在的话，自己要去建。提供方法创建文件夹
	NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"MyFolder"];
	
    [[AFDownloader manager] downloadURL:_model.urlString directory:directory state:^(CLDownloadState state) {
        weakSelf.model.state = state;
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (state) {
                case CLDownloadStateRunning:{
                    weakSelf.progressLabel.text = [NSString stringWithFormat:@"%@/%@", weakSelf.model.receivedSize, weakSelf.model.expectedSize];
                    weakSelf.statusLabel.text = @"下载中";
                    [weakSelf.progressView setProgress:weakSelf.model.progress];
                    [weakSelf.button setTitle:@"暂停" forState:UIControlStateNormal];
                }
                    break;
                case CLDownloadStateWaiting:{
                    weakSelf.progressLabel.text = weakSelf.model.expectedSize;
                    weakSelf.statusLabel.text = @"等待中";
                    [weakSelf.progressView setProgress:weakSelf.model.progress];
                    [weakSelf.button setTitle:@"" forState:UIControlStateNormal];
                }
                    break;
                case CLDownloadStateSuspended:{
                    weakSelf.progressLabel.text = weakSelf.model.expectedSize;
                    weakSelf.statusLabel.text = @"暂停下载";
                    [weakSelf.progressView setProgress:weakSelf.model.progress];
                    [weakSelf.button setTitle:@"开始" forState:UIControlStateNormal];
                }
                    break;
                case CLDownloadStateCompleted:{
                    [weakSelf.button setTitle:@"" forState:UIControlStateNormal];
                }
                    break;
                default:
                    break;
            }
        });
        
    } progress:^(NSString *receivedSize, NSString *expectedSize, NSString *speed, CGFloat progress) {
        weakSelf.progressLabel.text = [NSString stringWithFormat:@"%@/%@", receivedSize, expectedSize];
        weakSelf.statusLabel.text = [NSString stringWithFormat:@"%@/S", speed];
        [weakSelf.progressView setProgress:progress];
        
        weakSelf.model.receivedSize = receivedSize;
        weakSelf.model.expectedSize = expectedSize;
        weakSelf.model.progress = progress;
    } completion:^(BOOL successful, NSString *filePath, NSError *error) {
        if (successful) {
            weakSelf.progressLabel.text = weakSelf.model.expectedSize;
            weakSelf.statusLabel.text = @"已完成";
            [weakSelf.progressView setProgress:1.0];
        }else{
            weakSelf.progressLabel.text = weakSelf.model.expectedSize;
            weakSelf.statusLabel.text = @"停止下载";
            [weakSelf.progressView setProgress:0.0];
        }
    }];
}

- (IBAction)editAction:(id)sender {
    switch (_model.state) {
        case CLDownloadStateRunning:{// 暂停
            [[AFDownloader manager] suspendDownload:_model.urlString];
            _model.isStop = YES;
            [self setModel:_model];
        }
            break;
        case CLDownloadStateWaiting:{
            
        }
            break;
        case CLDownloadStateSuspended:{// 开始
            [[AFDownloader manager] resumeDownload:_model.urlString];
            _model.isStop = NO;
            [self setModel:_model];
        }
            break;
        case CLDownloadStateCompleted:{
            
        }
            break;
        default:
            break;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
