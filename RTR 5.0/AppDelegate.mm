//  AppDelegate.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "GLESViewController.h"
#import "AboutViewController.h"

@implementation AppDelegate
{
@private
    UIWindow *window;
    UITabBarController *tabBarController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Get the screen rectangle
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    // Create window
    window = [[UIWindow alloc] initWithFrame:screenRect];
    
    // Create Assignments ViewController (Home)
    ViewController *assignmentsVC = [[ViewController alloc] init];
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:assignmentsVC];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage systemImageNamed:@"house"] tag:0];

    // Create About ViewController
    AboutViewController *aboutVC = [[AboutViewController alloc] init];
    UINavigationController *aboutNav = [[UINavigationController alloc] initWithRootViewController:aboutVC];
    aboutNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"About" image:[UIImage systemImageNamed:@"info.circle"] tag:1];

    // Create Tab Bar Controller and set view controllers
    tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:@[homeNav, aboutNav]];

    // Attach tab bar controller to window
    [window setRootViewController:tabBarController];
    
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end
