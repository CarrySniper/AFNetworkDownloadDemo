//
//  ViewController.m
//  AFNetworkDownloadDemo
//
//  Created by CJQ on 2018/3/7.
//  Copyright © 2018年 CJQ. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloader.h"
#import "DownloadTableViewCell.h"
#import "CommonModel.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tableView.rowHeight = 70.0;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:DownloadTableViewCellIdentifier bundle:nil] forCellReuseIdentifier:DownloadTableViewCellIdentifier];
    
    //http://download.cntv.cn/cbox/mac/ysyy_v1.0.1.dmg
    //http://vrks3kssjavasdk2.ks3-cn-beijing.ksyun.com/礼物20180122/zhuantou.zip
    //@"http://7j1xh9.com1.z0.glb.clouddn.com/f86df31c9ca3e1901fbe87670338eb6b.ipa?attname=CSR201802140327QNJAQJ-resigned.ipa"
    
    // 最大并发数
    [AFDownloader manager].maxConcurrentCount = 1;
    
    NSArray *array = @[@"http://download.cntv.cn/cbox/mac/ysyy_v1.0.1.dmg",
                       @"http://vrks3kssjavasdk2.ks3-cn-beijing.ksyun.com/礼物20180122/zhuantou.zip",
                       @"http://7j1xh9.com1.z0.glb.clouddn.com/f86df31c9ca3e1901fbe87670338eb6b.ipa?attname=CSR201802140327QNJAQJ-resigned.ipa",
                       ];
    
    _dataArray = [NSMutableArray array];
    for (NSString *urlString in array) {
        [self addDownload:urlString];
    }
    [self.tableView reloadData];
}

- (void)addDownload:(NSString *)urlString {
    // Plist文件数据
    CommonModel *plistModel = [CommonModel yy_modelWithJSON:[[AFDownloader manager] downloadObjectWithUrlString:urlString]];
    
    CommonModel *model = [[CommonModel alloc]init];
    model.urlString = urlString;
    
    if (plistModel) {
        model.receivedSize = [[AFDownloader manager] formatByteCount:plistModel.downloadLength];
        model.expectedSize = [[AFDownloader manager] formatByteCount:plistModel.totalLength];
        model.progress = plistModel.progress;
    }else{
        model.receivedSize = @"0KB";
        model.expectedSize = @"0KB";
        model.progress = 0.0;
    }
    
    [_dataArray addObject:model];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak __typeof(self)weakSelf = self;
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        CommonModel *model = weakSelf.dataArray[indexPath.row];
        [weakSelf.dataArray removeObjectAtIndex:indexPath.row];
        [[AFDownloader manager] deleteDownload:model.urlString];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        
    }];
    return @[deleteAction];
}

#pragma mark - UITableView 代理事件
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DownloadTableViewCellIdentifier forIndexPath:indexPath];
   
    CommonModel *model = self.dataArray[indexPath.row];
    [cell setModel:model];
    return cell;
}

@end
