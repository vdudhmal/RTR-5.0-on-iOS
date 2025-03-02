//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "PerVertexLightsOn24Spheres.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "vmath.h"
using namespace vmath;
#import "Sphere.h"

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_TEXTURE_COORDINATES,
    AMC_ATTRIBUTE_NORMAL
};

namespace perVertexLightsOn24Spheres
{
// Material property
GLfloat materialAmbient[6][4][4] =
{
    {{0.0215, 0.1745, 0.0215, 1.0f}, {0.329412, 0.223529, 0.027451, 1.0f}, {0.0, 0.0, 0.0, 1.0f}, {0.02, 0.02, 0.02, 1.0f}},
    {{0.135, 0.2225, 0.1575, 1.0f}, {0.2125, 0.1275, 0.054, 1.0f}, {0.0, 0.1, 0.06, 1.0f}, {0.0, 0.05, 0.05, 1.0f}},
    {{0.05375, 0.05, 0.06625, 1.0f}, {0.25, 0.25, 0.25, 1.0f}, {0.0, 0.0, 0.0, 1.0}, {0.0, 0.05, 0.0, 1.0}},
    {{0.25, 0.20725, 0.20725, 1.0f}, {0.19125, 0.0735, 0.0225, 1.0f}, {0.0, 0.0, 0.0, 1.0f}, {0.05, 0.0, 0.0, 1.0f}},
    {{0.1745, 0.01175, 0.01175, 1.0f}, {0.24725, 0.1995, 0.0745, 1.0f}, {0.0, 0.0, 0.0, 1.0f}, {0.05, 0.05, 0.05, 1.0f}},
    {{0.1, 0.18725, 0.1745, 1.0f}, {0.19225, 0.19225, 0.19225, 1.0f}, {0.0, 0.0, 0.0, 1.0f}, {0.05, 0.05, 0.0, 1.0f}}};
GLfloat materialDiffused[6][4][4] =
{
    {{0.07568, 0.61424, 0.07568, 1.0f}, {0.780392, 0.568627, 0.113725, 1.0f}, {0.01, 0.01, 0.01, 1.0f}, {0.01, 0.01, 0.01, 1.0f}},
    {{0.54, 0.89, 0.63, 1.0f}, {0.714, 0.4284, 0.18144, 1.0f}, {0.0, 0.50980392, 0.50980392, 1.0f}, {0.4, 0.5, 0.5, 1.0f}},
    {{0.18275, 0.17, 0.22525, 1.0f}, {0.4, 0.4, 0.4, 1.0f}, {0.1, 0.35, 0.1, 1.0f}, {0.4, 0.5, 0.4, 1.0f}},
    {{1.0, 0.829, 0.829, 1.0f}, {0.7038, 0.27048, 0.0828, 1.0f}, {0.5, 0.0, 0.0, 1.0f}, {0.5, 0.4, 0.4, 1.0f}},
    {{0.61424, 0.04136, 0.04136, 1.0f}, {0.75164, 0.60648, 0.22648, 1.0f}, {0.55, 0.55, 0.55, 1.0f}, {0.5, 0.5, 0.5, 1.0f}},
    {{0.396, 0.74151, 0.69102, 1.0f}, {0.50754, 0.50754, 0.50754, 1.0f}, {0.5, 0.5, 0.0, 1.0f}, {0.5, 0.5, 0.4, 1.0f}}};
GLfloat materialSpecular[6][4][4] =
{
    {{0.633, 0.727811, 0.633, 1.0f}, {0.992157, 0.941176, 0.807843, 1.0f}, {0.50, 0.50, 0.50, 1.0f}, {0.4, 0.4, 0.4, 1.0f}},
    {{0.316228, 0.316228, 0.316228, 1.0f}, {0.393548, 0.271906, 0.166721, 1.0f}, {0.50196078, 0.50196078, 0.50196078, 1.0f}, {0.04, 0.7, 0.7, 1.0f}},
    {{0.332741, 0.328634, 0.346435, 1.0f}, {0.774597, 0.774597, 0.774597, 1.0f}, {0.45, 0.55, 0.45, 1.0f}, {0.04, 0.7, 0.04, 1.0f}},
    {{0.296648, 0.296648, 0.296648, 1.0f}, {0.256777, 0.137622, 0.086014, 1.0f}, {0.7, 0.6, 0.6, 1.0f}, {0.7, 0.04, 0.04, 1.0f}},
    {{0.727811, 0.626959, 0.626959, 1.0f}, {0.628281, 0.555802, 0.366065, 1.0f}, {0.70, 0.70, 0.70, 1.0f}, {0.7, 0.7, 0.7, 1.0f}},
    {{0.297254, 0.30829, 0.306678, 1.0f}, {0.508273, 0.508273, 0.508273, 1.0f}, {0.60, 0.60, 0.50, 1.0f}, {0.7, 0.7, 0.04, 1.0f}}};
GLfloat materialShininess[6][4] =
{
    {0.6 * 128, 0.21794872 * 128, 0.25 * 128, 0.078125 * 128},
    {0.1 * 128, 0.2 * 128, 0.25 * 128, 0.078125 * 128},
    {0.3 * 128, 0.6 * 128, 0.25 * 128, 0.078125 * 128},
    {0.088 * 128, 0.1 * 128, 0.25 * 128, 0.078125 * 128},
    {0.6 * 128, 0.4 * 128, 0.25 * 128, 0.078125 * 128},
    {0.1 * 128, 0.4 * 128, 0.25 * 128, 0.078125 * 128}};
}
using namespace perVertexLightsOn24Spheres;

