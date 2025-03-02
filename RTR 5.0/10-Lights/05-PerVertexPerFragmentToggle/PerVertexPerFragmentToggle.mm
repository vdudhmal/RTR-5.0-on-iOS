//
//  MyView.m
//  OpenGLES
//
//  Created by V D on 04/08/2024.
//

#import "PerVertexPerFragmentToggle.h"
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

@implementation PerVertexPerFragmentToggle
{
@private
	EAGLContext *eaglContext;
	GLuint customFrameBuffer;
	GLuint colorRenderBuffer;
	GLuint depthRenderBuffer;
	id displayLink;
	NSInteger framesPerSecond;
	BOOL isDisplayLink;

	GLuint shaderProgramObject_pv;
	GLuint shaderProgramObject_pf;
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

	// Material property
	GLfloat materialAmbientWhite[4];
	GLfloat materialDiffusedWhite[4];
	GLfloat materialSpecularWhite[4];
	GLfloat materialShininessWhite;
	GLfloat materialAmbientAlbedo[4];
	GLfloat materialDiffusedAlbedo[4];
	GLfloat materialSpecularAlbedo[4];
	GLfloat materialShininessAlbedo;

	bool bLightingEnabled;
	bool vertexShaderEnabled;
	bool whiteMaterial;
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
		shaderProgramObject_pf = 0;
		shaderProgramObject_pv = 0;
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

		lightAmbient[0] = 0.1f; // ambient light
		lightAmbient[1] = 0.1f;
		lightAmbient[2] = 0.1f;
		lightAmbient[3] = 1.0;
		lightDiffused[0] = 1.0f; // white diffused light
		lightDiffused[1] = 1.0f;
		lightDiffused[2] = 1.0f;
		lightDiffused[3] = 1.0f;
		lightSpecular[0] = 1.0f; // white specular light
		lightSpecular[1] = 1.0f;
		lightSpecular[2] = 1.0f;
		lightSpecular[3] = 1.0f;
		lightPosition[0] = 100.0f;
		lightPosition[1] = 100.0f;
		lightPosition[2] = 100.0f;
		lightPosition[3] = 1.0f;

		// Material property
		materialAmbientWhite[0] = 1.0f;
		materialAmbientWhite[1] = 1.0f;
		materialAmbientWhite[2] = 1.0f;
		materialAmbientWhite[3] = 1.0f;
		materialDiffusedWhite[0] = 1.0f;
		materialDiffusedWhite[1] = 1.0f;
		materialDiffusedWhite[2] = 1.0f;
		materialDiffusedWhite[3] = 1.0f;
		materialSpecularWhite[0] = 1.0f;
		materialSpecularWhite[1] = 1.0f;
		materialSpecularWhite[2] = 1.0f;
		materialSpecularWhite[3] = 1.0f;
		materialShininessWhite = 128.0f;
		materialAmbientAlbedo[0] = 0.0f;
		materialAmbientAlbedo[1] = 0.0f;
		materialAmbientAlbedo[2] = 0.0f;
		materialAmbientAlbedo[3] = 1.0f;
		materialDiffusedAlbedo[0] = 0.5f;
		materialDiffusedAlbedo[1] = 0.2f;
		materialDiffusedAlbedo[2] = 0.7f;
		materialDiffusedAlbedo[3] = 1.0f;
		materialSpecularAlbedo[0] = 0.7f;
		materialSpecularAlbedo[1] = 0.7f;
		materialSpecularAlbedo[2] = 0.7f;
		materialSpecularAlbedo[3] = 1.0f;
		materialShininessAlbedo = 128.0f;

		bLightingEnabled = false;
		vertexShaderEnabled = false;
		whiteMaterial = false;
		singleTap = 0;

		mvpMatrixUniform = 0;

		sAngle = 0.0f;

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
	const GLchar *vertexShaderSourceCode_pv =
		"#version 300 es"
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
		[self uninitialize];
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
		[self uninitialize];
		[self release];
		exit(0);
	}

	// Shader program
	shaderProgramObject_pv = glCreateProgram();
	glAttachShader(shaderProgramObject_pv, vertexShaderObject_pv);
	glAttachShader(shaderProgramObject_pv, fragmentShaderObject_pv);
	glBindAttribLocation(shaderProgramObject_pv, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_pv, AMC_ATTRIBUTE_NORMAL, "aNormal");
	// glBindAttribLocation(shaderProgramObject_pv, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
	glLinkProgram(shaderProgramObject_pv);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetProgramiv(shaderProgramObject_pv, GL_LINK_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_pv, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_pv, infoLogLength, NULL, szInfoLog);
				printf("shader program linking error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize];
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
		"uniform vec4 uLightPositionMatrix;"
		"out vec3 oTransformedNormals;"
		"out vec3 oLightDirection;"
		"out vec3 oViewerVector;"
		"void main(void)"
		"{"
		"if (uKeyPress == 1)"
		"{"
		"vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;"
		"oTransformedNormals = mat3(uViewMatrix * uModelMatrix) * aNormal;"
		"oLightDirection = vec3(uLightPositionMatrix - eyeCoordinates);"
		"oViewerVector = -eyeCoordinates.xyz;"
		"}"
		"else"
		"{"
		"oTransformedNormals = vec3(0.0f, 0.0f, 0.0f);"
		"oLightDirection = vec3(0.0f, 0.0f, 0.0f);"
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
		[self uninitialize];
		[self release];
		exit(0);
	}

	// fragment shader
	const GLchar *fragmentShaderSourceCode_pf =
		"#version 300 es"
		"\n"
		"precision mediump float;"
		"in vec3 oTransformedNormals;"
		"in vec3 oLightDirection;"
		"in vec3 oViewerVector;"
		"uniform vec3 uLightAmbient;"
		"uniform vec3 uLightDiffused;"
		"uniform vec3 uLightSpecular;"
		"uniform vec3 uMaterialAmbient;"
		"uniform vec3 uMaterialDiffused;"
		"uniform vec3 uMaterialSpecular;"
		"uniform float uMaterialShininess;"
		"uniform int uKeyPress;"
		"out vec4 fragColor;"
		"void main(void)"
		"{"
		"if (uKeyPress == 1)"
		"{"
		"vec3 normalizedTransformedNormals = normalize(oTransformedNormals);"
		"vec3 normalizedLightDirection = normalize(oLightDirection);"
		"vec3 normalizedViewerVector = normalize(oViewerVector);"
		"vec3 ambientLight = uLightAmbient * uMaterialAmbient;"
		"vec3 diffusedLight = uLightDiffused * uMaterialDiffused * max(dot(normalizedLightDirection, normalizedTransformedNormals), 0.0f);"
		"vec3 reflectionVector = reflect(-normalizedLightDirection, normalizedTransformedNormals);"
		"vec3 lightSpecular = uLightSpecular * uMaterialSpecular * pow(max(dot(reflectionVector, normalizedViewerVector), 0.0f), uMaterialShininess);"
		"vec3 phong_ADS_Light = ambientLight + diffusedLight + lightSpecular;"
		"fragColor = vec4(phong_ADS_Light, 1.0f);"
		"}"
		"else"
		"{"
		"vec3 phong_ADS_Light = vec3(1.0f, 1.0f, 1.0f);"
		"fragColor = vec4(phong_ADS_Light, 1.0f);"
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
		[self uninitialize];
		[self release];
		exit(0);
	}

	// Shader program
	shaderProgramObject_pf = glCreateProgram();
	glAttachShader(shaderProgramObject_pf, vertexShaderObject_pf);
	glAttachShader(shaderProgramObject_pf, fragmentShaderObject_pf);
	glBindAttribLocation(shaderProgramObject_pf, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_pf, AMC_ATTRIBUTE_NORMAL, "aNormal");
	// glBindAttribLocation(shaderProgramObject_pf, AMC_ATTRIBUTE_TEXTURE_COORDINATES, "aTextureCoordinates");
	glLinkProgram(shaderProgramObject_pf);
	status = 0;
	infoLogLength = 0;
	szInfoLog = NULL;
	glGetProgramiv(shaderProgramObject_pf, GL_LINK_STATUS, &status);
	if (status == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_pf, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0)
		{
			szInfoLog = (GLchar *)malloc(infoLogLength);
			if (szInfoLog != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_pf, infoLogLength, NULL, szInfoLog);
				printf("shader program linking error log: %s\n", szInfoLog);
				free(szInfoLog);
				szInfoLog = NULL;
			}
		}
		[self uninitialize];
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

	// get shader uniform locations - must be after linkage
	if (!vertexShaderEnabled)
	{
		modelMatrixUniform = glGetUniformLocation(shaderProgramObject_pf, "uModelMatrix");
		viewMatrixUniform = glGetUniformLocation(shaderProgramObject_pf, "uViewMatrix");
		projectionMatrixUniform = glGetUniformLocation(shaderProgramObject_pf, "uProjectionMatrix");
		lightAmbientUniform = glGetUniformLocation(shaderProgramObject_pf, "uLightAmbient");
		lightDiffusedUniform = glGetUniformLocation(shaderProgramObject_pf, "uLightDiffused");
		lightSpecularUniform = glGetUniformLocation(shaderProgramObject_pf, "uLightSpecular");
		lightPositionUniform = glGetUniformLocation(shaderProgramObject_pf, "uLightPositionMatrix");
		materialAmbientUniform = glGetUniformLocation(shaderProgramObject_pf, "uMaterialAmbient");
		materialDiffusedUniform = glGetUniformLocation(shaderProgramObject_pf, "uMaterialDiffused");
		materialSpecularUniform = glGetUniformLocation(shaderProgramObject_pf, "uMaterialSpecular");
		materialShininessUniform = glGetUniformLocation(shaderProgramObject_pf, "uMaterialShininess");
		keyPressUniform = glGetUniformLocation(shaderProgramObject_pf, "uKeyPress");

		glUseProgram(shaderProgramObject_pf);
	}
	else
	{
		modelMatrixUniform = glGetUniformLocation(shaderProgramObject_pv, "uModelMatrix");
		viewMatrixUniform = glGetUniformLocation(shaderProgramObject_pv, "uViewMatrix");
		projectionMatrixUniform = glGetUniformLocation(shaderProgramObject_pv, "uProjectionMatrix");
		lightAmbientUniform = glGetUniformLocation(shaderProgramObject_pv, "uLightAmbient");
		lightDiffusedUniform = glGetUniformLocation(shaderProgramObject_pv, "uLightDiffused");
		lightSpecularUniform = glGetUniformLocation(shaderProgramObject_pv, "uLightSpecular");
		lightPositionUniform = glGetUniformLocation(shaderProgramObject_pv, "uLightPositionMatrix");
		materialAmbientUniform = glGetUniformLocation(shaderProgramObject_pv, "uMaterialAmbient");
		materialDiffusedUniform = glGetUniformLocation(shaderProgramObject_pv, "uMaterialDiffused");
		materialSpecularUniform = glGetUniformLocation(shaderProgramObject_pv, "uMaterialSpecular");
		materialShininessUniform = glGetUniformLocation(shaderProgramObject_pv, "uMaterialShininess");
		keyPressUniform = glGetUniformLocation(shaderProgramObject_pv, "uKeyPress");

		glUseProgram(shaderProgramObject_pv);
	}

	// transformations
	mat4 modelMatrix = vmath::translate(0.0f, 0.0f, -2.0f);
	mat4 viewMatrix = vmath::mat4::identity();

	// push above mvp into vertex shaders mvp uniform
	glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, modelMatrix);
	glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, viewMatrix);
	glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, perspectiveProjectionMatrix);
    if (bLightingEnabled) {
        glUniform1i(keyPressUniform, 1);
        glUniform3fv(lightAmbientUniform, 1, lightAmbient);
        glUniform3fv(lightDiffusedUniform, 1, lightDiffused);
        glUniform3fv(lightSpecularUniform, 1, lightSpecular);
        glUniform4fv(lightPositionUniform, 1, lightPosition);
        if (whiteMaterial)
        {
            // White material
            glUniform3fv(materialAmbientUniform, 1, materialAmbientWhite);
            glUniform3fv(materialDiffusedUniform, 1, materialDiffusedWhite);
            glUniform3fv(materialSpecularUniform, 1, materialSpecularWhite);
            glUniform1f(materialShininessUniform, materialShininessWhite);
        }
        else
        {
            // Albedo material
            glUniform3fv(materialAmbientUniform, 1, materialAmbientAlbedo);
            glUniform3fv(materialDiffusedUniform, 1, materialDiffusedAlbedo);
            glUniform3fv(materialSpecularUniform, 1, materialSpecularAlbedo);
            glUniform1f(materialShininessUniform, materialShininessAlbedo);
        }
    } else {
        glUniform1i(keyPressUniform, 0);
    }

	// sphere
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
	sAngle -= 1.0f;
	if (sAngle <= 0.0f)
	{
		sAngle += 360.0f;
	}
}

