//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "TextureOnTwo3DShapes.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "../../Common/vmath.h"
using namespace vmath;

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_TEXTURE_COORDINATES,
    AMC_ATTRIBUTE_NORMAL
};

@implementation TextureOnTwo3DShapes
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
    GLuint vbo_texture_coordinates_pyramid;
    GLuint vao_cube;
    GLuint vbo_position_cube;
    GLuint vbo_color_cube;
    GLuint mvpMatrixUniform;
    mat4 perspectiveProjectionMatrix; // mat4 is in vmath.h

    GLuint textureSamplerUniform;
    GLuint texture_stone;
    GLuint texture_kundali;

    float pAngle;
    float cAngle;
}

- (id)initWithFrame:(CGRect)frame
{
    // code
    self = [super initWithFrame:frame];
    if (self)
    {
        pAngle = 0.0f;
        cAngle = 0.0f;
        
        textureSamplerUniform = 0;
        texture_stone = 0;
        texture_kundali = 0;
        
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
        "in vec4 aPosition;"
        "in vec2 aTextureCoordinates;"
        "uniform mat4 uMVPMatrix;"
        "out vec2 oTextureCoordinates;"
        "void main(void)"
        "{"
        "gl_Position = uMVPMatrix * aPosition;"
        "oTextureCoordinates = aTextureCoordinates;"
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
        "in vec2 oTextureCoordinates;"
        "uniform sampler2D uTextureSampler;"
        "out vec4 fragColor;"
        "void main(void)"
        "{"
        "fragColor = texture(uTextureSampler, oTextureCoordinates);"
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
    mvpMatrixUniform = glGetUniformLocation(shaderProgramObject, "uMVPMatrix");
    textureSamplerUniform = glGetUniformLocation(shaderProgramObject, "uTextureSampler");

	const GLfloat pyramid_position[] = {
		// front
		0.0f, 1.0f, 0.0f,
		-1.0f, -1.0f, 1.0f,
		1.0f, -1.0f, 1.0f,

		// right
		0.0f, 1.0f, 0.0f,
		1.0f, -1.0f, 1.0f,
		1.0f, -1.0f, -1.0f,

		// back
		0.0f, 1.0f, 0.0f,
		1.0f, -1.0f, -1.0f,
		-1.0f, -1.0f, -1.0f,

		// left
		0.0f, 1.0f, 0.0f,
		-1.0f, -1.0f, -1.0f,
		-1.0f, -1.0f, 1.0f};
	const GLfloat pyramid_texture_coordinates[] = {
		// front
		0.5, 1.0, // front-top
		0.0, 0.0, // front-left
		1.0, 0.0, // front-right

		// right
		0.5, 1.0, // right-top
		1.0, 0.0, // right-left
		0.0, 0.0, // right-right

		// back
		0.5, 1.0, // back-top
		0.0, 0.0, // back-left
		1.0, 0.0, // back-right

		// left
		0.5, 1.0, // left-top
		1.0, 0.0, // left-left
		0.0, 0.0, // left-right
	};
	const GLfloat cube_position[] = {
		// top
		1.0f, 1.0f, -1.0f,
		-1.0f, 1.0f, -1.0f,
		-1.0f, 1.0f, 1.0f,
		1.0f, 1.0f, 1.0f,

		// bottom
		1.0f, -1.0f, -1.0f,
		-1.0f, -1.0f, -1.0f,
		-1.0f, -1.0f, 1.0f,
		1.0f, -1.0f, 1.0f,

		// front
		1.0f, 1.0f, 1.0f,
		-1.0f, 1.0f, 1.0f,
		-1.0f, -1.0f, 1.0f,
		1.0f, -1.0f, 1.0f,

		// back
		1.0f, 1.0f, -1.0f,
		-1.0f, 1.0f, -1.0f,
		-1.0f, -1.0f, -1.0f,
		1.0f, -1.0f, -1.0f,

		// right
		1.0f, 1.0f, -1.0f,
		1.0f, 1.0f, 1.0f,
		1.0f, -1.0f, 1.0f,
		1.0f, -1.0f, -1.0f,

		// left
		-1.0f, 1.0f, 1.0f,
		-1.0f, 1.0f, -1.0f,
		-1.0f, -1.0f, -1.0f,
		-1.0f, -1.0f, 1.0f};
	const GLfloat cube_texture_coordinates[] = {
		// front
		1.0f, 1.0f, // top-right of front
		0.0f, 1.0f, // top-left of front
		0.0f, 0.0f, // bottom-left of front
		1.0f, 0.0f, // bottom-right of front

		// right
		1.0f, 1.0f, // top-right of right
		0.0f, 1.0f, // top-left of right
		0.0f, 0.0f, // bottom-left of right
		1.0f, 0.0f, // bottom-right of right

		// back
		1.0f, 1.0f, // top-right of back
		0.0f, 1.0f, // top-left of back
		0.0f, 0.0f, // bottom-left of back
		1.0f, 0.0f, // bottom-right of back

		// left
		1.0f, 1.0f, // top-right of left
		0.0f, 1.0f, // top-left of left
		0.0f, 0.0f, // bottom-left of left
		1.0f, 0.0f, // bottom-right of left

		// top
		1.0f, 1.0f, // top-right of top
		0.0f, 1.0f, // top-left of top
		0.0f, 0.0f, // bottom-left of top
		1.0f, 0.0f, // bottom-right of top

		// bottom
		1.0f, 1.0f, // top-right of bottom
		0.0f, 1.0f, // top-left of bottom
		0.0f, 0.0f, // bottom-left of bottom
		1.0f, 0.0f, // bottom-right of bottom
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

    // vbo for color - vertex buffer object
    glGenBuffers(1, &vbo_texture_coordinates_pyramid);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_texture_coordinates_pyramid);
    glBufferData(GL_ARRAY_BUFFER, sizeof(pyramid_texture_coordinates), pyramid_texture_coordinates, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE_COORDINATES, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE_COORDINATES);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // unbind vao_pyramid
    glBindVertexArray(0);

    // vao_cube - vertex array object
    glGenVertexArrays(1, &vao_cube);
    glBindVertexArray(vao_cube);

    // vbo for position - vertex buffer object
    glGenBuffers(1, &vbo_position_cube);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_cube);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cube_position), cube_position, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // vbo for color - vertex buffer object
    glGenBuffers(1, &vbo_color_cube);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_color_cube);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cube_texture_coordinates), cube_texture_coordinates, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE_COORDINATES, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE_COORDINATES);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // unbind vao_cube
    glBindVertexArray(0);

    // loading images to create texture
	texture_stone = [self loadGLTexture:@"Stone":@"bmp"];
	texture_kundali = [self loadGLTexture:@"Kundali":@"png"];

	// Tell OpenGL to enable texture
	glEnable(GL_TEXTURE_2D);

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