@implementation PerVertexLightsOn24Spheres
{
@private
    EAGLContext *eaglContext;
    GLuint customFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint depthRenderBuffer;
    id displayLink;
    NSInteger framesPerSecond;
    BOOL isDisplayLink;

    GLuint shaderProgramObject;
    GLuint vao_sphere;
    GLuint vbo_position_sphere;
    GLuint vbo_element_sphere;
    GLuint vbo_normal_sphere;
    GLuint vbo_texture_coordinates_sphere;
    GLuint vbo_texcoord_sphere;
    GLuint modelMatrixUniform;
    GLuint viewMatrixUniform;
    GLuint projectionMatrixUniform;

    GLuint lightDiffusedUniform;
    GLuint lightPositionUniform;
    GLuint lightAmbientUniform;
    GLuint lightSpecularUniform;

    GLuint materialAmbientUniform;
    GLuint materialDiffusedUniform;
    GLuint materialSpecularUniform;
    GLuint materialShininessUniform;

    GLuint keyPressUniform;

    GLfloat lightAmbient[4];
    GLfloat lightDiffused[4];
    GLfloat lightSpecular[4];
    GLfloat lightPosition[4];

    GLfloat lightAngleX;
    GLfloat lightAngleY;
    GLfloat lightAngleZ;
    bool bXRotationEnabled;
    bool bYRotationEnabled;
    bool bZRotationEnabled;

    bool bLightingEnabled;
    int singleTap;

    GLuint mvpMatrixUniform;

    mat4 perspectiveProjectionMatrix; // mat4 is in vmath.h

    float sAngle;

    float sphere_vertices[1146];
    float sphere_normals[1146];
    float sphere_textures[764];
    unsigned short sphere_elements[2280];
    short gNumElements;
    short gNumVertices;
}

