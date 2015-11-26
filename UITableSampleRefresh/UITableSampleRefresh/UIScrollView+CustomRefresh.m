

//
//  UIScrollView+CustomRefresh.m
//  UITableHeaderImageScale
//
//  Created by oucaizi on 15/11/25.
//  Copyright © 2015年 oucaizi. All rights reserved.
//

#import "UIScrollView+CustomRefresh.h"
#import <objc/runtime.h>

@interface CustomRefreshView ()

/**
 *  kvo监听当前视图是否处于监听状态
 */
@property(nonatomic,assign) BOOL isObserving;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, weak) UIScrollView *scrollView;///当前视图的父视图
@property(nonatomic,readwrite) CustomRefreshPosition position;
@property(nonatomic,strong,readonly) UIActivityIndicatorView *HudView;
@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@end



static CGFloat const RefreshViewHeight = 50;
static const char *refreshViewKeyHeader ;
static const char *refreshViewKeyFooter ;

@implementation UIScrollView (CustomRefresh)
@dynamic headerRefreshView,showRefreshView,footerRefreshView;

-(void)addRefreshActionHandle:(void(^)(void))actionHandle position:(CustomRefreshPosition)position{
    
    CGFloat yOrigin;
    
    switch (position) {
        case CustomRefreshPositionTop:
            yOrigin=-RefreshViewHeight;
            break;
        case CustomRefreshPositionButtom:
            yOrigin=self.contentSize.height;
            break;
        default:
            break;
    }
    
    CustomRefreshView *view=[[CustomRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, CGRectGetWidth(self.bounds), RefreshViewHeight)];
    [view setBackgroundColor:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1]];
    view.originalTopInset=self.contentInset.top;
    view.originalBottomInset=self.contentInset.bottom;
    view.pullToRefreshActionHandler=actionHandle;
    view.scrollView=self;
    view.position=position;
    if (position==CustomRefreshPositionTop) {
        self.headerRefreshView=view;
        [self.headerRefreshView setTag:1000];
        [self addSubview:self.headerRefreshView];
    }else{
        self.footerRefreshView=view;
        [self.footerRefreshView setTag:1001];
        [self addSubview:self.footerRefreshView];
    }
    
    self.showRefreshView = YES;
    
}


#pragma mark setter/getter

