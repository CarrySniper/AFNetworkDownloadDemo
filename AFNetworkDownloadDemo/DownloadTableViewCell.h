//
//  DownloadTableViewCell.h
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/8.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonModel.h"

/** 静态常量 */
static NSString *const DownloadTableViewCellIdentifier = @"DownloadTableViewCell";

@interface DownloadTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIButton *button;

@property (nonatomic, strong) CommonModel *model;

@end
