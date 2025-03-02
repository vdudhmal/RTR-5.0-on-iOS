//  GLESViewController.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "GLESViewController.h"
//#import "GLESView.h"

@interface GLESViewController ()

@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) UIView *glesView;

@end

@implementation GLESViewController

- (instancetype)initWithClassName:(NSString *)className {
    self = [super init];
    if (self) {
        _className = className;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Get the screen rectangle
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    // Use NSClassFromString to get the class dynamically
    Class glesViewClass = NSClassFromString(self.className);
    
    if (glesViewClass) {
        // Create the GLESView instance
        self.glesView = [[glesViewClass alloc] initWithFrame:screenRect];
        [self.view addSubview:self.glesView];
        
        // Start the display link for rendering
        [self.glesView startDisplayLink];
    } else {
        NSLog(@"Class not found: %@", self.className);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Stop the display link when the view disappears
    [self.glesView stopDisplayLink];
}

@end
