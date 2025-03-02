//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "RenderToTexture.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "../Common/vmath.h"
using namespace vmath;
#import "../Common/Sphere.h"

enum
{
	AMC_ATTRIBUTE_POSITION = 0,
	AMC_ATTRIBUTE_COLOR,
	AMC_ATTRIBUTE_TEXTURE_COORDINATES,
	AMC_ATTRIBUTE_NORMAL
};

#define FBO_WIDTH 512
#define FBO_HEIGHT 512

@implementation RenderToTexture
{
@private
	EAGLContext *eaglContext;
	GLuint customFrameBuffer;
	GLuint colorRenderBuffer;
	GLuint depthRenderBuffer;
	id displayLink;
	NSInteger framesPerSecond;
	BOOL isDisplayLink;

	GLuint shaderProgramObject_cube;
	GLuint vao_cube;
	GLuint vbo_position_cube;
	GLuint vbo_texture_coordinates_cube;
	GLuint mvpMatrixUniform_cube;
	mat4 perspectiveProjectionMatrix_cube; // mat4 is in vmath.h

	float cAngle;

	GLint winWidth;
	GLint winHeight;

	GLuint textureSamplerUniform_cube;

	GLuint shaderProgramObject_pv_sphere;
	GLuint shaderProgramObject_pf_sphere;
	GLuint vao_sphere;
	GLuint vbo_position_sphere;
	GLuint vbo_element_sphere;
	GLuint vbo_normal_sphere;
	GLuint vbo_texcoord_sphere;
	GLuint modelMatrixUniform_sphere;
	GLuint viewMatrixUniform_sphere;
	GLuint projectionMatrixUniform_sphere;

	GLuint lightDiffusedUniform_sphere[3];
	GLuint lightPositionUniform_sphere[3];
	GLuint lightAmbientUniform_sphere[3];
	GLuint lightSpecularUniform_sphere[3];

	GLuint materialAmbientUniform_sphere;
	GLuint materialDiffusedUniform_sphere;
	GLuint materialSpecularUniform_sphere;
	GLuint materialShininessUniform_sphere;

	GLuint keyPressUniform_sphere;

	// Material property
	GLfloat materialAmbient_sphere[4];
	GLfloat materialDiffused_sphere[4];
	GLfloat materialSpecular_sphere[4];
	GLfloat materialShininess_sphere;

	bool vertexShaderEnabled;
	bool bLightingEnabled;
	int singleTap;

	mat4 perspectiveProjectionMatrix_sphere; // mat4 is in vmath.h

	GLfloat lightAngleX_sphere;
	GLfloat lightAngleY_sphere;
	GLfloat lightAngleZ_sphere;
	struct Light
	{
		vec3 ambient;
		vec3 diffused;
		vec3 specular;
		vec4 position;
	};
	struct Light light[3];

	// FBO related global variable
	GLuint FBO;
	GLuint RBO;
	GLuint texture_FBO;
	bool bFBOResult;

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
		shaderProgramObject_cube = 0;
		vao_cube = 0;
		vbo_position_cube = 0;
		vbo_texture_coordinates_cube = 0;
		mvpMatrixUniform_cube = 0;

		cAngle = 0.0;

		winWidth = 0;
		winHeight = 0;

		textureSamplerUniform_cube = 0;

		shaderProgramObject_pf_sphere = 0;
		vao_sphere = 0;
		vbo_position_sphere = 0;
		vbo_normal_sphere = 0;
		vbo_texcoord_sphere = 0;
		modelMatrixUniform_sphere = 0;
		viewMatrixUniform_sphere = 0;
		projectionMatrixUniform_sphere = 0;

		materialAmbientUniform_sphere = 0;
		materialDiffusedUniform_sphere = 0;
		materialSpecularUniform_sphere = 0;
		materialShininessUniform_sphere = 0;

		keyPressUniform_sphere = 0;

		// Material property
		materialAmbient_sphere[0] = 1.0f;
		materialAmbient_sphere[1] = 1.0f;
		materialAmbient_sphere[2] = 1.0f;
		materialAmbient_sphere[3] = 1.0f;
		materialDiffused_sphere[0] = 1.0f;
		materialDiffused_sphere[1] = 1.0f;
		materialDiffused_sphere[2] = 1.0f;
		materialDiffused_sphere[3] = 1.0f;
		materialSpecular_sphere[0] = 1.0f;
		materialSpecular_sphere[1] = 1.0f;
		materialSpecular_sphere[2] = 1.0f;
		materialSpecular_sphere[3] = 1.0f;
		materialShininess_sphere = 128.0f;

		vertexShaderEnabled = false;
		bLightingEnabled = false;
		singleTap = 0;

		lightAngleX_sphere = 0.0;
		lightAngleY_sphere = 0.0;
		lightAngleZ_sphere = 0.0;

		// FBO related global variable
		FBO = 0;
		RBO = 0;
		texture_FBO = 0;
		bFBOResult = false;

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
			[self uninitialize_cube];
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
			printf("Framebuffer creation status is not complete %s %d!\n", __func__, __LINE__);
			[self uninitialize_cube];
			[self release];
			exit(0);
		}

		// unbind framebuffer
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		framesPerSecond = 60; // value 60 is recommened from ios 8.2
		// OpenGL deprecated from ios 12
		//
		isDisplayLink = NO;

		// call initialize_cube
		int result = [self initialize_cube];
		if (result != 0)
		{
			printf("Initialize failed!\n");
			[self uninitialize_cube];
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

	// render FBO scene
	if (bFBOResult == true)
	{
		[self display_sphere:FBO_WIDTH:FBO_HEIGHT];
		[self update_sphere];
	}

	// 2 bind with framebuffer again
	glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);

	// 3 call renderer
	[self display_cube];
	[self update_cube];

	// 4 bind with color render buffer again
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);

	// 5 present color buffer, which internally does double buffering
	[eaglContext presentRenderbuffer:GL_RENDERBUFFER];

	// unbind framebuffer
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)layoutSubviews
{
	// code

	// 0 bind framebuffer
	glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);

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
		printf("Framebuffer creation status is not complete %s %d!\n", __func__, __LINE__);
		[self uninitialize_cube];
		[self release];
		exit(0);
	}

	// unbind framebuffer
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	// call resize_cube
	[self resize_cube:width:height];

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

