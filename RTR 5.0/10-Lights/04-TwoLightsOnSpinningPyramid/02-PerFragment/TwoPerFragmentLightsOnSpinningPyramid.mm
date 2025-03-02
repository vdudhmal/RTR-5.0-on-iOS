//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "TwoPerFragmentLightsOnSpinningPyramid.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "vmath.h"
using namespace vmath;

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_TEXTURE_COORDINATES,
    AMC_ATTRIBUTE_NORMAL
};

@implementation TwoPerFragmentLightsOnSpinningPyramid
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
    GLuint vao_pyramid;
    GLuint vbo_position_pyramid;
    GLuint vbo_normal_pyramid;

    GLuint modelMatrixUniform;
    GLuint viewMatrixUniform;
    GLuint projectionMatrixUniform;

    GLuint lightDiffusedUniform[2];
    GLuint lightPositionUniform[2];
    GLuint lightAmbientUniform[2];
    GLuint lightSpecularUniform[2];

    GLuint materialAmbientUniform;
    GLuint materialDiffusedUniform;
    GLuint materialSpecularUniform;
    GLuint materialShininessUniform;

    GLuint keyPressUniform;

    bool bLightingEnabled;
    bool bAnimationEnabled;
    int singleTap;

    mat4 perspectiveProjectionMatrix; // mat4 is in vmath.h

    float pAngle;

    // Material property
    GLfloat materialAmbient[4];
    GLfloat materialDiffused[4];
    GLfloat materialSpecular[4];
    GLfloat materialShininess;

    struct Light
    {
        vec3 ambient;
        vec3 diffused;
        vec3 specular;
        vec4 position;
    };
    struct Light light[2];
}