//类别中增加方法用runtime重新合成属性
-(void)setHeaderRefreshView:(CustomRefreshView *)headerRefreshView{
    objc_setAssociatedObject(self, &refreshViewKeyHeader, headerRefreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CustomRefreshView*)headerRefreshView{
    return   objc_getAssociatedObject(self, &refreshViewKeyHeader);
}

-(void)setFooterRefreshView:(CustomRefreshView *)footerRefreshView{
    objc_setAssociatedObject(self, &refreshViewKeyFooter, footerRefreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CustomRefreshView*)footerRefreshView{
    return   objc_getAssociatedObject(self, &refreshViewKeyFooter);
}

-(void)setShowRefreshView:(BOOL)showRefreshView{
    if (showRefreshView) {
        //self.refreshView 作为kvo观察者
        
        if (!self.headerRefreshView.isObserving) {
            [self addObserver:self.headerRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.headerRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
           
            self.headerRefreshView.isObserving=YES;
        }
        if (!self.footerRefreshView.isObserving) {
            [self addObserver:self.footerRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.footerRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
           
            self.footerRefreshView.isObserving=YES;
        }
        
    }else{
        
        if (self.headerRefreshView.isObserving) {
            [self removeObserver:self.headerRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.headerRefreshView forKeyPath:@"contentSize" ];
           
            self.headerRefreshView.isObserving=NO;
        }
        if (self.footerRefreshView.isObserving) {
            [self removeObserver:self.footerRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.footerRefreshView forKeyPath:@"contentSize" ];
         
            self.footerRefreshView.isObserving=NO;
        }
    }
    
}

- (void)dealloc
{
    if (self.headerRefreshView.isObserving) {
        [self removeObserver:self.headerRefreshView forKeyPath:@"contentOffset"];
        [self removeObserver:self.headerRefreshView forKeyPath:@"contentSize" ];
     
    }
    if (self.footerRefreshView.isObserving) {
        [self removeObserver:self.footerRefreshView forKeyPath:@"contentOffset"];
        [self removeObserver:self.footerRefreshView forKeyPath:@"contentSize" ];
      
    }
}

@end

@implementation CustomRefreshView

@synthesize state=_state;
@synthesize position=_position;
@synthesize HudView=_HudView;
@synthesize pullToRefreshActionHandler;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.state=CustomRefreshStateStoped;// 初始状态为停止状态
        self.HudView.center=CGPointMake(self.center.x, CGRectGetHeight(self.bounds)/2);
        
    }
    return self;
}

-(void)willMoveToSuperview:(UIView *)newSuperview{
    if (self.superview&&newSuperview==nil) {
        UIScrollView *scrollView=(UIScrollView *)self.superview;
        if (scrollView.showRefreshView) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if ([keyPath isEqualToString:@"contentSize"])
    {
        CGFloat yOrigin;
        switch (self.position) {
            case CustomRefreshPositionTop:
                yOrigin = -RefreshViewHeight;
                break;
            case CustomRefreshPositionButtom:
            {
                yOrigin=self.scrollView.contentSize.height;
            }
                break;
        }
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, RefreshViewHeight);
       
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/**
 *  通过offset来确定当前view的状态
 */
- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    
    // 处于非loading状态,loading状态不会执行
    if (self.state!=CustomRefreshStateLoading) {
        CGFloat scrollOffsetThreshold=0; ///滑动的阈值
        
        switch (self.position) {
            case CustomRefreshPositionTop:
                scrollOffsetThreshold=self.frame.origin.y-self.originalTopInset;
                break;
            case CustomRefreshPositionButtom:
                scrollOffsetThreshold=MAX(self.scrollView.contentSize.height-CGRectGetHeight(self.scrollView.bounds), 0)+self.originalBottomInset+self.bounds.size.height;
                break;
            default:
                break;
        }
        /** 特别注意由于滑动的过程中top和bottom同时处于监听状态
         *  此处的逻辑乃是核心，以下来慢慢阐述
         *  下拉:分两种情况:拖动的距离未达到刷新位置，且状态为非stop状态,释放手指，要将状态置为stop,如果拖动距离达到刷新位置，释放手指，并且当前状态为stop状态，释放手指将状态设置为triger状态,两种状态在释放手指后如果为triger状态则，进入loading状态、
         *  上拉，原理同下拉
         */
        if (!self.scrollView.isDragging&&(self.state==CustomRefreshStateTrigger)) {
            self.state=CustomRefreshStateLoading;
        }else if ((contentOffset.y>=scrollOffsetThreshold)&&(self.state!=CustomRefreshStateStoped)&&(self.position==CustomRefreshPositionTop)&&(contentOffset.y<=0)){
            self.state=CustomRefreshStateStoped;
        }else if ((contentOffset.y<scrollOffsetThreshold)&&(self.state==CustomRefreshStateStoped)&&(self.position==CustomRefreshPositionTop)&&(contentOffset.y<=0)){
            self.state=CustomRefreshStateTrigger;
        }else if ((contentOffset.y<=scrollOffsetThreshold)&&(self.state!=CustomRefreshStateStoped)&&(self.position==CustomRefreshPositionButtom)&&(contentOffset.y>=0)){
            self.state=CustomRefreshStateStoped;
        }else if((contentOffset.y>scrollOffsetThreshold)&&(self.state==CustomRefreshStateStoped)&&(self.position==CustomRefreshPositionButtom)&&(contentOffset.y>=0)){
            self.state=CustomRefreshStateTrigger;
        }
        
    }else{ ///处于loading状态
        
    }
}

-(void)setState:(CustomRefreshState)state{
    _state=state;
    switch (_state) {
        case CustomRefreshStateStoped:
            [self resetScrollViewContentInset];
            break;
        case CustomRefreshStateLoading:
        {
            [self setScrollViewContentInsetForLoading];
            if (self.pullToRefreshActionHandler) {
                self.pullToRefreshActionHandler();
            }
        }
            break;
        default:
            break;
    }
}

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case CustomRefreshPositionTop:
            currentInsets.top = self.originalTopInset;
            break;
        case CustomRefreshPositionButtom:
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
            break;
    }
    [self setScrollViewContentInset:currentInsets];
    
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset;
    UIEdgeInsets currentInsets = self.scrollView.contentInset;

    switch (self.position) {
        case CustomRefreshPositionTop:
            offset = MAX(self.scrollView.contentOffset.y * -1, 0);
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
         
            break;
        case CustomRefreshPositionButtom:
            
            currentInsets.bottom = self.frame.size.height;
        
            break;
    }
    [self setScrollViewContentInset:currentInsets];
    [self.HudView startAnimating];
    
    switch (self.position) {
        case CustomRefreshPositionTop:
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.bounds.size.height) animated:YES];
            break;
        case CustomRefreshPositionButtom:
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height) animated:YES];
            break;
        default:
            break;
    }
    
    
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                         
                     }
                     completion:NULL];
}

/**
 *  开始加载刷新动画
 */
-(void)beginRefresh{
    self.state=CustomRefreshStateLoading;
}

/**
 *  停止加载刷新动画
 */
-(void)endRefresh{
    
    self.state=CustomRefreshStateStoped;
    [self.HudView stopAnimating];
    switch (self.position) {
        case CustomRefreshPositionTop:
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            break;
        case CustomRefreshPositionButtom:
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x,  MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.originalBottomInset) animated:YES];
            break;
        default:
            break;
    }

}

#pragma mark getter
-(UIActivityIndicatorView*)HudView{
    if(!_HudView) {
        _HudView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _HudView.hidesWhenStopped = YES;
        [self addSubview:_HudView];
    }
    return _HudView;
}

@end

