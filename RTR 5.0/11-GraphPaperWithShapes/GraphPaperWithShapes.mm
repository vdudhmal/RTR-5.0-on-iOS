//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "GraphPaperWithShapes.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "../Common/vmath.h"
using namespace vmath;

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_TEXTURE_COORDINATES,
    AMC_ATTRIBUTE_NORMAL
};

@implementation GraphPaperWithShapes
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
    GLuint vao_triangle;
	GLuint vao_square;
	GLuint vao_circle;
	GLuint vao_horizontal_line;
	GLuint vao_vertical_line;
	GLuint vbo_position_triangle;
	GLuint vbo_position_square;
	GLuint vbo_position_circle;
	GLuint vbo_position_horizontal_line;
	GLuint vbo_position_vertical_line;
    GLuint mvpMatrixUniform;
    mat4 perspectiveProjectionMatrix; // mat4 is in vmath.h
    
    bool showGraphpaper;
	bool showTriangle;
	bool showSquare;
	bool showCircle;

	// int lineCount;
    int singleTap;
}

- (id)initWithFrame:(CGRect)frame
{
    // code
    self = [super initWithFrame:frame];
    if (self)
    {
        shaderProgramObject = 0;
		vao_triangle = 0;
		vao_square = 0;
		vao_circle = 0;
		vao_horizontal_line = 0;
		vao_vertical_line = 0;
		vbo_position_triangle = 0;
		vbo_position_square = 0;
		vbo_position_circle = 0;
		vbo_position_horizontal_line = 0;
		vbo_position_vertical_line = 0;

		mvpMatrixUniform = 0;

		showGraphpaper = true;
		showTriangle = false;
		showSquare = false;
		showCircle = false;

		// lineCount = 0;
        singleTap = 0;

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
        "in vec4 aColor;"
        "uniform mat4 uMVPMatrix;"
        "out vec4 oColor;"
        "void main(void)"
        "{"
        "gl_Position = uMVPMatrix * aPosition;"
        "oColor = aColor;"
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
        "in vec4 oColor;"
        "out vec4 fragColor;"
        "void main(void)"
        "{"
        "fragColor = oColor;"
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

const GLfloat triangle_position[] = {
		0.0, 1.0, 0.0,	 // apex
		-1.0, -1.0, 0.0, // left bottom
		1.0, -1.0, 0.0}; // right bottom
	const GLfloat square_position[] = {
		1.0, 1.0, 0.0,	 // right top
		-1.0, 1.0, 0.0,	 // left top
		-1.0, -1.0, 0.0, // left bottom
		1.0, -1.0, 0.0}; // right bottom
	GLfloat circle_position[360 * 3];
	int index = 0;
	for (float angle = 0.0f; angle < 360.0f; angle++)
	{
		const GLfloat radian = angle * M_PI / 180.0f;
		const GLfloat radius = 1.0f;
		const GLfloat centerX = 0.0f, centerY = 0.0f;
		const GLfloat x = cos(radian) * radius + centerX;
		const GLfloat y = sin(radian) * radius + centerY;

		circle_position[index++] = x;
		circle_position[index++] = y;
		circle_position[index++] = 0.0f;
	}
	GLfloat horizontal_line_position[] = {
		-3.0f, 0.0f, 0.0f,
		3.0f, 0.0f, 0.0f};
	GLfloat vertical_line_position[] = {
		0.0f, -3.0f, 0.0f,
		0.0f, 3.0f, 0.0f};

	// triangle
	// vao - vertex array object
	glGenVertexArrays(1, &vao_triangle);
	glBindVertexArray(vao_triangle);

	// vbo for position - vertex buffer object
	glGenBuffers(1, &vbo_position_triangle);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_triangle);
	glBufferData(GL_ARRAY_BUFFER, sizeof(triangle_position), triangle_position, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// unbind vao
	glBindVertexArray(0);

	// square
	// vao - vertex array object
	glGenVertexArrays(1, &vao_square);
	glBindVertexArray(vao_square);

	// vbo for position - vertex buffer object
	glGenBuffers(1, &vbo_position_square);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_square);
	glBufferData(GL_ARRAY_BUFFER, sizeof(square_position), square_position, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// unbind vao
	glBindVertexArray(0);

	// circle
	// vao - vertex array object
	glGenVertexArrays(1, &vao_circle);
	glBindVertexArray(vao_circle);

	// vbo for position - vertex buffer object
	glGenBuffers(1, &vbo_position_circle);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_circle);
	glBufferData(GL_ARRAY_BUFFER, sizeof(circle_position), circle_position, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// unbind vao
	glBindVertexArray(0);

	// horizontal line
	// vao - vertex array object
	glGenVertexArrays(1, &vao_horizontal_line);
	glBindVertexArray(vao_horizontal_line);

	// vbo for position - vertex buffer object
	glGenBuffers(1, &vbo_position_horizontal_line);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_horizontal_line);
	glBufferData(GL_ARRAY_BUFFER, sizeof(horizontal_line_position), horizontal_line_position, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// unbind vao
	glBindVertexArray(0);

	// vertical line
	// vao - vertex array object
	glGenVertexArrays(1, &vao_vertical_line);
	glBindVertexArray(vao_vertical_line);

	// vbo for position - vertex buffer object
	glGenBuffers(1, &vbo_position_vertical_line);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_vertical_line);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertical_line_position), vertical_line_position, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

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

	// graph paper
	if (showGraphpaper)
	{
		// horizontal lines
		int lineCount = 0;
		for (float y = -3.0f; y < 3.0f; y += 0.0375f)
		{
			// transformations
			mat4 translationMatrix = vmath::translate(0.0f, y, -5.0f);
			mat4 modelViewMatrix = translationMatrix;

			// transformations
			mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

			// push above mvp into vertex shaders mvp uniform
			glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

			if (lineCount % 5 == 0)
			{
				glBindVertexArray(vao_horizontal_line);
				glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
				glLineWidth(2.0f);
				glDrawArrays(GL_LINES, 0, 2);
				glBindVertexArray(0);
			}
			else
			{
				glBindVertexArray(vao_horizontal_line);
				glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
				glLineWidth(0.1f);
				glDrawArrays(GL_LINES, 0, 2);
				glBindVertexArray(0);
			}
			lineCount++;
		}
		printf("No of horizontal lines = %d\n", lineCount);
		// vertical lines
		lineCount = 0;
		for (float x = -3.0f; x < 3.0f; x += 0.0375f)
		{
			// transformations
			mat4 translationMatrix = vmath::translate(x, 0.0f, -5.0f);
			mat4 modelViewMatrix = translationMatrix;

			// transformations
			mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

			// push above mvp into vertex shaders mvp uniform
			glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

			if (lineCount % 5 == 0)
			{
				glBindVertexArray(vao_vertical_line);
				glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
				glLineWidth(2.0f);
				glDrawArrays(GL_LINES, 0, 2);
				glBindVertexArray(0);
			}
			else
			{
				glBindVertexArray(vao_vertical_line);
				glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
				glLineWidth(0.1f);
				glDrawArrays(GL_LINES, 0, 2);
				glBindVertexArray(0);
			}
			lineCount++;
		}
		printf("No of vertical lines = %d\n", lineCount);

		// X-axis
		{
			mat4 modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
			mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

			// push above mvp into vertex shaders mvp uniform
			glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

			glBindVertexArray(vao_horizontal_line);
			glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 1.0f, 0.0f, 0.0f);
			glLineWidth(3.0f);
			glDrawArrays(GL_LINES, 0, 2);
			glBindVertexArray(0);
		}
		// Y-axis
		{
			mat4 modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
			mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

			// push above mvp into vertex shaders mvp uniform
			glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

			glBindVertexArray(vao_vertical_line);
			glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 1.0f, 0.0f);
			glLineWidth(3.0f);
			glDrawArrays(GL_LINES, 0, 2);
			glBindVertexArray(0);
		}
	}

	// triangle
	if (showTriangle)
	{
		// transformations
        mat4 modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);

		mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

		// push above mvp into vertex shaders mvp uniform
		glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

		glBindVertexArray(vao_triangle);
		glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 1.0f, 1.0f, 0.0f);
		glLineWidth(3.0f);
		glDrawArrays(GL_LINE_LOOP, 0, 3);
		glBindVertexArray(0);
	}

	// square
	if (showSquare)
	{
		// transformations
        mat4 modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);

		mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

		// push above mvp into vertex shaders mvp uniform
		glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

		glBindVertexArray(vao_square);
		glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 1.0f, 1.0f, 0.0f);
		glLineWidth(3.0f);
		glDrawArrays(GL_LINE_LOOP, 0, 4);
		glBindVertexArray(0);
	}

	// circle
	if (showCircle)
	{
		// transformations
        mat4 modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);

		mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix; // order of multiplication is very important

		// push above mvp into vertex shaders mvp uniform
		glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, modelViewProjectionMatrix);

		glBindVertexArray(vao_circle);
		glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 1.0f, 1.0f, 0.0f);
		glLineWidth(3.0f);
		glDrawArrays(GL_LINE_LOOP, 0, 360);
		glBindVertexArray(0);
	}

	glUseProgram(0);
}