- (id)initWithFrame:(CGRect)frame
{
    // code
    self = [super initWithFrame:frame];
    if (self)
    {
        shaderProgramObject = 0;
        vao_pyramid = 0;
        vbo_position_pyramid = 0;
        vbo_normal_pyramid = 0;

        modelMatrixUniform = 0;
        viewMatrixUniform = 0;
        projectionMatrixUniform = 0;

        lightDiffusedUniform[0] = 0;
        lightDiffusedUniform[1] = 0;
        lightPositionUniform[0] = 0;
        lightPositionUniform[1] = 0;
        lightAmbientUniform[0] = 0;
        lightAmbientUniform[1] = 0;
        lightSpecularUniform[0] = 0;
        lightSpecularUniform[1] = 0;

        materialAmbientUniform = 0;
        materialDiffusedUniform = 0;
        materialSpecularUniform = 0;
        materialShininessUniform = 0;

        keyPressUniform = 0;

        bLightingEnabled = true;
        bAnimationEnabled = true;
        singleTap = 0;

        pAngle = 0.0f;

        materialAmbient[0] = 0.0f;
        materialAmbient[1] = 0.0f;
        materialAmbient[2] = 0.0f;
        materialAmbient[3] = 1.0f;
        materialDiffused[0] = 1.0f;
        materialDiffused[1] = 1.0f;
        materialDiffused[2] = 1.0f;
        materialDiffused[3] = 1.0f;
        materialSpecular[0] = 1.0f;
        materialSpecular[1] = 1.0f;
        materialSpecular[2] = 1.0f;
        materialSpecular[3] = 1.0f;
        materialShininess = 128.0f;

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
    if (bAnimationEnabled == true)
    {
        // update
        [self update];
    }

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
		"uniform int uKeyPress;"
		"uniform mat4 uModelMatrix;"
		"uniform mat4 uViewMatrix;"
		"uniform mat4 uProjectionMatrix;"
		"uniform vec4 uLightPositionMatrix[2];"
		"out vec3 oTransformedNormals;"
		"out vec3 oLightDirection[2];"
		"out vec3 oViewerVector;"
		"void main(void)"
		"{"
		"if (uKeyPress == 1)"
		"{"
		"vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;"
		"oTransformedNormals = mat3(uViewMatrix * uModelMatrix) * aNormal;"
		"oLightDirection[0] = vec3(uLightPositionMatrix[0] - eyeCoordinates);"
		"oLightDirection[1] = vec3(uLightPositionMatrix[1] - eyeCoordinates);"
		"oViewerVector = -eyeCoordinates.xyz;"
		"}"
		"else"
		"{"
		"oTransformedNormals = vec3(0.0f, 0.0f, 0.0f);"
		"oLightDirection[0] = vec3(0.0f, 0.0f, 0.0f);"
		"oLightDirection[1] = vec3(0.0f, 0.0f, 0.0f);"
		"oViewerVector = vec3(0.0f, 0.0f, 0.0f);"
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
        "in vec3 oTransformedNormals;"
		"in vec3 oLightDirection[2];"
		"in vec3 oViewerVector;"
		"uniform vec3 uLightAmbient[2];"
		"uniform vec3 uLightDiffused[2];"
		"uniform vec3 uLightSpecular[2];"
		"uniform vec3 uMaterialAmbient;"
		"uniform vec3 uMaterialDiffused;"
		"uniform vec3 uMaterialSpecular;"
		"uniform float uMaterialShininess;"
		"uniform int uKeyPress;"
		"out vec4 fragColor;"
		"void main(void)"
		"{"
		"vec3 phong_ADS_Light = vec3(0.0f, 0.0f, 0.0f);"
		"if (uKeyPress == 1)"
		"{"
		"vec3 reflectionVector[2];"
		"vec3 ambientLight[2];"
		"vec3 diffusedLight[2];"
		"vec3 lightSpecular[2];"
		"vec3 normalizedLightDirection[2];"
		"vec3 normalizedTransformedNormals = normalize(oTransformedNormals);"
		"vec3 normalizedViewerVector = normalize(oViewerVector);"
		"for (int i = 0; i < 2; i++)"
		"{"
		"normalizedLightDirection[i] = normalize(oLightDirection[i]);"
		"ambientLight[i] = uLightAmbient[i] * uMaterialAmbient;"
		"diffusedLight[i] = uLightDiffused[i] * uMaterialDiffused * max(dot(normalizedLightDirection[i], normalizedTransformedNormals), 0.0f);"
		"reflectionVector[i] = reflect(-normalizedLightDirection[i], normalizedTransformedNormals);"
		"lightSpecular[i] = uLightSpecular[i] * uMaterialSpecular * pow(max(dot(reflectionVector[i], normalizedViewerVector), 0.0f), uMaterialShininess);"
		"phong_ADS_Light = phong_ADS_Light + ambientLight[i] + diffusedLight[i] + lightSpecular[i];"
		"}"
		"fragColor = vec4(phong_ADS_Light, 1.0f);"
		"}"
		"else"
		"{"
		"fragColor = vec4(1.0f, 1.0f, 1.0, 1.0f);"
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
    //glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_COLOR, "aColor");
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_NORMAL, "aNormal");
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
    lightAmbientUniform[0] = glGetUniformLocation(shaderProgramObject, "uLightAmbient[0]");
    lightDiffusedUniform[0] = glGetUniformLocation(shaderProgramObject, "uLightDiffused[0]");
    lightSpecularUniform[0] = glGetUniformLocation(shaderProgramObject, "uLightSpecular[0]");
    lightPositionUniform[0] = glGetUniformLocation(shaderProgramObject, "uLightPositionMatrix[0]");
    lightAmbientUniform[1] = glGetUniformLocation(shaderProgramObject, "uLightAmbient[1]");
    lightDiffusedUniform[1] = glGetUniformLocation(shaderProgramObject, "uLightDiffused[1]");
    lightSpecularUniform[1] = glGetUniformLocation(shaderProgramObject, "uLightSpecular[1]");
    lightPositionUniform[1] = glGetUniformLocation(shaderProgramObject, "uLightPositionMatrix[1]");
    materialAmbientUniform = glGetUniformLocation(shaderProgramObject, "uMaterialAmbient");
    materialDiffusedUniform = glGetUniformLocation(shaderProgramObject, "uMaterialDiffused");
    materialSpecularUniform = glGetUniformLocation(shaderProgramObject, "uMaterialSpecular");
    materialShininessUniform = glGetUniformLocation(shaderProgramObject, "uMaterialShininess");
    keyPressUniform = glGetUniformLocation(shaderProgramObject, "uKeyPress");

    const GLfloat pyramid_position[] = {
        // front
        0.0f, 1.0f, 0.0f,   // front-top
        -1.0f, -1.0f, 1.0f, // front-left
        1.0f, -1.0f, 1.0f,  // front-right

        // right
        0.0f, 1.0f, 0.0f,   // right-top
        1.0f, -1.0f, 1.0f,  // right-left
        1.0f, -1.0f, -1.0f, // right-right

        // back
        0.0f, 1.0f, 0.0f,    // back-top
        1.0f, -1.0f, -1.0f,  // back-left
        -1.0f, -1.0f, -1.0f, // back-right

        // left
        0.0f, 1.0f, 0.0f,    // left-top
        -1.0f, -1.0f, -1.0f, // left-left
        -1.0f, -1.0f, 1.0f,  // left-right
    };
    const GLfloat pyramid_normal[] = {
        // front
        0.000000f, 0.447214f, 0.894427f, // front-top
        0.000000f, 0.447214f, 0.894427f, // front-left
        0.000000f, 0.447214f, 0.894427f, // front-right

        // right
        0.894427f, 0.447214f, 0.000000f, // right-top
        0.894427f, 0.447214f, 0.000000f, // right-left
        0.894427f, 0.447214f, 0.000000f, // right-right

        // back
        0.000000f, 0.447214f, -0.894427f, // back-top
        0.000000f, 0.447214f, -0.894427f, // back-left
        0.000000f, 0.447214f, -0.894427f, // back-right

        // left
        -0.894427f, 0.447214f, 0.000000f, // left-top
        -0.894427f, 0.447214f, 0.000000f, // left-left
        -0.894427f, 0.447214f, 0.000000f, // left-right
    };

    // vao_pyramid - vertex array object
    glGenVertexArrays(1, &vao_pyramid);
    glBindVertexArray(vao_pyramid);

    // vbo for position - vertex buffer object
    glGenBuffers(1, &vbo_position_pyramid);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_pyramid);
    glBufferData(GL_ARRAY_BUFFER, sizeof(pyramid_position), pyramid_position, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // vbo for normal - vertex buffer object
    glGenBuffers(1, &vbo_normal_pyramid);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_normal_pyramid);
    glBufferData(GL_ARRAY_BUFFER, sizeof(pyramid_normal), pyramid_normal, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // unbind vao_pyramid
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

    light[0].ambient = vec3(0.0f, 0.0f, 0.0f);
    light[1].ambient = vec3(0.0f, 0.0f, 0.0f);
    light[0].diffused = vec3(1.0f, 0.0f, 0.0f);
    light[1].diffused = vec3(0.0f, 0.0f, 1.0f);
    light[0].specular = vec3(1.0f, 0.0f, 0.0f);
    light[1].specular = vec3(0.0f, 0.0f, 1.0f);
    light[0].position = vec4(-2.0f, 0.0f, 0.0f, 1.0f);
    light[1].position = vec4(2.0f, 0.0f, 0.0f, 1.0f);

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
    
    // pyramid
    // transformations
    vmath::mat4 modelMatrix = vmath::mat4::identity();
    vmath::mat4 translationMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
    vmath::mat4 rotationMatrix1 = vmath::rotate(pAngle, -1.0f, 0.0f, 0.0f);  // Rotation around x-axis
    vmath::mat4 rotationMatrix2 = vmath::rotate(pAngle, 0.0f, -1.0f, 0.0f);  // Rotation around y-axis
    vmath::mat4 rotationMatrix3 = vmath::rotate(pAngle, 0.0f, 0.0f, -1.0f);  // Rotation around z-axis
    vmath::mat4 rotationMatrix = rotationMatrix1 * rotationMatrix2 * rotationMatrix3;
    modelMatrix = translationMatrix * rotationMatrix;
    
    mat4 viewMatrix = vmath::mat4::identity();

    // push above mvp into vertex shaders mvp uniform
    glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, modelMatrix);
    glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, viewMatrix);
    glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, perspectiveProjectionMatrix);

    if (bLightingEnabled == true)
    {
        glUniform1i(keyPressUniform, 1);
        glUniform3fv(lightAmbientUniform[0], 1, light[0].ambient);
        glUniform3fv(lightDiffusedUniform[0], 1, light[0].diffused);
        glUniform3fv(lightSpecularUniform[0], 1, light[0].specular);
        glUniform4fv(lightPositionUniform[0], 1, light[0].position);
        glUniform3fv(lightAmbientUniform[1], 1, light[1].ambient);
        glUniform3fv(lightDiffusedUniform[1], 1, light[1].diffused);
        glUniform3fv(lightSpecularUniform[1], 1, light[1].specular);
        glUniform4fv(lightPositionUniform[1], 1, light[1].position);
        glUniform3fv(materialAmbientUniform, 1, materialAmbient);
        glUniform3fv(materialDiffusedUniform, 1, materialDiffused);
        glUniform3fv(materialSpecularUniform, 1, materialSpecular);
        glUniform1f(materialShininessUniform, materialShininess);
    }
    else
    {
        glUniform1i(keyPressUniform, 0);
    }

    glBindVertexArray(vao_pyramid);
    glDrawArrays(GL_TRIANGLES, 0, 12);
    glBindVertexArray(0);

    glUseProgram(0);
}

- (void)update // NSOpenGLview update is for window resizing
{
    // code
    pAngle += 1.0f;
    if (pAngle > 360.0f)
    {
        pAngle -= 360.0f;
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

    // pyramid
    if (vbo_normal_pyramid)
    {
        glDeleteBuffers(1, &vbo_normal_pyramid);
        vbo_normal_pyramid = 0;
    }
    if (vbo_position_pyramid)
    {
        glDeleteBuffers(1, &vbo_position_pyramid);
        vbo_position_pyramid = 0;
    }
    if (vao_pyramid)
    {
        glDeleteVertexArrays(1, &vao_pyramid);
        vao_pyramid = 0;
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
    singleTap = (singleTap + 1) % 4;
    if (singleTap == 1) {
        bLightingEnabled = true;
        bAnimationEnabled = false;
    } else if (singleTap == 2) {
        bLightingEnabled = false;
        bAnimationEnabled = false;
    } else if (singleTap == 3) {
        bLightingEnabled = false;
        bAnimationEnabled = true;
    } else {
        bLightingEnabled = true;
        bAnimationEnabled = true;
    }
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