- (int)initialize_cube
{
	// code
	[self printGLInfo];

	// vertex shader
	const GLchar *vertexShaderSourceCode_cube =
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
	GLuint vertexShaderObject_cube = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShaderObject_cube, 1, (const GLchar **)&vertexShaderSourceCode_cube, NULL);
	glCompileShader(vertexShaderObject_cube);
	GLint status = 0;
	GLint infoLogLength = 0;
	GLchar *szInfoLog = NULL;
	glGetShaderiv(vertexShaderObject_cube, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(vertexShaderObject_cube, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(vertexShaderObject_cube, infoLogLength, NULL, szInfoLog);
				printf("vertex shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_cube];
		[self release];
		exit(0);
	}

	// fragment shader
	const GLchar *fragmentShaderSourceCode_cube =
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
	GLuint fragmentShaderObject_cube = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShaderObject_cube, 1, (const GLchar **)&fragmentShaderSourceCode_cube, NULL);
	glCompileShader(fragmentShaderObject_cube);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetShaderiv(fragmentShaderObject_cube, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(fragmentShaderObject_cube, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(fragmentShaderObject_cube, infoLogLength, NULL, szInfoLog);
				printf("fragment shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_cube];
		[self release];
		exit(0);
	}

	// Shader program
	shaderProgramObject_cube = glCreateProgram();
	glAttachShader(shaderProgramObject_cube, vertexShaderObject_cube);
	glAttachShader(shaderProgramObject_cube, fragmentShaderObject_cube);
	glBindAttribLocation(shaderProgramObject_cube, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_cube, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
	glLinkProgram(shaderProgramObject_cube);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetProgramiv(shaderProgramObject_cube, GL_LINK_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_cube, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_cube, infoLogLength, NULL, szInfoLog);
				printf("shader program linking error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_cube];
		[self release];
		exit(0);
	}

	// get shader uniform locations - must be after linkage
	mvpMatrixUniform_cube = glGetUniformLocation(shaderProgramObject_cube, "uMVPMatrix");
	textureSamplerUniform_cube = glGetUniformLocation(shaderProgramObject_cube, "uTextureSampler");

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
	glGenBuffers(1, &vbo_texture_coordinates_cube);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_texture_coordinates_cube);
	glBufferData(GL_ARRAY_BUFFER, sizeof(cube_texture_coordinates), cube_texture_coordinates, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE_COORDINATES, 2, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE_COORDINATES);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// unbind vao_cube
	glBindVertexArray(0);

	// Enable depth
	glClearDepthf(1.0);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);

	// Set the clearcolor of window to black
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

	// Tell OpenGL to enable texture
	glEnable(GL_TEXTURE_2D);

	// initialize_cube perspectiveProjectionMatrix_cube
	perspectiveProjectionMatrix_cube = vmath::mat4::identity();

	// warmup
	//[self resize_cube:WIN_WIDTH:WIN_HEIGHT];

	// FBO related code
	if ([self createFBO:FBO_WIDTH:FBO_HEIGHT] == true)
	{
		bFBOResult = [self initialize_sphere:FBO_WIDTH:FBO_HEIGHT];
	}

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

- (int)initialize_sphere:(int)textureWidth :(int)textureHeight
{
	// code
	// vertex shader
	const GLchar *vertexShaderSourceCode_pv =
		"#version 300 es"
		"\n"
		"precision mediump int;"
		"in vec4 aPosition;"
		"in vec3 aNormal;"
		"uniform vec3 uLightAmbient[3];"
		"uniform vec3 uLightDiffused[3];"
		"uniform vec3 uLightSpecular[3];"
		"uniform vec4 uLightPositionMatrix[3];"
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
		"oPhong_ADS_Light = vec3(0.0f, 0.0f, 0.0f);"
		"if (uKeyPress == 1)"
		"{"
		"vec3 lightDirection[3];"
		"vec3 reflectionVector[3];"
		"vec3 ambientLight[3];"
		"vec3 diffusedLight[3];"
		"vec3 lightSpecular[3];"
		"vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;"
		"vec3 transformedNormals = normalize(mat3(uViewMatrix * uModelMatrix) * aNormal);"
		"vec3 viewerVector = normalize(-eyeCoordinates.xyz);"
		"for (int i = 0; i < 3; i++) "
		"{"
		"lightDirection[i] = normalize(vec3(uLightPositionMatrix[i] - eyeCoordinates));"
		"reflectionVector[i] = reflect(-lightDirection[i], transformedNormals);"
		"ambientLight[i] = uLightAmbient[i] * uMaterialAmbient;"
		"diffusedLight[i] = uLightDiffused[i] * uMaterialDiffused * max(dot(lightDirection[i], transformedNormals), 0.0f);"
		"lightSpecular[i] = uLightSpecular[i] * uMaterialSpecular * pow(max(dot(reflectionVector[i], viewerVector), 0.0f), uMaterialShininess);"
		"oPhong_ADS_Light = oPhong_ADS_Light + ambientLight[i] + diffusedLight[i] + lightSpecular[i];"
		"}"
		"}"
		"gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix * aPosition;"
		"}";
	GLuint vertexShaderObject_pv = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShaderObject_pv, 1, (const GLchar **)&vertexShaderSourceCode_pv, NULL);
	glCompileShader(vertexShaderObject_pv);
	GLint status = 0;
	GLint infoLogLength = 0;
	GLchar *szInfoLog = NULL;
	glGetShaderiv(vertexShaderObject_pv, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(vertexShaderObject_pv, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(vertexShaderObject_pv, infoLogLength, NULL, szInfoLog);
				printf("vertex shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

	// fragment shader
	const GLchar *fragmentShaderSourceCode_pv =
		"#version 300 es"
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
	GLuint fragmentShaderObject_pv = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShaderObject_pv, 1, (const GLchar **)&fragmentShaderSourceCode_pv, NULL);
	glCompileShader(fragmentShaderObject_pv);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetShaderiv(fragmentShaderObject_pv, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(fragmentShaderObject_pv, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(fragmentShaderObject_pv, infoLogLength, NULL, szInfoLog);
				printf("fragment shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

	// Shader program
	shaderProgramObject_pv_sphere = glCreateProgram();
	glAttachShader(shaderProgramObject_pv_sphere, vertexShaderObject_pv);
	glAttachShader(shaderProgramObject_pv_sphere, fragmentShaderObject_pv);
	glBindAttribLocation(shaderProgramObject_pv_sphere, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_pv_sphere, AMC_ATTRIBUTE_NORMAL, "aNormal");
	glBindAttribLocation(shaderProgramObject_pv_sphere, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
	glLinkProgram(shaderProgramObject_pv_sphere);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetProgramiv(shaderProgramObject_pv_sphere, GL_LINK_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_pv_sphere, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_pv_sphere, infoLogLength, NULL, szInfoLog);
				printf("shader program linking error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

	// vertex shader
	const GLchar *vertexShaderSourceCode_pf =
		"#version 300 es"
		"\n"
		"precision mediump int;"
		"in vec4 aPosition;"
		"in vec3 aNormal;"
		"uniform int uKeyPress;"
		"uniform mat4 uModelMatrix;"
		"uniform mat4 uViewMatrix;"
		"uniform mat4 uProjectionMatrix;"
		"uniform vec4 uLightPositionMatrix[3];"
		"out vec3 oTransformedNormals;"
		"out vec3 oLightDirection[3];"
		"out vec3 oViewerVector;"
		"void main(void)"
		"{"
		"if (uKeyPress == 1)"
		"{"
		"vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;"
		"oTransformedNormals = mat3(uViewMatrix * uModelMatrix) * aNormal;"
		"oLightDirection[0] = vec3(uLightPositionMatrix[0] - eyeCoordinates);"
		"oLightDirection[1] = vec3(uLightPositionMatrix[1] - eyeCoordinates);"
		"oLightDirection[2] = vec3(uLightPositionMatrix[2] - eyeCoordinates);"
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
	GLuint vertexShaderObject_pf = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShaderObject_pf, 1, (const GLchar **)&vertexShaderSourceCode_pf, NULL);
	glCompileShader(vertexShaderObject_pf);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetShaderiv(vertexShaderObject_pf, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(vertexShaderObject_pf, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(vertexShaderObject_pf, infoLogLength, NULL, szInfoLog);
				printf("vertex shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

	// fragment shader
	const GLchar *fragmentShaderSourceCode_pf =
		"#version 300 es"
		"\n"
		"precision mediump float;"
		"in vec3 oTransformedNormals;"
		"in vec3 oLightDirection[3];"
		"in vec3 oViewerVector;"
		"uniform vec3 uLightAmbient[3];"
		"uniform vec3 uLightDiffused[3];"
		"uniform vec3 uLightSpecular[3];"
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
		"vec3 reflectionVector[3];"
		"vec3 ambientLight[3];"
		"vec3 diffusedLight[3];"
		"vec3 lightSpecular[3];"
		"vec3 normalizedLightDirection[3];"
		"vec3 normalizedTransformedNormals = normalize(oTransformedNormals);"
		"vec3 normalizedViewerVector = normalize(oViewerVector);"
		"for (int i = 0; i < 3; i++)"
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
	GLuint fragmentShaderObject_pf = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShaderObject_pf, 1, (const GLchar **)&fragmentShaderSourceCode_pf, NULL);
	glCompileShader(fragmentShaderObject_pf);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetShaderiv(fragmentShaderObject_pf, GL_COMPILE_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetShaderiv(fragmentShaderObject_pf, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetShaderInfoLog(fragmentShaderObject_pf, infoLogLength, NULL, szInfoLog);
				printf("fragment shader compilation error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

	// Shader program
	shaderProgramObject_pf_sphere = glCreateProgram();
	glAttachShader(shaderProgramObject_pf_sphere, vertexShaderObject_pf);
	glAttachShader(shaderProgramObject_pf_sphere, fragmentShaderObject_pf);
	glBindAttribLocation(shaderProgramObject_pf_sphere, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_pf_sphere, AMC_ATTRIBUTE_NORMAL, "aNormal");
	glBindAttribLocation(shaderProgramObject_pf_sphere, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
	glLinkProgram(shaderProgramObject_pf_sphere);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetProgramiv(shaderProgramObject_pf_sphere, GL_LINK_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_pf_sphere, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_pf_sphere, infoLogLength, NULL, szInfoLog);
				printf("shader program linking error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize_sphere];
		[self release];
		exit(0);
	}

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

	// vbo for texture
	glGenBuffers(1, &vbo_texcoord_sphere);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoord_sphere);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_textures), sphere_textures, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE_COORDINATES, 2, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE_COORDINATES);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// vbo for normal
	glGenBuffers(1, &vbo_normal_sphere);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_normal_sphere);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_normals), sphere_normals, GL_STATIC_DRAW);
	glVertexAttribPointer(AMC_ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// element vbo
	glGenBuffers(1, &vbo_element_sphere);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphere_elements), sphere_elements, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	// unbind vao
	glBindVertexArray(0);

	// Enable depth
	glClearDepthf(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);

	// Set the clearcolor of window to black
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	// initialize_sphere perspectiveProjectionMatrix_sphere
	perspectiveProjectionMatrix_sphere = vmath::mat4::identity();

	// warmup
	//[self resize_sphere:WIN_WIDTH:WIN_HEIGHT];

	light[0].ambient = vec3(0.0f, 0.0f, 0.0f);
	light[1].ambient = vec3(0.0f, 0.0f, 0.0f);
	light[2].ambient = vec3(0.0f, 0.0f, 0.0f);
	light[0].diffused = vec3(1.0f, 0.0f, 0.0f);
	light[1].diffused = vec3(0.0f, 1.0f, 0.0f);
	light[2].diffused = vec3(0.0f, 0.0f, 1.0f);
	light[0].specular = vec3(1.0f, 0.0f, 0.0f);
	light[1].specular = vec3(0.0f, 1.0f, 0.0f);
	light[2].specular = vec3(0.0f, 0.0f, 1.0f);
	// light[0].position = vec4(-2.0f, 0.0f, 0.0f, 1.0f);
	// light[1].position = vec4(2.0f, 0.0f, 0.0f, 1.0f);
	// light[2].position = vec4(0.0f, 2.0f, 0.0f, 1.0f);

	return (true);
}

- (bool)createFBO:(GLint)textureWidth :(GLint)textureHeight
{
	// variable declarations
	GLint maxRenderBufferSize = 0;

	// check capacity of render buffer
	glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderBufferSize);
	if (maxRenderBufferSize < textureWidth || maxRenderBufferSize < textureHeight)
	{
		printf("Texture size overflow!\n");
		return false;
	}

	// create custom framebuffer
	glGenFramebuffers(1, &FBO);
	glBindFramebuffer(GL_FRAMEBUFFER, FBO);

	// create texture for FBO in which we are going to render the sphere
	glGenTextures(1, &texture_FBO);
	glBindTexture(GL_TEXTURE_2D, texture_FBO);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, textureWidth, textureHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, NULL);
	// attach above texture to framebuffer at color attachment 0
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture_FBO, 0);
	// now create render buffer to hold depth of custom FBO
	glGenRenderbuffers(1, &RBO);
	glBindRenderbuffer(GL_RENDERBUFFER, RBO);
	// set the storage of render buffer of texture size for depth
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, textureWidth, textureHeight);
	// attach above depth related FBO to depth attachment
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, RBO);
	// check the framebuffer status
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		printf("Framebuffer creation status is not complete!\n");
		return false;
	}
	// unbind framebuffer
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	return true;
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
		[self uninitialize_cube];
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

- (void)resize_cube:(int)width :(int)height
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

	winWidth = width;
	winHeight = height;

	// Viewpot == binocular
	glViewport(0, 0, (GLsizei)width, (GLsizei)height);

	// set perspectives projection matrix
	perspectiveProjectionMatrix_cube = vmath::perspective(45.0f, ((GLfloat)width / (GLfloat)height), 0.1f, 100.0f);
}

- (void)resize_sphere:(int)width :(int)height
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
	perspectiveProjectionMatrix_sphere = vmath::perspective(45.0f, ((GLfloat)width / (GLfloat)height), 0.1f, 100.0f);
}