- (id)initWithFrame:(CGRect)frame
{
    // code
    self = [super initWithFrame:frame];
    if (self)
    {
        shaderProgramObject = 0;
        vao_sphere = 0;
        vbo_position_sphere = 0;
        vbo_normal_sphere = 0;
        vbo_texcoord_sphere = 0;
        modelMatrixUniform = 0;
        viewMatrixUniform = 0;
        projectionMatrixUniform = 0;

        lightDiffusedUniform = 0;
        lightPositionUniform = 0;
        lightAmbientUniform = 0;
        lightSpecularUniform = 0;

        materialAmbientUniform = 0;
        materialDiffusedUniform = 0;
        materialSpecularUniform = 0;
        materialShininessUniform = 0;

        keyPressUniform = 0;

        lightAmbient[0] = 0.0f; // ambient light
        lightAmbient[1] = 0.0f;
        lightAmbient[2] = 0.0f;
        lightAmbient[3] = 1.0;
        lightDiffused[0] = 1.0f; // white diffused light
        lightDiffused[1] = 1.0f;
        lightDiffused[2] = 1.0f;
        lightDiffused[3] = 1.0f;
        lightSpecular[0] = 1.0f; // white specular light
        lightSpecular[1] = 1.0f;
        lightSpecular[2] = 1.0f;
        lightSpecular[3] = 1.0f;
        lightPosition[0] = 0.0f;
        lightPosition[1] = 0.0f;
        lightPosition[2] = 0.0f;
        lightPosition[3] = 1.0f;

        bLightingEnabled = true;
        singleTap = 0;

        mvpMatrixUniform = 0;

        sAngle = 0.0f;

        lightAngleX = 0.0;
        lightAngleY = 0.0;
        lightAngleZ = 0.0;
        bXRotationEnabled = false;
        bYRotationEnabled = false;
        bZRotationEnabled = false;

        // set background to black
        [self setBackgroundColor:[UIColor blackColor]];

        // create layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)[super layer];

        // make layer opaque
        [eaglLayer setOpaque:YES];

        // create dictionary
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

        // attach dictionary to layer
        [eaglLayer setDrawableProperties:dictionary];

        // create eagl context
        eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if (eaglContext == nil)
        {
            printf("OpenGLES context creation failed!\n");
            [self uninitialize];
            [self release];
            exit(0);
        }

        // set current context
        [EAGLContext setCurrentContext:eaglContext];

        // create custom framebuffer
        glGenFramebuffers(1, &customFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);

        // create color renderbuffer
        glGenRenderbuffers(1, &colorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);

        // layered rendering, give storage to color render buffer, not using opengl function but ios function
        [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];

        // assign color render buffer to framebuffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);

        // find width of color buffer
        GLint width;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);

        // find height of color buffer
        GLint height;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);

        // create depth renderbuffer
        glGenRenderbuffers(1, &depthRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);

        // give storage to depth render buffer by using opengles function
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);

        // assign depth render buffer to framebuffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);

        GLenum frameBufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (frameBufferStatus != GL_FRAMEBUFFER_COMPLETE)
        {
            printf("Framebuffer creation status is not complete!\n");
            [self uninitialize];
            [self release];
            exit(0);
        }

        // unbind framebuffer
        // glBindFramebuffer(GL_FRAMEBUFFER, 0);

        framesPerSecond = 60; // value 60 is recommened from ios 8.2
        // OpenGL deprecated from ios 12
        //
        isDisplayLink = NO;

        // call initialize
        int result = [self initialize];
        if (result != 0)
        {
            printf("Initialize failed!\n");
            [self uninitialize];
            [self release];
            exit(0);
        }

        // single tap
        UITapGestureRecognizer *singleTapGestureRecognizer = nil;
        {
            // 1 create object
            UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];

            // 2 set number of taps required
            [singleTapGestureRecognizer setNumberOfTapsRequired:1];

            // 3 set number of fingers required
            [singleTapGestureRecognizer setNumberOfTouchesRequired:1];

            // 4 set delegate
            [singleTapGestureRecognizer setDelegate:self];

            // 5 add recogniser
            [self addGestureRecognizer:singleTapGestureRecognizer];
        }

        // double tap
        {
            // 1 create object
            UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];

            // 2 set number of taps required
            [doubleTapGestureRecognizer setNumberOfTapsRequired:2];

            // 3 set number of fingers required
            [doubleTapGestureRecognizer setNumberOfTouchesRequired:1];

            // 4 set delegate
            [doubleTapGestureRecognizer setDelegate:self];

            // 5 add recogniser
            [self addGestureRecognizer:doubleTapGestureRecognizer];

            // 6
            [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        }

        // swipe
        {
            // 1 create object
            UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];

            // 2 set delegate
            [swipeGestureRecognizer setDelegate:self];

            // 3 add recogniser
            [self addGestureRecognizer:swipeGestureRecognizer];
        }

        // long press
        {
            // 1 create object
            UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];

            // 2 set delegate
            [longPressGestureRecognizer setDelegate:self];

            // 3 add recogniser
            [self addGestureRecognizer:longPressGestureRecognizer];
        }
    }

    return (self);
}

+ (Class)layerClass
{
    // code
    return [CAEAGLLayer class];
}

/*
- (void)drawRect:(CGRect)rect
{
    // code
}
*/

