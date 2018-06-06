//
//  ViewController.m
//  ImageCombine_demo
//
//  Created by Derek on 2018/6/5.
//  Copyright © 2018年 Derek. All rights reserved.
//

#import "ViewController.h"
#import "MMCodeMaker.h"

@interface ViewController ()
@property (strong, nonatomic) UIImageView *imageView;

@property(nonatomic,strong) UIImageView *qrImageView;
@property(nonatomic, copy) NSString *qrContent;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:self.imageView];
    
    //下载网络照片进行合并二维码
    // [self combineNetImage];
    
    //本地照片进行合并二维码
    //[self combineHomeImage];
    
    //生成二维码，合并图片
    [self createCodeCombineWithImage];
    
}
-(void)createCodeCombineWithImage{
    
    self.title = @"结果";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    
    self.qrContent = @"http://www.baidu.com";
    self.qrImageView.image = [MMCodeMaker qrImageWithContent:self.qrContent logoImage:[UIImage imageNamed:@"logo.jpg"] qrColor:[UIColor blackColor] qrWidth:300];
    [self.view addSubview:self.qrImageView];
    
    [self toSaveImage:self.qrImageView.image];
    
    
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 300, self.view.bounds.size.width, self.view.bounds.size.height-300)];
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.layer.borderColor = [[[UIColor lightGrayColor] colorWithAlphaComponent:0.7] CGColor];
    contentView.layer.borderWidth = 1.0;
    [self.view addSubview:contentView];
    
    UILabel *noteLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 100, 20)];
    noteLab.font = [UIFont systemFontOfSize:14.0];
    noteLab.text = @"内容：";
    noteLab.textColor = [UIColor grayColor];
    [contentView addSubview:noteLab];
    
    CGSize contentSize = [self.qrContent boundingRectWithSize:CGSizeMake(self.view.bounds.size.width-20, MAXFLOAT)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0]}
                                                      context:nil].size;
    
    UILabel *contentLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 30, self.view.bounds.size.width-20, contentSize.height+10)];
    contentLab.font = [UIFont systemFontOfSize:13.0];
    contentLab.textColor = [UIColor grayColor];
    contentLab.numberOfLines = 0;
    contentLab.text = self.qrContent;
    [contentView addSubview:contentLab];
}
-(void)combineHomeImage{
    
    //1.图片1
    UIImage *image1 = [UIImage imageNamed:@"fashion.jpg"];
    
    // 2.下载图片2
     UIImage *image2 = [UIImage imageNamed:@"code.jpeg"];
    
        // 开启一个位图上下文
        UIGraphicsBeginImageContextWithOptions(image1.size, NO, 0.0);
        
        // 绘制第1张图片
        CGFloat image1W = image1.size.width;
        CGFloat image1H = image1.size.height;
        [image1 drawInRect:CGRectMake(0, 0, image1W, image1H)];
        
        // 绘制第2张图片
        CGFloat image2W = image2.size.width * 0.5;
        CGFloat image2H = image2.size.height * 0.5;
        CGFloat image2Y = image1H - image2H;
        [image2 drawInRect:CGRectMake(image2W, image2Y - image2H, image2W, image2H)];
        
        // 得到上下文中的图片
        UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // 结束上下文
        UIGraphicsEndImageContext();
        
        // 5.回到主线程显示图片
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = fullImage;
            
            [self toSaveImage:self.imageView.image];
        });
    
}
-(void)combineNetImage{
    
    // 1.队列组
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 2.下载图片1
    __block UIImage *image1 = nil;  //要加一个 __block因为 block代码默认不能改外面的东西（记住语法即可）
    dispatch_group_async(group, queue, ^{
        NSURL *url1 = [NSURL URLWithString:@"http://g.hiphotos.baidu.com/image/pic/item/f2deb48f8c5494ee460de6182ff5e0fe99257e80.jpg"];
        NSData *data1 = [NSData dataWithContentsOfURL:url1];
        image1 = [UIImage imageWithData:data1];
    });
    
    // 3.下载图片2
    __block UIImage *image2 = nil;
    dispatch_group_async(group, queue, ^{
        NSURL *url2 = [NSURL URLWithString:@"https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=1855790068,611309659&fm=200&gp=0.jpg"];
        NSData *data2 = [NSData dataWithContentsOfURL:url2];
        image2 = [UIImage imageWithData:data2];
    });
    
    // 4.合并图片 用Quartz2D的知识，则要先要搞一个空的大图片，然后再把小图片画上去(保证执行完组里面的所有任务之后，再执行notify函数里面的block)
    //队列组：要把队列组里面的所有任务都执行完后调用dispatch_group_notify(group, queue, ^{ }
    dispatch_group_notify(group, queue, ^{
        // 开启一个位图上下文
        UIGraphicsBeginImageContextWithOptions(image1.size, NO, 0.0);
        
        // 绘制第1张图片
        CGFloat image1W = image1.size.width;
        CGFloat image1H = image1.size.height;
        [image1 drawInRect:CGRectMake(0, 0, image1W, image1H)];
        
        // 绘制第2张图片
        CGFloat image2W = image2.size.width * 0.2;
        CGFloat image2H = image2.size.height * 0.2;
        CGFloat image2Y = image1H - image2H;
        [image2 drawInRect:CGRectMake(image2W, image2Y - image2H, image2W, image2H)];
        
        // 得到上下文中的图片
        UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // 结束上下文
        UIGraphicsEndImageContext();
        
        // 5.回到主线程显示图片
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = fullImage;
            
            [self toSaveImage:self.imageView.image];
        });
    });
    
    
}
- (void)toSaveImage:(UIImage *)image {
    
    // 保存图片到相册中
    UIImageWriteToSavedPhotosAlbum(image,self, @selector(image:didFinishSavingWithError:contextInfo:),nil);
    
}
//保存图片完成之后的回调
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    // Was there an error?
    if (error != NULL)
    {
        // Show error message…
        NSLog(@"图片保存失败");
    }
    else  // No errors
    {
        // Show message image successfully saved
        NSLog(@"图片保存成功");
    }
}

#pragma mark - GETTER
- (UIImageView *)qrImageView
{
    if (!_qrImageView) {
        _qrImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-200)/2, 50, 200, 200)];
        _qrImageView.backgroundColor = [UIColor clearColor];
        _qrImageView.layer.borderWidth = 0.5;
        _qrImageView.layer.borderColor = [[[UIColor lightGrayColor] colorWithAlphaComponent:0.7] CGColor];
    }
    return _qrImageView;
}
@end
