//
//  MyView.h
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import <UIKit/UIKit.h>

@interface ColorRectangleRotation : UIView <UIGestureRecognizerDelegate>
- (void)startDisplayLink;
- (void)stopDisplayLink;
@end