- (void)drawView:(id)displayLink
{
    // code

    // 1 set current context again
    [EAGLContext setCurrentContext:eaglContext];

    // 2 bind with framebuffer again
    glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);

    // 3 call renderer
    [self display];
    [self update];

    // 4 bind with color render buffer again
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);

    // 5 present color buffer, which internally does double buffering
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews
{
    // code

    // 1 bind with color render buffer again
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);

    // 2 layered rendering, give storage to color render buffer, not using opengl function but ios function
    [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)[self layer]];

    // 3
    // find width of color buffer
    GLint width;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);

    // find height of color buffer
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);

    // create depth renderbuffer
    glGenRenderbuffers(1, &depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);

    // give storage to depth render buffer by using opengles function
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);

    // assign depth render buffer to framebuffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);

    GLenum frameBufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferStatus != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("Framebuffer creation status is not complete!\n");
        [self uninitialize];
        [self release];
        exit(0);
    }

    // call resize
    [self resize:width:height];

    [self drawView:displayLink];
}

// start displayLink custom method which appdelegate will call
- (void)startDisplayLink
{
    // code
    if (isDisplayLink == NO)
    {
        // 1 create displayLink
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];

        // 2 set frames per second
        [displayLink setPreferredFramesPerSecond:framesPerSecond];

        // 3 add displayLink
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        // 4 set isDisplayLink
        isDisplayLink = YES;
    }
}

// stop displayLink custom method which appdelegate will call
- (void)stopDisplayLink
{
    // code
    if (isDisplayLink == YES)
    {
        // remove displayLink from runloop
        [displayLink invalidate];

        // set isDisplayLink
        isDisplayLink = NO;
    }
}

