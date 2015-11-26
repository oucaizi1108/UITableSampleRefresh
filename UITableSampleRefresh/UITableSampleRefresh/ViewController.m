//
//  ViewController.m
//  UITableHeaderImageScale
//
//  Created by oucaizi on 15/11/24.
//  Copyright © 2015年 oucaizi. All rights reserved.
//

#import "ViewController.h"
#import "UIScrollView+CustomRefresh.h"

static NSString * Identifier =@"content";


@interface ViewController (){
    NSInteger row;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.ptableView];

    __weak typeof(self) weakSelf=self;
    [self.ptableView addRefreshActionHandle:^{
        [weakSelf topRefresh];
    } position:CustomRefreshPositionTop];
 
    [self.ptableView addRefreshActionHandle:^{
        [weakSelf bottomRefresh];
    } position:CustomRefreshPositionButtom];
    
    [self.ptableView.footerRefreshView beginRefresh];
    
    row=14;
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)topRefresh{
    dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
         [self.ptableView.headerRefreshView endRefresh];
    });
    
}

-(void)bottomRefresh{
    dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
        row+=1;
        [self.ptableView.footerRefreshView endRefresh];
        [self.ptableView beginUpdates];
        [self.ptableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [self.ptableView endUpdates];
    });
}

#pragma mark 


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return row;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:Identifier];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text=[NSString stringWithFormat:@"%ld",(long)indexPath.row];
    return cell;
}




#pragma mark getter

-(UITableView*)ptableView{
    if (!_ptableView) {
        _ptableView =[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_ptableView setDataSource:self];
        [_ptableView setDelegate:self];
        [_ptableView setTableFooterView:[UIView new]];
    }
    return _ptableView;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