- (void)display_cube
{
	// call resize again to compensate change by display
	[self resize_cube:winWidth:winHeight];
	// reset color white to compensate change by display sphere
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

	// code
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glUseProgram(shaderProgramObject_cube);

	// cube
	mat4 translationMatrix = vmath::translate(0.0f, 0.0f, -6.5f);
	mat4 scaleMatrix = vmath::scale(1.0f, 1.0f, 1.0f);
	mat4 rotationMatrix1 = vmath::rotate(cAngle, 1.0f, 0.0f, 0.0f);
	mat4 rotationMatrix2 = vmath::rotate(cAngle, 0.0f, 1.0f, 0.0f);
	mat4 rotationMatrix3 = vmath::rotate(cAngle, 0.0f, 0.0f, 1.0f);
	mat4 rotationMatrix = rotationMatrix1 * rotationMatrix2 * rotationMatrix3;
	mat4 modelViewMatrix = translationMatrix * scaleMatrix * rotationMatrix;

	// transformations
	mat4 modelViewProjectionMatrix = perspectiveProjectionMatrix_cube * modelViewMatrix; // order of multiplication is very important

	// push above mvp into vertex shaders mvp uniform
	glUniformMatrix4fv(mvpMatrixUniform_cube, 1, GL_FALSE, modelViewProjectionMatrix);

	// bind texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture_FBO);
	glUniform1i(textureSamplerUniform_cube, 0);

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

- (void)display_sphere:(int)textureWidth :(int)textureHeight
{
	// bind with FBO
	glBindFramebuffer(GL_FRAMEBUFFER, FBO);
	// call resize sphere
	[self resize_sphere:textureWidth:textureHeight];
	// set clear color to black again to compensate the change done by display
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	// code
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	if (!vertexShaderEnabled)
	{
		// get shader uniform locations - must be after linkage
		modelMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uModelMatrix");
		viewMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uViewMatrix");
		projectionMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uProjectionMatrix");
		lightAmbientUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightAmbient[0]");
		lightDiffusedUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightDiffused[0]");
		lightSpecularUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightSpecular[0]");
		lightPositionUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightPositionMatrix[0]");
		lightAmbientUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightAmbient[1]");
		lightDiffusedUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightDiffused[1]");
		lightSpecularUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightSpecular[1]");
		lightPositionUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightPositionMatrix[1]");
		lightAmbientUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightAmbient[2]");
		lightDiffusedUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightDiffused[2]");
		lightSpecularUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightSpecular[2]");
		lightPositionUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pf_sphere, "uLightPositionMatrix[2]");
		materialAmbientUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uMaterialAmbient");
		materialDiffusedUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uMaterialDiffused");
		materialSpecularUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uMaterialSpecular");
		materialShininessUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uMaterialShininess");
		keyPressUniform_sphere = glGetUniformLocation(shaderProgramObject_pf_sphere, "uKeyPress");

		glUseProgram(shaderProgramObject_pf_sphere);
	}
	else
	{
		modelMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uModelMatrix");
		viewMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uViewMatrix");
		projectionMatrixUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uProjectionMatrix");
		lightAmbientUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightAmbient[0]");
		lightDiffusedUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightDiffused[0]");
		lightSpecularUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightSpecular[0]");
		lightPositionUniform_sphere[0] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightPositionMatrix[0]");
		lightAmbientUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightAmbient[1]");
		lightDiffusedUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightDiffused[1]");
		lightSpecularUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightSpecular[1]");
		lightPositionUniform_sphere[1] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightPositionMatrix[1]");
		lightAmbientUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightAmbient[2]");
		lightDiffusedUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightDiffused[2]");
		lightSpecularUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightSpecular[2]");
		lightPositionUniform_sphere[2] = glGetUniformLocation(shaderProgramObject_pv_sphere, "uLightPositionMatrix[2]");
		materialAmbientUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uMaterialAmbient");
		materialDiffusedUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uMaterialDiffused");
		materialSpecularUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uMaterialSpecular");
		materialShininessUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uMaterialShininess");
		keyPressUniform_sphere = glGetUniformLocation(shaderProgramObject_pv_sphere, "uKeyPress");

		glUseProgram(shaderProgramObject_pv_sphere);
	}

	// transformations
	mat4 modelMatrix = vmath::translate(0.0f, 0.0f, -1.5f);
	mat4 viewMatrix = vmath::mat4::identity();

	// push above mvp into vertex shaders mvp uniform
	glUniformMatrix4fv(modelMatrixUniform_sphere, 1, GL_FALSE, modelMatrix);
	glUniformMatrix4fv(viewMatrixUniform_sphere, 1, GL_FALSE, viewMatrix);
	glUniformMatrix4fv(projectionMatrixUniform_sphere, 1, GL_FALSE, perspectiveProjectionMatrix_sphere);

	if (bLightingEnabled == true)
	{
		glUniform1i(keyPressUniform_sphere, 1);
		glUniform3fv(lightAmbientUniform_sphere[0], 1, light[0].ambient);
		glUniform3fv(lightDiffusedUniform_sphere[0], 1, light[0].diffused);
		glUniform3fv(lightSpecularUniform_sphere[0], 1, light[0].specular);
		glUniform4fv(lightPositionUniform_sphere[0], 1, light[0].position);
		glUniform3fv(lightAmbientUniform_sphere[1], 1, light[1].ambient);
		glUniform3fv(lightDiffusedUniform_sphere[1], 1, light[1].diffused);
		glUniform3fv(lightSpecularUniform_sphere[1], 1, light[1].specular);
		glUniform4fv(lightPositionUniform_sphere[1], 1, light[1].position);
		glUniform3fv(lightAmbientUniform_sphere[2], 1, light[2].ambient);
		glUniform3fv(lightDiffusedUniform_sphere[2], 1, light[2].diffused);
		glUniform3fv(lightSpecularUniform_sphere[2], 1, light[2].specular);
		glUniform4fv(lightPositionUniform_sphere[2], 1, light[2].position);
		glUniform3fv(materialAmbientUniform_sphere, 1, materialAmbient_sphere);
		glUniform3fv(materialDiffusedUniform_sphere, 1, materialDiffused_sphere);
		glUniform3fv(materialSpecularUniform_sphere, 1, materialSpecular_sphere);
		glUniform1f(materialShininessUniform_sphere, materialShininess_sphere);
	}
	else
	{
		glUniform1i(keyPressUniform_sphere, 0);
	}

	// sphere
	glBindVertexArray(vao_sphere);
	// *** draw, either by glDrawTriangles() or glDrawArrays() or glDrawElements()
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere);
	glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_SHORT, 0);
	glBindVertexArray(0);

	glUseProgram(0);

	// unbind framebuffer
	// unbind with FBO
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)update_cube // NSOpenGLview update_cube is for window resizing
{
	// code
	cAngle -= 1.0f;
	if (cAngle <= 0.0f)
	{
		cAngle += 360.0f;
	}
}
- (void)update_sphere // NSOpenGLview update is for window resizing
{
	// code
	// animating lights
	lightAngleX_sphere = lightAngleX_sphere + 0.05f;
	if (lightAngleX_sphere > 360.0f)
	{
		lightAngleX_sphere = lightAngleX_sphere - 360.0f;
	}
	lightAngleY_sphere = lightAngleY_sphere + 0.05f;
	if (lightAngleY_sphere > 360.0f)
	{
		lightAngleY_sphere = lightAngleY_sphere - 360.0f;
	}
	lightAngleZ_sphere = lightAngleZ_sphere + 0.05f;
	if (lightAngleZ_sphere > 360.0f)
	{
		lightAngleZ_sphere = lightAngleZ_sphere - 360.0f;
	}

	light[0].position[0] = 0.0;							   // by rule
	light[0].position[1] = 5.0f * cos(lightAngleX_sphere); // one of index 1 and 2 should have value, so chosen to keep zero here
	light[0].position[2] = 5.0f * sin(lightAngleX_sphere);
	light[0].position[3] = 1.0;
	light[1].position[0] = 5.0f * sin(lightAngleY_sphere);
	light[1].position[1] = 0.0;							   // by rule
	light[1].position[2] = 5.0f * cos(lightAngleY_sphere); // one of index 0 and 2 should have value, so chosen to keep zero here
	light[1].position[3] = 1.0;
	light[2].position[0] = 5.0f * cos(lightAngleZ_sphere); // one of index 0 and 1 should have value, so chosen to keep zero here
	light[2].position[1] = 5.0f * sin(lightAngleZ_sphere);
	light[2].position[2] = 0.0; // by rule
	light[2].position[3] = 1.0;
}
- (void)uninitialize_cube
{
	// code
	[self uninitialize_sphere];
	if (texture_FBO)
	{
		glDeleteTextures(1, &texture_FBO);
		texture_FBO = 0;
	}
	if (RBO)
	{
		glDeleteRenderbuffers(1, &RBO);
		RBO = 0;
	}
	if (FBO)
	{
		glDeleteFramebuffers(1, &FBO);
		FBO = 0;
	}
	if (shaderProgramObject_cube)
	{
		glUseProgram(shaderProgramObject_cube);
		GLint numShaders = 0;
		glGetProgramiv(shaderProgramObject_cube, GL_ATTACHED_SHADERS, &numShaders);
		if (numShaders > 0)
		{
			GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
			if (pShaders != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_cube, numShaders, NULL, pShaders);
				for (GLint i = 0; i < numShaders; i++)
				{
					glDetachShader(shaderProgramObject_cube, pShaders[i]);
					glDeleteShader(pShaders[i]);
					pShaders[i] = 0;
				}
				free(pShaders);
				pShaders = NULL;
			}
		}
		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_cube);
		shaderProgramObject_cube = 0;
	}

	// cube
	if (vbo_position_cube)
	{
		glDeleteBuffers(1, &vbo_position_cube);
		vbo_position_cube = 0;
	}
	if (vbo_texture_coordinates_cube)
	{
		glDeleteBuffers(1, &vbo_texture_coordinates_cube);
		vbo_texture_coordinates_cube = 0;
	}
	if (vao_cube)
	{
		glDeleteVertexArrays(1, &vao_cube);
		vao_cube = 0;
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

- (void)uninitialize_sphere
{
	// code
	if (shaderProgramObject_pv_sphere)
	{
		glUseProgram(shaderProgramObject_pv_sphere);
		GLint numShaders = 0;
		glGetProgramiv(shaderProgramObject_pv_sphere, GL_ATTACHED_SHADERS, &numShaders);
		if (numShaders > 0)
		{
			GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
			if (pShaders != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_pv_sphere, numShaders, NULL, pShaders);
				for (GLint i = 0; i < numShaders; i++)
				{
					glDetachShader(shaderProgramObject_pv_sphere, pShaders[i]);
					glDeleteShader(pShaders[i]);
					pShaders[i] = 0;
				}
				free(pShaders);
				pShaders = NULL;
			}
		}
		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_pv_sphere);
		shaderProgramObject_pv_sphere = 0;
	}
	if (shaderProgramObject_pf_sphere)
	{
		glUseProgram(shaderProgramObject_pf_sphere);
		GLint numShaders = 0;
		glGetProgramiv(shaderProgramObject_pf_sphere, GL_ATTACHED_SHADERS, &numShaders);
		if (numShaders > 0)
		{
			GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
			if (pShaders != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_pf_sphere, numShaders, NULL, pShaders);
				for (GLint i = 0; i < numShaders; i++)
				{
					glDetachShader(shaderProgramObject_pf_sphere, pShaders[i]);
					glDeleteShader(pShaders[i]);
					pShaders[i] = 0;
				}
				free(pShaders);
				pShaders = NULL;
			}
		}
		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_pf_sphere);
		shaderProgramObject_pf_sphere = 0;
	}

	// sphere
	if (vbo_position_sphere)
	{
		glDeleteBuffers(1, &vbo_position_sphere);
		vbo_position_sphere = 0;
	}
	if (vbo_texcoord_sphere)
	{
		glDeleteBuffers(1, &vbo_texcoord_sphere);
		vbo_texcoord_sphere = 0;
	}
	if (vbo_normal_sphere)
	{
		glDeleteBuffers(1, &vbo_normal_sphere);
		vbo_normal_sphere = 0;
	}
	if (vao_sphere)
	{
		glDeleteVertexArrays(1, &vao_sphere);
		vao_sphere = 0;
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
	singleTap = (singleTap + 1) % 3;
	if (singleTap == 1)
	{
		bLightingEnabled = true;
		vertexShaderEnabled = true;
	}
	else if (singleTap == 2)
	{
		bLightingEnabled = true;
		vertexShaderEnabled = false;
	}
	else
	{
		bLightingEnabled = false;
	}
}

- (void)onDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
	// code
}

- (void)onSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
	// code
	[self uninitialize_cube];
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
	[self uninitialize_cube];

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
