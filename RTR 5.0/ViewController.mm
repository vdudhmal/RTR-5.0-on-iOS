#import "ViewController.h"
#import "GLESViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *assignments; // Top-level assignments
@property (nonatomic, strong) NSMutableSet *expandedSections; // Track expanded sections

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize the list of assignments with titles and classes
    self.assignments = @[
        @{@"title": @"1. BlueScreen", @"class": @"BlueScreen"}, // No children
        @{@"title": @"2. Orthographic Triangle", @"class": @"Ortho"}, // No children
        @{@"title": @"3. Perspective Triangle", @"children": @[
            @{@"title": @"1. Black and White", @"class": @"PerspectiveBlackAndWhiteTriangle"},
            @{@"title": @"2. Color", @"class": @"PerspectiveColorTriangle"},
        ]},
        @{@"title": @"4. Rectangle", @"children": @[
            @{@"title": @"1. Black and White", @"class": @"BlackAndWhiteRectangle"},
            @{@"title": @"2. Color", @"class": @"ColorRectangle"},
        ]},
        @{@"title": @"5. Two 2D Shapes", @"children": @[
            @{@"title": @"1. Black and White", @"class": @"TwoBlackAndWhite2DShapes"},
            @{@"title": @"2. Color", @"class": @"TwoColor2DShapes"},
        ]},
        @{@"title": @"6. 2D Rotation", @"children": @[
            @{@"title": @"1. Black and White Triangle", @"class": @"TriangleRotation"},
            @{@"title": @"2. Black and White Rectangle", @"class": @"RectangleRotation"},
            @{@"title": @"3. Black and White 2D Shapes", @"class": @"Two2DShapesRotation"},
            @{@"title": @"4. Color Triangle", @"class": @"ColorTriangleRotation"},
            @{@"title": @"5. Color Rectangle", @"class": @"ColorRectangleRotation"},
            @{@"title": @"6. Two Color 2D Shapes", @"class": @"TwoColor2DShapesRotation"},
        ]},
        @{@"title": @"7. 3D Rotation", @"children": @[
            @{@"title": @"1. Black and White Pyramid", @"class": @"PyramidRotation"},
            @{@"title": @"2. Black and White Cube", @"class": @"CubeRotation"},
            @{@"title": @"3. Two Black and White 3D Shapes", @"class": @"Two3DShapesRotation"},
            @{@"title": @"4. Color Pyramid", @"class": @"ColorPyramidRotation"},
            @{@"title": @"5. Color Cube", @"class": @"ColorCubeRotation"},
            @{@"title": @"6. Two Color 3D Shapes", @"class": @"TwoColor3DShapesRotation"},
        ]},
        @{@"title": @"8. Texture", @"children": @[
            @{@"title": @"1. Pyramid", @"class": @"TextureOnPyramid"},
            @{@"title": @"2. Cube", @"class": @"TextureOnCube"},
            @{@"title": @"3. Two 3D Shapes", @"class": @"TextureOnTwo3DShapes"},
            @{@"title": @"4. Smiley", @"class": @"SmileyTexture"},
            @{@"title": @"5. Tweaked Smiley", @"class": @"TweakedSmiley"},
            @{@"title": @"6. Checkerboard", @"class": @"Checkerboard"},
        ]},
        @{@"title": @"9. White Sphere", @"class": @"WhiteSphere"}, // No children
        @{@"title": @"10. Lights", @"children": @[
            @{@"title": @"1. Diffused Light on Pyramid", @"class": @"DiffusedLightOnPyramid"},
            @{@"title": @"2. Diffused Light on Cube", @"class": @"DiffusedLightOnCube"},
            @{@"title": @"3. Diffused Light on Sphere", @"class": @"DiffusedLightOnSphere"},
            @{@"title": @"4. Per Vertex Light On White Sphere", @"class": @"PerVertexLightOnWhiteSphere"},
            @{@"title": @"5. Per Fragment Light On White Sphere", @"class": @"PerFragmentLightOnWhiteSphere"},
            @{@"title": @"6. Per Vertex Light On Albedo Sphere", @"class": @"PerVertexLightOnAlbedoSphere"},
            @{@"title": @"7. Per Fragment Light On Albedo Sphere", @"class": @"PerFragmentLightOnAlbedoSphere"},
            @{@"title": @"8. Two Per Vertex Lights On Pyramid", @"class": @"TwoPerVertexLightsOnSpinningPyramid"},
            @{@"title": @"9. Two Per Fragment Lights On Pyramid", @"class": @"TwoPerFragmentLightsOnSpinningPyramid"},
            @{@"title": @"10. Toggle Per Vertex, Per Fragment Light", @"class": @"PerVertexPerFragmentToggle"},
            @{@"title": @"11. Three Moving Lights On Sphere", @"class": @"ThreeMovingLightsOnSphere"},
            @{@"title": @"12. Per Vertex Light On 24 spheres", @"class": @"PerVertexLightsOn24Spheres"},
            @{@"title": @"13. Per Fragment Light On 24 spheres", @"class": @"PerFragmentLightsOn24Spheres"},
        ]},
        @{@"title": @"11. Graph Paper With Shapes", @"class": @"GraphPaperWithShapes"}, // No children
        @{@"title": @"12. Push-Pop Matrix", @"children": @[
            @{@"title": @"1. Solar System", @"class": @"SolarSystem"},
            @{@"title": @"2. Robotic Arm", @"class": @"RoboticArm"},
        ]},
        @{@"title": @"13. Render To Texture", @"class": @"RenderToTexture"}, // No children
        @{@"title": @"14. Interleave", @"class": @"Interleave"}, // No children
        @{@"title": @"15. Indexed Drawing", @"class": @"IndexedDrawing"}, // No children
    ];

    self.expandedSections = [NSMutableSet set]; // Initialize the expanded sections set

    self.title = @"Home";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AssignmentCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.assignments.count; // Each entry in assignments is a section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionInfo = self.assignments[section];

    // Check if the section has children and if it is expanded
    if (sectionInfo[@"children"]) {
        if ([self.expandedSections containsObject:sectionInfo[@"title"]]) {
            return [sectionInfo[@"children"] count] + 1; // +1 for the section title
        }
        return 1; // If collapsed, just show the section title
    }
    return 1; // Assignments without children
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AssignmentCell" forIndexPath:indexPath];
    
    NSDictionary *sectionInfo = self.assignments[indexPath.section];

    if (sectionInfo[@"children"]) {
        if (indexPath.row == 0) {
            // Section title
            cell.textLabel.text = sectionInfo[@"title"];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:16]; // Make all section titles bold
            cell.indentationLevel = 0; // No indentation for section titles
        } else {
            // Assignment under section
            NSDictionary *assignmentInfo = sectionInfo[@"children"][indexPath.row - 1];
            cell.textLabel.text = assignmentInfo[@"title"]; // Set the assignment title
            cell.textLabel.font = [UIFont systemFontOfSize:15]; // Regular font for assignments
            cell.indentationLevel = 1; // Indent sub-assignments
        }
    } else {
        // Assignments without children
        cell.textLabel.text = sectionInfo[@"title"];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16]; // Make these titles bold as well
        cell.indentationLevel = 0; // No indentation for these
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *sectionInfo = self.assignments[indexPath.section];

    if (sectionInfo[@"children"]) {
        if (indexPath.row == 0) {
            // Toggle the expanded state of the section
            if ([self.expandedSections containsObject:sectionInfo[@"title"]]) {
                [self.expandedSections removeObject:sectionInfo[@"title"]]; // Collapse section
            } else {
                [self.expandedSections addObject:sectionInfo[@"title"]]; // Expand section
            }
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic]; // Reload the section to update visibility
        } else {
            // Assignment under section selected
            NSDictionary *assignmentInfo = sectionInfo[@"children"][indexPath.row - 1];
            NSString *assignmentClassName = assignmentInfo[@"class"];
            GLESViewController *glesVC = [[GLESViewController alloc] initWithClassName:assignmentClassName];
            [self.navigationController pushViewController:glesVC animated:YES];
        }
    } else {
        // Assignments without children
        GLESViewController *glesVC = [[GLESViewController alloc] initWithClassName:sectionInfo[@"class"]];
        [self.navigationController pushViewController:glesVC animated:YES];
    }
}

@end
