//
//  UIScrollView+CustomRefresh.h
//  UITableHeaderImageScale
//
//  Created by oucaizi on 15/11/25.
//  Copyright © 2015年 oucaizi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomRefreshView;

@interface UIScrollView (CustomRefresh)

typedef NS_ENUM(NSUInteger,CustomRefreshPosition)
{
    CustomRefreshPositionTop,
    CustomRefreshPositionButtom
};

@property(nonatomic,strong,readonly) CustomRefreshView *headerRefreshView;
@property(nonatomic,strong,readonly) CustomRefreshView *footerRefreshView;
@property(nonatomic,assign) BOOL showRefreshView;


-(void)addRefreshActionHandle:(void(^)(void))actionHandle position:(CustomRefreshPosition)position;



@end

@interface CustomRefreshView : UIView

/**
 *  当前view所处的状态
 */
typedef NS_ENUM(NSUInteger,CustomRefreshState){
    /**
     *  停止
     */
    CustomRefreshStateStoped,
    /**
     *  手指触发
     */
    CustomRefreshStateTrigger,
    /**
     *  加载状态
     */
    CustomRefreshStateLoading,
    /**
     *
     */
    CustomRefreshStateAll
};

@property(nonatomic,readonly) CustomRefreshState state;

-(void)beginRefresh;

-(void)endRefresh;

@end