- (int)initialize
{
    // code
    [self printGLInfo];

    // vertex shader
    const GLchar *vertexShaderSourceCode =
        "#version 300 es"
        //"#version opengles 300"
        "\n"
        "precision mediump int;"
        "in vec4 aPosition;"
        "in vec3 aNormal;"
        "uniform vec3 uLightAmbient;"
        "uniform vec3 uLightDiffused;"
        "uniform vec3 uLightSpecular;"
        "uniform vec4 uLightPositionMatrix;"
        "uniform vec3 uMaterialAmbient;"
        "uniform vec3 uMaterialDiffused;"
        "uniform vec3 uMaterialSpecular;"
        "uniform float uMaterialShininess;"
        "uniform int uKeyPress;"
        "uniform mat4 uModelMatrix;"
        "uniform mat4 uViewMatrix;"
        "uniform mat4 uProjectionMatrix;"
        "out vec3 oPhong_ADS_Light;"
        "void main(void)"
        "{"
        "if (uKeyPress == 1)"
        "{"
        "vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;"
        "vec3 transformedNormals = normalize(mat3(uViewMatrix * uModelMatrix) * aNormal);"
        "vec3 lightDirection = normalize(vec3(uLightPositionMatrix - eyeCoordinates));"
        "vec3 reflectionVector = reflect(-lightDirection, transformedNormals);"
        "vec3 viewerVector = normalize(-eyeCoordinates.xyz);"
        "vec3 ambientLight = uLightAmbient * uMaterialAmbient;"
        "vec3 diffusedLight = uLightDiffused * uMaterialDiffused * max(dot(lightDirection, transformedNormals), 0.0f);"
        "vec3 lightSpecular = uLightSpecular * uMaterialSpecular * pow(max(dot(reflectionVector, viewerVector), 0.0f), uMaterialShininess);"
        "oPhong_ADS_Light = ambientLight + diffusedLight + lightSpecular;"
        "}"
        "else"
        "{"
        "oPhong_ADS_Light = vec3(0.0f, 0.0f, 0.0f);"
        "}"
        "gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix * aPosition;"
        "}";
    GLuint vertexShaderObject = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShaderObject, 1, (const GLchar **)&vertexShaderSourceCode, NULL);
    glCompileShader(vertexShaderObject);
    GLint status = 0;
    GLint infoLogLength = 0;
    GLchar *szInfoLog = NULL;
    glGetShaderiv(vertexShaderObject, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        glGetShaderiv(vertexShaderObject, GL_INFO_LOG_LENGTH, &infoLogLength);
        if (infoLogLength > 0)
        {
            szInfoLog = (GLchar *)malloc(infoLogLength);
            if (szInfoLog != NULL)
            {
                glGetShaderInfoLog(vertexShaderObject, infoLogLength, NULL, szInfoLog);
                printf("vertex shader compilation error log: %s\n", szInfoLog);
                free(szInfoLog);
                szInfoLog = NULL;
            }
        }
        [self uninitialize];
        [self release];
        exit(0);
    }

    // fragment shader
    const GLchar *fragmentShaderSourceCode =
        "#version 300 es"
        //"#version opengles 300"
        "\n"
        "precision mediump float;"
        "in vec3 oPhong_ADS_Light;"
        "uniform int uKeyPress;"
        "out vec4 fragColor;"
        "void main(void)"
        "{"
        "if (uKeyPress == 1)"
        "{"
        "fragColor = vec4(oPhong_ADS_Light, 1.0f);"
        "}"
        "else"
        "{"
        "fragColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);"
        "}"
        "}";
    GLuint fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShaderObject, 1, (const GLchar **)&fragmentShaderSourceCode, NULL);
    glCompileShader(fragmentShaderObject);
    status = 0;
    infoLogLength = 0;
    szInfoLog = NULL;
    glGetShaderiv(fragmentShaderObject, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        glGetShaderiv(fragmentShaderObject, GL_INFO_LOG_LENGTH, &infoLogLength);
        if (infoLogLength > 0)
        {
            szInfoLog = (GLchar *)malloc(infoLogLength);
            if (szInfoLog != NULL)
            {
                glGetShaderInfoLog(fragmentShaderObject, infoLogLength, NULL, szInfoLog);
                printf("fragment shader compilation error log: %s\n", szInfoLog);
                free(szInfoLog);
                szInfoLog = NULL;
            }
        }
        [self uninitialize];
        [self release];
        exit(0);
    }

    // Shader program
    shaderProgramObject = glCreateProgram();
    glAttachShader(shaderProgramObject, vertexShaderObject);
    glAttachShader(shaderProgramObject, fragmentShaderObject);
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_POSITION, "aPosition");
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_COLOR, "aColor");
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_NORMAL, "aNormal");
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
    glLinkProgram(shaderProgramObject);
    status = 0;
    infoLogLength = 0;
    szInfoLog = NULL;
    glGetProgramiv(shaderProgramObject, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
    {
        glGetProgramiv(shaderProgramObject, GL_INFO_LOG_LENGTH, &infoLogLength);
        if (infoLogLength > 0)
        {
            szInfoLog = (GLchar *)malloc(infoLogLength);
            if (szInfoLog != NULL)
            {
                glGetProgramInfoLog(shaderProgramObject, infoLogLength, NULL, szInfoLog);
                printf("shader program linking error log: %s\n", szInfoLog);
                free(szInfoLog);
                szInfoLog = NULL;
            }
        }
        [self uninitialize];
        [self release];
        exit(0);
    }

    // get shader uniform locations - must be after linkage
    modelMatrixUniform = glGetUniformLocation(shaderProgramObject, "uModelMatrix");
    viewMatrixUniform = glGetUniformLocation(shaderProgramObject, "uViewMatrix");
    projectionMatrixUniform = glGetUniformLocation(shaderProgramObject, "uProjectionMatrix");
    lightAmbientUniform = glGetUniformLocation(shaderProgramObject, "uLightAmbient");
    lightDiffusedUniform = glGetUniformLocation(shaderProgramObject, "uLightDiffused");
    lightSpecularUniform = glGetUniformLocation(shaderProgramObject, "uLightSpecular");
    lightPositionUniform = glGetUniformLocation(shaderProgramObject, "uLightPositionMatrix");
    materialAmbientUniform = glGetUniformLocation(shaderProgramObject, "uMaterialAmbient");
    materialDiffusedUniform = glGetUniformLocation(shaderProgramObject, "uMaterialDiffused");
    materialSpecularUniform = glGetUniformLocation(shaderProgramObject, "uMaterialSpecular");
    materialShininessUniform = glGetUniformLocation(shaderProgramObject, "uMaterialShininess");
    keyPressUniform = glGetUniformLocation(shaderProgramObject, "uKeyPress");

    Sphere *sphere = new Sphere();
    sphere->getSphereVertexData(sphere_vertices, sphere_normals, sphere_textures, sphere_elements);
    gNumVertices = sphere->getNumberOfSphereVertices();
    gNumElements = sphere->getNumberOfSphereElements();
    delete sphere;

    // vao - vertex array object
    glGenVertexArrays(1, &vao_sphere);
    glBindVertexArray(vao_sphere);

    // vbo for position - vertex buffer object
    glGenBuffers(1, &vbo_position_sphere);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_sphere);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_vertices), sphere_vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // vbo for normal
    glGenBuffers(1, &vbo_normal_sphere);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_normal_sphere);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_normals), sphere_normals, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // vbo for texture
    glGenBuffers(1, &vbo_texture_coordinates_sphere);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_texture_coordinates_sphere);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_textures), sphere_textures, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE_COORDINATES, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE_COORDINATES);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // element vbo
    glGenBuffers(1, &vbo_element_sphere);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphere_elements), sphere_elements, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // unbind vao
    glBindVertexArray(0);

    // Enable depth
    glClearDepthf(1.0);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    // Disable culling
    glDisable(GL_CULL_FACE);

    // Set the clearcolor of window to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // initialize perspectiveProjectionMatrix
    perspectiveProjectionMatrix = vmath::mat4::identity();

    // warmup
    //[self resize:WIN_WIDTH:WIN_HEIGHT];

    return (0);
}

