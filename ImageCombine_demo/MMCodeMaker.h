//
//  MMCodeMaker.h
//  MMScanner
//
//  Created by LEA on 2017/11/23.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MMCodeMaker : NSObject

/**
 生成二维码[同步]
 
 @param qrContent 二维码内容
 @param logoImage 中间的填充图片[logo]
 @param qrColor 二维码颜色
 @param qrWidth 二维码宽度
 @return 二维码
 */
+ (UIImage *)qrImageWithContent:(NSString *)qrContent logoImage:(UIImage *)logoImage qrColor:(UIColor *)qrColor qrWidth:(CGFloat)qrWidth;

/**
 生成二维码[异步]
 
 @param qrContent 二维码内容
 @param logoImage 中间的填充图片[logo]
 @param qrColor 二维码颜色
 @param qrWidth 二维码宽度
 @param completion 完成回调
 */
+ (void)qrImageWithContent:(NSString *)qrContent logoImage:(UIImage *)logoImage qrColor:(UIColor *)qrColor qrWidth:(CGFloat)qrWidth completion:(void (^)(UIImage *image))completion;

@end