- (void)update // NSOpenGLview update is for window resizing
{
    // code
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

// square
	if (vbo_position_square)
	{
		glDeleteBuffers(1, &vbo_position_square);
		vbo_position_square = 0;
	}
	if (vao_square)
	{
		glDeleteVertexArrays(1, &vao_square);
		vao_square = 0;
	}

	// triangle
	if (vbo_position_triangle)
	{
		glDeleteBuffers(1, &vbo_position_triangle);
		vbo_position_triangle = 0;
	}
	if (vao_triangle)
	{
		glDeleteVertexArrays(1, &vao_triangle);
		vao_triangle = 0;
	}

	// circle
	if (vbo_position_circle)
	{
		glDeleteBuffers(1, &vbo_position_circle);
		vbo_position_circle = 0;
	}
	if (vao_circle)
	{
		glDeleteVertexArrays(1, &vao_circle);
		vao_circle = 0;
	}

	// graph paper
	if (vbo_position_horizontal_line)
	{
		glDeleteBuffers(1, &vbo_position_horizontal_line);
		vbo_position_horizontal_line = 0;
	}
	if (vao_horizontal_line)
	{
		glDeleteVertexArrays(1, &vao_horizontal_line);
		vao_horizontal_line = 0;
	}
	if (vbo_position_vertical_line)
	{
		glDeleteBuffers(1, &vbo_position_vertical_line);
		vbo_position_vertical_line = 0;
	}
	if (vao_vertical_line)
	{
		glDeleteVertexArrays(1, &vao_vertical_line);
		vao_vertical_line = 0;
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
        showCircle = true;
    } else if (singleTap == 2) {
        showSquare = true;
    } else if (singleTap == 3) {
        showTriangle = true;
    } else {
        showCircle = false;
        showSquare = false;
        showTriangle = false;
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
