//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "DiffusedLightOnSphere.h"
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

@implementation DiffusedLightOnSphere
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
    GLuint vbo_texture_coordinates_sphere;
    GLuint vbo_element_sphere;
    GLuint vbo_normal_sphere;

    GLuint modelViewMatrixUniform;
    GLuint projectionMatrixUniform;
    GLuint ldUniform;
    GLuint kdUniform;
    GLuint lightPositionUniform;
    GLuint keyPressUniform;

    bool bLightingEnabled;
    bool bAnimationEnabled;

    GLfloat lightDiffused[4];    // = { 1.0f, 1.0f, 1.0f, 1.0f }; // white diffused light
    GLfloat materialDiffused[4]; // = { 0.5f, 0.5f, 0.5f, 1.0f };
    GLfloat lightPosition[4];    // = { 0.0f, 0.0f, 2.0f, 1.0f };

    mat4 perspectiveProjectionMatrix; // mat4 is in vmath.h
    int singleTap;
    float cAngle;
    float pAngle;

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
        bLightingEnabled = true;
        bAnimationEnabled = true;
        lightDiffused[0] = 1.0f; // white diffused light
        lightDiffused[1] = 1.0f;
        lightDiffused[2] = 1.0f;
        lightDiffused[3] = 1.0f;
        materialDiffused[0] = 0.5f;
        materialDiffused[1] = 0.5f;
        materialDiffused[2] = 0.5f;
        materialDiffused[3] = 1.0f;
        lightPosition[0] = 0.0f;
        lightPosition[1] = 0.0f;
        lightPosition[2] = 2.0f;
        lightPosition[3] = 1.0f;
        singleTap = 0;
        cAngle = 0.0;
        pAngle = 0.0;

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
        "uniform mat4 uModelViewMatrix;"
        "uniform mat4 uProjectionMatrix;"
        "uniform vec3 uLdMatrix;"
        "uniform vec3 uKdMatrix;"
        "uniform vec4 uLightPositionMatrix;"
        "uniform int uKeyPress;"
        "out vec3 oDiffusedLight;"
        "void main(void)"
        "{"
        "if(uKeyPress == 1)"
        "{"
        "vec4 eyePosition = uModelViewMatrix * aPosition;"
        "mat3 normalMatrix = mat3(transpose(inverse(uModelViewMatrix)));"
        "vec3 n = normalize(normalMatrix * aNormal);"
        "vec3 s = normalize(vec3(uLightPositionMatrix - eyePosition));"
        "oDiffusedLight = uLdMatrix * uKdMatrix * max(dot(s, n), 0.0);"
        "}"
        "else"
        "{"
        "oDiffusedLight = vec3(0.0f, 0.0f, 0.0f);"
        "}"
        "gl_Position = uProjectionMatrix * uModelViewMatrix * aPosition;"
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
        "in vec3 oDiffusedLight;"
        "uniform int uKeyPress;"
        "out vec4 fragColor;"
        "void main(void)"
        "{"
        "if (uKeyPress == 1)"
        "{"
        "fragColor = vec4(oDiffusedLight, 1.0f);"
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
    modelViewMatrixUniform = glGetUniformLocation(shaderProgramObject, "uModelViewMatrix");
    projectionMatrixUniform = glGetUniformLocation(shaderProgramObject, "uProjectionMatrix");
    ldUniform = glGetUniformLocation(shaderProgramObject, "uLdMatrix");
    kdUniform = glGetUniformLocation(shaderProgramObject, "uKdMatrix");
    lightPositionUniform = glGetUniformLocation(shaderProgramObject, "uLightPositionMatrix");
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

    mat4 translationMatrix = vmath::translate(0.0f, 0.0f, -2.0f);
    mat4 rotationMatrix1 = vmath::rotate(cAngle, 1.0f, 0.0f, 0.0f);
    mat4 rotationMatrix2 = vmath::rotate(cAngle, 0.0f, 1.0f, 0.0f);
    mat4 rotationMatrix3 = vmath::rotate(cAngle, 0.0f, 0.0f, 1.0f);
    mat4 rotationMatrix = rotationMatrix1 * rotationMatrix2 * rotationMatrix3;
    mat4 modelViewMatrix = translationMatrix * rotationMatrix;

    // transformations

    // push above mvp into vertex shaders mvp uniform
    glUniformMatrix4fv(modelViewMatrixUniform, 1, GL_FALSE, modelViewMatrix);
    glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, perspectiveProjectionMatrix);

    if (bLightingEnabled)
    {
        glUniform1i(keyPressUniform, 1);
        glUniform3fv(ldUniform, 1, lightDiffused); // shader uses vec3, though array is 4 elements, alpha is not sent, only rgb sent
        // alterative way of above line
        // glUniform3f(ldUniform, 1, { 1.0f, 1.0f, 1.0f});
        glUniform3fv(kdUniform, 1, materialDiffused);
        glUniform4fv(lightPositionUniform, 1, lightPosition);
    }
    else
    {
        glUniform1i(keyPressUniform, 0);
    }

    // bind vao
    glBindVertexArray(vao_sphere);

    // *** draw, either by glDrawTriangles() or glDrawArrays() or glDrawElements()
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere);
    glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_SHORT, 0);

    glBindVertexArray(0);

    glUseProgram(0);
}

- (void)update // NSOpenGLview update is for window resizing
{
    // code
    cAngle -= 1.0f;
    if (cAngle <= 0.0f)
    {
        cAngle += 360.0f;
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
    bLightingEnabled = !bLightingEnabled;
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
