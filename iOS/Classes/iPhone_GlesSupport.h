
#ifndef _TRAMPOLINE_IPHONE_GLESSUPPORT_H_
#define _TRAMPOLINE_IPHONE_GLESSUPPORT_H_

#include <OpenGLES/ES1/gl.h>
#include "iPhone_Common.h"


#define ENABLE_UNITY_GLES_DEBUG 1
#define MSAA_DEFAULT_SAMPLE_COUNT 0

#define GLES_UPSCALE_FILTER GL_LINEAR
//#define GLES_UPSCALE_FILTER GL_NEAREST


struct EAGLSurfaceDesc
{
	GLuint		format;
	GLuint		depthFormat;
	GLuint		msaaSamples;

	// system FB
	GLuint		systemFramebuffer;
	GLuint		systemRenderbuffer;

	// target resolution FB
	GLuint		targetFramebuffer;
	GLuint		targetRT;

	// MSAA FB
	GLuint		msaaFramebuffer;
	GLuint		msaaRenderbuffer;

	// will be "shared", only one depth buffer is needed
	GLuint		depthbuffer;

	unsigned	systemW, systemH;
	unsigned	targetW, targetH;

	void*		eaglLayer;

	bool		use32bitColor;
};
extern	EAGLSurfaceDesc	_surface;


extern 	bool			_supportsDiscard;
extern 	bool			_supportsMSAA;


void InitGLES();

void CreateSurfaceGLES(EAGLSurfaceDesc* surface);
void DestroySurfaceGLES(EAGLSurfaceDesc* surface);

bool NeedRecreateRenderingSurfaceGLES(EAGLSurfaceDesc* surface);
void CreateRenderingSurfaceGLES(EAGLSurfaceDesc* surface);
void DestroyRenderingSurfaceGLES(EAGLSurfaceDesc* surface);

void PreparePresentSurfaceGLES(EAGLSurfaceDesc* surface);
void AfterPresentSurfaceGLES(EAGLSurfaceDesc* surface);


void CheckGLESError(const char* file, int line);


#if ENABLE_UNITY_GLES_DEBUG
	#define GLESAssert()	do { CheckGLESError (__FILE__, __LINE__); } while(0)
	#define GLES_CHK(expr)	do { {expr;} GLESAssert(); } while(0)
#else
	#define GLESAssert()	do { } while(0)
	#define GLES_CHK(expr)	do { expr; } while(0)
#endif


#endif