- (GLuint)loadGLTexture:(NSString *)szImageFileName :(NSString *)extension
{
    // code
    // step 1
    NSString *imageFileNameWithPath = [[NSBundle mainBundle] pathForResource:szImageFileName ofType:extension];

    // step 2
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imageFileNameWithPath];
    if (image == nil)
    {
        printf("Creating image failed!\n");
        [self uninitialize];
        [self release];
        exit(0);
    }

    // step 3
    CGImageRef cgImage = [image CGImage];

    // step 4
    int imageWidth = (int)CGImageGetWidth(cgImage);
    int imageHeight = (int)CGImageGetHeight(cgImage);

    // step 5
    CGDataProviderRef imageDataProviderRef = CGImageGetDataProvider(cgImage);
    CFDataRef imageDataRef = CGDataProviderCopyData(imageDataProviderRef);

    // step 6
    const unsigned char *imageData = CFDataGetBytePtr(imageDataRef);

    GLuint texture = 0;

    // Create image texture
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    // set texture parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    // create multiple MIPMAP images
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    glGenerateMipmap(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, 0);

    // step 7
    CFRelease(imageDataRef);

    return texture;
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

    // transformation
    mat4 translationMatrix = vmath::translate(-1.75f, 0.0f, -6.5f);
    mat4 rotationMatrix1 = vmath::rotate(pAngle, -1.0f, 0.0f, 0.0f);
    mat4 rotationMatrix2 = vmath::rotate(pAngle, 0.0f, -1.0f, 0.0f);
    mat4 rotationMatrix3 = vmath::rotate(pAngle, 0.0f, 0.0f, -1.0f);
    mat4 rotationMatrix = rotationMatrix1 * rotationMatrix2 * rotationMatrix3;
    mat4 modelViewMatrix = translationMatrix * rotationMatrix;
    mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

    // push above mvp into vertex shaders mvp uniform
    glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

    // bind texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture_stone);
	glUniform1i(textureSamplerUniform, 0);

    glBindVertexArray(vao_pyramid);
    glDrawArrays(GL_TRIANGLES, 0, 12);
    glBindVertexArray(0);

	glBindTexture(GL_TEXTURE_2D, 0);

    // transformation
    translationMatrix = vmath::translate(1.75f, 0.0f, -6.5f);
    rotationMatrix1 = vmath::rotate(cAngle, 1.0f, 0.0f, 0.0f);
    rotationMatrix2 = vmath::rotate(cAngle, 0.0f, 1.0f, 0.0f);
    rotationMatrix3 = vmath::rotate(cAngle, 0.0f, 0.0f, 1.0f);
    rotationMatrix = rotationMatrix1 * rotationMatrix2 * rotationMatrix3;
    modelViewMatrix = translationMatrix * rotationMatrix;
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

    // push above mvp into vertex shaders mvp uniform
    glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);
    
    // bind texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture_kundali);
	glUniform1i(textureSamplerUniform, 0);

    glBindVertexArray(vao_cube);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 4, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 8, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 12, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 16, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 20, 4);
    glBindVertexArray(0);

	glBindTexture(GL_TEXTURE_2D, 0);

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
    cAngle -= 1.0f;
    if (cAngle <= 0.0f)
    {
        cAngle += 360.0f;
    }
}

- (void)uninitialize
{
    // code
    if (texture_kundali)
	{
		glDeleteTextures(1, &texture_kundali);
		texture_kundali = 0;
	}
	if (texture_stone)
	{
		glDeleteTextures(1, &texture_stone);
		texture_stone = 0;
	}
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

    // cube
    if (vbo_color_cube)
    {
        glDeleteBuffers(1, &vbo_color_cube);
        vbo_color_cube = 0;
    }
    if (vbo_position_cube)
    {
        glDeleteBuffers(1, &vbo_position_cube);
        vbo_position_cube = 0;
    }
    if (vao_cube)
    {
        glDeleteVertexArrays(1, &vao_cube);
        vao_cube = 0;
    }

    // pyramid
    if (vbo_texture_coordinates_pyramid)
    {
        glDeleteBuffers(1, &vbo_texture_coordinates_pyramid);
        vbo_texture_coordinates_pyramid = 0;
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
