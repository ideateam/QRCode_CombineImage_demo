//
//  MMCodeMaker.m
//  MMScanner
//
//  Created by LEA on 2017/11/23.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMCodeMaker.h"

@implementation MMCodeMaker


#pragma mark - 二维码生成[含有logo]
+ (UIImage *)qrImageWithContent:(NSString *)qrContent logoImage:(UIImage *)logoImage qrColor:(UIColor *)qrColor qrWidth:(CGFloat)qrWidth
{
    //1、通过滤镜生成二维码
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [qrContent dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *image = [filter outputImage];
    //2、改变生成的图片的大小
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(qrWidth/CGRectGetWidth(extent), qrWidth/CGRectGetHeight(extent));
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    //3、获取
    UIImage *qrImage = [UIImage imageWithCGImage:scaledImage];
    //4、设置颜色
    if (qrColor) {
        CGFloat red = 0.0;
        CGFloat green = 0.0;
        CGFloat blue = 0.0;
        CGFloat alpha = 0.0;
        [qrColor getRed:&red green:&green blue:&blue alpha:&alpha];
        qrImage = [self qrcodeImage:qrImage red:red green:green blue:blue];
    }
    //5、填充中间的图片
    if (logoImage) {
        qrImage = [self qrcodeImage:qrImage logoImage:logoImage];
    }
    return qrImage;
}

+ (void)qrImageWithContent:(NSString *)qrContent logoImage:(UIImage *)logoImage qrColor:(UIColor *)qrColor qrWidth:(CGFloat)qrWidth completion:(void (^)(UIImage *image))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [self qrImageWithContent:qrContent logoImage:logoImage qrColor:qrColor qrWidth:qrWidth];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(image);
            }
        });
    });
}

#pragma mark - 通用方法
+ (UIImage *)qrcodeImage:(UIImage *)qrImage logoImage:(UIImage *)logoImage
{
    //1.二维码图片size/rect
    CGSize qrSize = qrImage.size;
    CGRect qrRect = CGRectMake(0, 0, qrSize.width, qrSize.height);
    //2.logo图片size/rect
    CGSize logoSize = CGSizeMake(qrSize.width/4, qrSize.width/4);
    CGRect logoRect = CGRectMake((qrSize.width-logoSize.width)/2, (qrSize.height-logoSize.height)/2, logoSize.width, logoSize.height);
    //3.获取白色背景圆角logo图
    logoImage = [self clipCornerRadius:logoImage maxSize:logoSize];
    //4.绘制
    UIGraphicsBeginImageContextWithOptions(qrSize, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);{
        CGContextTranslateCTM(context, 0, qrSize.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextDrawImage(context, qrRect, qrImage.CGImage);
        CGContextDrawImage(context, logoRect, logoImage.CGImage);
    }CGContextRestoreGState(context);
    //5.获取合成后的图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)clipCornerRadius:(UIImage *)image maxSize:(CGSize)size
{
    //1.设置外侧留白宽度
    CGFloat margin = size.width/15.0;
    //2.圆角
    CGFloat radius = size.width/5.0;
    //3.为context创建rect
    CGRect fillRect = CGRectMake(0, 0, size.width, size.height);
    //4.设置rect
    CGFloat fillOrigin = margin/2.0;
    CGFloat logoOrigin =  fillOrigin/1.2;
    CGRect outerRect = CGRectInset(fillRect, fillOrigin, fillOrigin);
    CGRect innerRect = CGRectInset(outerRect, logoOrigin, logoOrigin);
    //5.path
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:outerRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(outerRect.size.width/5.0, outerRect.size.width/5.0)];
    //6.绘制
    UIColor *fillColor = [UIColor whiteColor];
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);{
        CGContextTranslateCTM(context, 0, size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextAddPath(context, fillPath.CGPath);
        CGContextClip(context);
        CGContextAddPath(context, fillPath.CGPath);
        CGContextSetFillColorWithColor(context, fillColor.CGColor);
        CGContextFillPath(context);
        CGContextDrawImage(context, innerRect, image.CGImage);
        CGContextAddPath(context, outerPath.CGPath);
        CGContextSetStrokeColorWithColor(context, fillColor.CGColor);
        CGContextSetLineWidth(context, margin);
        CGContextStrokePath(context);
    }CGContextRestoreGState(context);
    //7.获取图片
    UIImage *radiusImage  = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return radiusImage;
}

// 设置颜色
+ (UIImage *)qrcodeImage:(UIImage *)qrImage red:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    const int imageWidth = qrImage.size.width;
    const int imageHeight = qrImage.size.height;
    
    size_t bytesPerRow = imageWidth * 4;
    uint32_t *rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), qrImage.CGImage);
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        // 改变二维码颜色
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red*255.0;
            ptr[2] = green*255.0;
            ptr[1] = blue*255.0;
        }
    }
    // 输出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage *resultUIImage = [UIImage imageWithCGImage:imageRef];
    // 清理空间
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}

void ProviderReleaseData (void *info, const void *data, size_t size)
{
    free((void *)data);
}

@end