- (void)printGLInfo
{
    // variable declarations
    GLint numExtensions;
    GLint i;

    // code
    printf("OpenGL vendor: %s\n", glGetString(GL_VENDOR));
    printf("OpenGL renderer: %s\n", glGetString(GL_RENDERER));
    printf("OpenGL version: %s\n", glGetString(GL_VERSION));
    printf("GLSL version: %s\n", glGetString(GL_SHADING_LANGUAGE_VERSION));

    // listing of supported extensions
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
    for (i = 0; i < numExtensions; i++)
    {
        printf("%s\n", glGetStringi(GL_EXTENSIONS, i));
    }
}

- (void)resize:(int)width :(int)height
{
    // code
    if (height <= 0)
    {
        height = 1;
    }

    if (width <= 0)
    {
        width = 1;
    }

    // Viewpot == binocular
    glViewport(0, 0, (GLsizei)width, (GLsizei)height);

    // set perspectives projection matrix
    perspectiveProjectionMatrix = vmath::perspective(45.0f, ((GLfloat)width / (GLfloat)height), 0.1f, 100.0f);
}

- (void)display
{
    // code
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(shaderProgramObject);
    
    for (int j = 0; j < 4; j++)
    {
        for (int i = 0; i < 6; i++)
        {
            // sphere
            mat4 translationMatrix = vmath::mat4::identity();
            translationMatrix = vmath::translate(-10.5f + 7.0f * j, 7.0f - i * 2.5f, -20.0f);
            mat4 modelMatrix = translationMatrix;
            mat4 viewMatrix = vmath::mat4::identity();

            // transformations

            // push above mvp into vertex shaders mvp uniform
            glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, modelMatrix);
            glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, viewMatrix);
            glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, perspectiveProjectionMatrix);

            if (bLightingEnabled == true)
            {
                glUniform1i(keyPressUniform, 1);
                glUniform3fv(lightAmbientUniform, 1, lightAmbient);
                glUniform3fv(lightDiffusedUniform, 1, lightDiffused);
                glUniform3fv(lightSpecularUniform, 1, lightSpecular);
                glUniform4fv(lightPositionUniform, 1, lightPosition);
                glUniform3fv(materialAmbientUniform, 1, materialAmbient[i][j]);
                glUniform3fv(materialDiffusedUniform, 1, materialDiffused[i][j]);
                glUniform3fv(materialSpecularUniform, 1, materialSpecular[i][j]);
                glUniform1f(materialShininessUniform, materialShininess[i][j]);
            }
            else
            {
                glUniform1i(keyPressUniform, 0);
            }

            // sphere
            glBindVertexArray(vao_sphere);
            // *** draw, either by glDrawTriangles() or glDrawArrays() or glDrawElements()
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere);
            glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_SHORT, 0);
            glBindVertexArray(0);
        }
    }

    glUseProgram(0);
}

