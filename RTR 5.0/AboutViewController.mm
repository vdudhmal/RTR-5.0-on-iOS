//
//  AboutViewController.mm
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "AboutViewController.h"

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set background color
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Set navigation title
    self.navigationItem.title = @"About";

    // Create About TextView
    UITextView *aboutTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
    aboutTextView.text = @"This app demonstrates all OpenGL programmable pipeline assignments "
                          "done as part of RTR(Real Time Rendering) 5.0 course conducted by "
                          "AstroMediComp (https://www.astromedicomp.org/) from April 2023 to October 2024.\n\n"
                          "🖥️ Technologies Used:\n"
                          "Programming Language: Objective-C\n"
                          "Rendering API: OpenGL ES GLSL ES 3.00\n"
                          "Operating System: iOS\n"
                          "User Interface & Windowing: UIKit\n\n"
                          "👩‍💻 Programming by Vaishali Dudhmal.\n\n";
    aboutTextView.font = [UIFont systemFontOfSize:18];
    aboutTextView.editable = NO;
    aboutTextView.dataDetectorTypes = UIDataDetectorTypeLink;

    // Enable auto-layout
    aboutTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:aboutTextView];

    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [aboutTextView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [aboutTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [aboutTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [aboutTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];

    // Release memory (if using manual reference counting)
    [aboutTextView release];
}

@end
