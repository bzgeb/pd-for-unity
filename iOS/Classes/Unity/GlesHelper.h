
#ifndef _TRAMPOLINE_IPHONE_GLESSUPPORT_H_
#define _TRAMPOLINE_IPHONE_GLESSUPPORT_H_

#import <QuartzCore/QuartzCore.h>

#include <OpenGLES/ES1/gl.h>
#include "iPhone_Common.h"


#define ENABLE_UNITY_GLES_DEBUG 1
#define MSAA_DEFAULT_SAMPLE_COUNT 0

#define GLES_UPSCALE_FILTER GL_LINEAR
//#define GLES_UPSCALE_FILTER GL_NEAREST

extern 	bool			_supportsDiscard;
extern 	bool			_supportsMSAA;

struct
UnityRenderingSurface
{
	CAEAGLLayer*	layer;
	EAGLContext*	context;

	// unity RenderBuffer connection
	void*			unityColorBuffer;
	void*			unityDepthBuffer;

	// system FB
	GLuint			systemFB;
	GLuint			systemColorRB;

	// target resolution FB/target RT to blit from
	GLuint			targetFB;
	GLuint			targetColorRT;

	// MSAA FB
	GLuint			msaaFB;
	GLuint			msaaColorRB;

	// will be "shared", only one depth buffer is needed
	GLuint			depthRB;

	// system surface ext
	unsigned		systemW, systemH;

	// target/msaa ext
	unsigned		targetW, targetH;

	GLuint			colorFormat, depthFormat;

	int				msaaSamples;

	bool 			use32bitColor;
	bool 			use24bitDepth;
	bool			allowScreenshot;
};

void InitGLES();

// in:  layer, context, use32bitColor
void CreateSystemRenderingSurface(UnityRenderingSurface* surface);
void DestroySystemRenderingSurface(UnityRenderingSurface* surface);
// in:  targetW, targetH, msaaSamples
void CreateRenderingSurface(UnityRenderingSurface* surface);
void DestroyRenderingSurface(UnityRenderingSurface* surface);
// in:  use24bitDepth
void CreateSharedDepthbuffer(UnityRenderingSurface* surface);
void DestroySharedDepthbuffer(UnityRenderingSurface* surface);
// should be last ;-)
void CreateUnityRenderBuffers(UnityRenderingSurface* surface);
void DestroyUnityRenderBuffers(UnityRenderingSurface* surface);


void DestroyRenderingSurface(UnityRenderingSurface* surface);
void PreparePresentRenderingSurface(UnityRenderingSurface* surface, EAGLContext* mainContext);
void SetupUnityDefaultFBO(UnityRenderingSurface* surface);

@interface GLView : UIView {}
@end


void CheckGLESError(const char* file, int line);

#if ENABLE_UNITY_GLES_DEBUG
	#define GLESAssert()	do { CheckGLESError (__FILE__, __LINE__); } while(0)
	#define GLES_CHK(expr)	do { {expr;} GLESAssert(); } while(0)
#else
	#define GLESAssert()	do { } while(0)
	#define GLES_CHK(expr)	do { expr; } while(0)
#endif


#endif