- (void)uninitialize
{
	// code
	if (shaderProgramObject_pv)
	{
		glUseProgram(shaderProgramObject_pv);
		GLint numShaders = 0;
		glGetProgramiv(shaderProgramObject_pv, GL_ATTACHED_SHADERS, &numShaders);
		if (numShaders > 0)
		{
			GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
			if (pShaders != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_pv, numShaders, NULL, pShaders);
				for (GLint i = 0; i < numShaders; i++)
				{
					glDetachShader(shaderProgramObject_pv, pShaders[i]);
					glDeleteShader(pShaders[i]);
					pShaders[i] = 0;
				}
				free(pShaders);
				pShaders = NULL;
			}
		}
		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_pv);
		shaderProgramObject_pv = 0;
	}
	if (shaderProgramObject_pf)
	{
		glUseProgram(shaderProgramObject_pf);
		GLint numShaders = 0;
		glGetProgramiv(shaderProgramObject_pf, GL_ATTACHED_SHADERS, &numShaders);
		if (numShaders > 0)
		{
			GLuint *pShaders = (GLuint *)malloc(numShaders * sizeof(GLuint));
			if (pShaders != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_pf, numShaders, NULL, pShaders);
				for (GLint i = 0; i < numShaders; i++)
				{
					glDetachShader(shaderProgramObject_pf, pShaders[i]);
					glDeleteShader(pShaders[i]);
					pShaders[i] = 0;
				}
				free(pShaders);
				pShaders = NULL;
			}
		}
		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_pf);
		shaderProgramObject_pf = 0;
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
        bLightingEnabled = true;
        vertexShaderEnabled = true;
        whiteMaterial = true;
    } else if (singleTap == 2) {
        bLightingEnabled = true;
        vertexShaderEnabled = true;
        whiteMaterial = false;
    } else if (singleTap == 3) {
        bLightingEnabled = true;
        vertexShaderEnabled = false;
        whiteMaterial = true;
    } else if (singleTap == 4) {
        bLightingEnabled = true;
        vertexShaderEnabled = false;
        whiteMaterial = false;
    } else {
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
