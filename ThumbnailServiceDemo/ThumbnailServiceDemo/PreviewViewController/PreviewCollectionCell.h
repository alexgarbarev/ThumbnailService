//
//  ImageCell.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewCollectionCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) id context;

@end
