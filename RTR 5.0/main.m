//
//  main.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char *argv[])
{
    // code

    // create autorelease pool for memory management
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Get the appdelegate class name as string
    NSString *appDelegateClassName = NSStringFromClass([AppDelegate class]);
    int result = UIApplicationMain(argc, argv, nil, appDelegateClassName);

    // let autorelease pool release all pending objects in our application
    [pool release];

    return (result);
}