- (void)update // NSOpenGLview update is for window resizing
{
    // code
    // animating lights
    if (bXRotationEnabled)
    {
        lightAngleX = lightAngleX + 0.1f;
        if (lightAngleX > 360.0f)
        {
            lightAngleX = lightAngleX - 360.0f;
        }
        lightPosition[0] = 0.0;                      // by rule
        lightPosition[1] = 45.0f * cos(lightAngleX); // one of index 1 and 2 should have value, so chosen to keep zero here
        lightPosition[2] = 45.0f * sin(lightAngleX);
        lightPosition[3] = 1.0;
    }
    if (bYRotationEnabled)
    {
        lightAngleY = lightAngleY + 0.1f;
        if (lightAngleY > 360.0f)
        {
            lightAngleY = lightAngleY - 360.0f;
        }
        lightPosition[0] = 45.0f * sin(lightAngleY);
        lightPosition[1] = 0.0;                      // by rule
        lightPosition[2] = 45.0f * cos(lightAngleY); // one of index 0 and 2 should have value, so chosen to keep zero here
        lightPosition[3] = 1.0;
    }
    if (bZRotationEnabled)
    {
        lightAngleZ = lightAngleZ + 0.1f;
        if (lightAngleZ > 360.0f)
        {
            lightAngleZ = lightAngleZ - 360.0f;
        }
        lightPosition[0] = 45.0f * cos(lightAngleZ); // one of index 0 and 1 should have value, so chosen to keep zero here
        lightPosition[1] = 45.0f * sin(lightAngleZ);
        lightPosition[2] = 0.0; // by rule
        lightPosition[3] = 1.0;
    }
}

- (void)uninitialize
{
    // code
    if (shaderProgramObject)
    {
        glUseProgram(shaderProgramObject);
        GLint numShaders = 0;
        glGetProgramiv(shaderProgramObject, GL_ATTACHED_SHADERS, &numShaders);
        if (numShaders > 0)
        {
            GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
            if (pShaders != NULL)
            {
                glGetAttachedShaders(shaderProgramObject, numShaders, NULL, pShaders);
                for (GLint i = 0; i < numShaders; i++)
                {
                    glDetachShader(shaderProgramObject, pShaders[i]);
                    glDeleteShader(pShaders[i]);
                    pShaders[i] = 0;
                }
                free(pShaders);
                pShaders = NULL;
            }
        }
        glUseProgram(0);
        glDeleteProgram(shaderProgramObject);
        shaderProgramObject = 0;
    }

    // sphere
    if (vbo_position_sphere)
    {
        glDeleteBuffers(1, &vbo_position_sphere);
        vbo_position_sphere = 0;
    }
    if (vao_sphere)
    {
        glDeleteVertexArrays(1, &vao_sphere);
        vao_sphere = 0;
    }

    if (depthRenderBuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderBuffer);
        depthRenderBuffer = 0;
    }
    if (colorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderBuffer);
        colorRenderBuffer = 0;
    }
    if (customFrameBuffer)
    {
        glDeleteFramebuffers(1, &customFrameBuffer);
        customFrameBuffer = 0;
    }

    // release eaglcontext
    if (eaglContext && [EAGLContext currentContext] == eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
        [eaglContext release];
        eaglContext = nil;
    }
}

- (BOOL)becomeFirstResponder
{
    // code
    return (YES);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // code
}

- (void)onSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    // code
    singleTap = (singleTap + 1) % 5;
    if (singleTap == 1) {
        bXRotationEnabled = true;
        bYRotationEnabled = false;
        bZRotationEnabled = false;
    } else if (singleTap == 2) {
        bXRotationEnabled = false;
        bYRotationEnabled = true;
        bZRotationEnabled = false;
    } else if (singleTap == 3) {
        bXRotationEnabled = false;
        bYRotationEnabled = false;
        bZRotationEnabled = true;
    } else if (singleTap == 4) {
        bLightingEnabled = false;
        bXRotationEnabled = false;
        bYRotationEnabled = false;
        bZRotationEnabled = false;
    } else {
        bLightingEnabled = true;
    }
    lightAngleX = 0.0f;
    lightAngleY = 0.0f;
    lightAngleZ = 0.0f;
}

- (void)onDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    // code
}

- (void)onSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    // code
    [self uninitialize];
    [self release];
    exit(0);
}

- (void)onLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    // code
}

- (void)dealloc
{
    // code
    [super dealloc];
    [self uninitialize];

    // release displayLink
    if (displayLink)
    {
        // remove from run loop
        [displayLink invalidate];

        // stop
        [displayLink stop];

        [displayLink release];
        displayLink = nil;
    }
}

@end
