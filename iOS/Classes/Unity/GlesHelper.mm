
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <OpenGLES/ES2/glext.h>

#include <stdio.h>

#include "GlesHelper.h"
#include "EAGLContextHelper.h"

#include "iPhone_Profiler.h"


void	UnityCaptureScreenshot();
bool	UnityIsCaptureScreenshotRequested();

bool 	UnityHasRenderingAPIExtension(const char* extension);
int 	UnityGetDesiredMSAASampleCount(int defaultSampleCount);
void 	UnityGetRenderingResolution(unsigned* w, unsigned* h);
void    UnityBlitToSystemFB(unsigned tex, unsigned w, unsigned h, unsigned sysw, unsigned sysh);

extern GLint gDefaultFBO;


extern "C" void InitEAGLLayer(void* eaglLayer, bool use32bitColor);

void InitGLES()
{
#if GL_EXT_discard_framebuffer
	_supportsDiscard = UnityHasRenderingAPIExtension("GL_EXT_discard_framebuffer");
#endif

#if GL_APPLE_framebuffer_multisample
	_supportsMSAA = UnityHasRenderingAPIExtension("GL_APPLE_framebuffer_multisample");
#endif
}


void CreateSystemRenderingSurface(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);
	DestroySystemRenderingSurface(surface);

	const NSString* colorFormat = surface->use32bitColor ? kEAGLColorFormatRGBA8 : kEAGLColorFormatRGB565;

    surface->layer.opaque = YES;
    surface->layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    		[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    		colorFormat, kEAGLDrawablePropertyColorFormat,
                                    		nil
                                		];


    surface->colorFormat = surface->use32bitColor ? GL_RGBA8_OES : GL_RGB565_OES;

	GLES_CHK(glGenRenderbuffersOES(1, &surface->systemColorRB));
	GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemColorRB));
	AllocateRenderBufferStorageFromEAGLLayer(surface->context, surface->layer);

	GLES_CHK(glGenFramebuffersOES(1, &surface->systemFB));
	GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFB));
	GLES_CHK(glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, surface->systemColorRB));
}

void CreateRenderingSurface(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);
	DestroyRenderingSurface(surface);

	if(surface->targetW != surface->systemW || surface->targetH != surface->systemH)
	{
		GLES_CHK(glGenTextures(1, &surface->targetColorRT));
		GLES_CHK(glBindTexture(GL_TEXTURE_2D, surface->targetColorRT));
        GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GLES_UPSCALE_FILTER));
        GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GLES_UPSCALE_FILTER));
        GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
        GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));

        GLenum fmt  = surface->use32bitColor ? GL_RGBA : GL_RGB;
        GLenum type = surface->use32bitColor ? GL_UNSIGNED_BYTE : GL_UNSIGNED_SHORT_5_6_5;
        GLES_CHK(glTexImage2D(GL_TEXTURE_2D, 0, fmt, surface->targetW, surface->targetH, 0, fmt, type, 0));

		GLES_CHK(glGenFramebuffersOES(1, &surface->targetFB));
		GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->targetFB));
		GLES_CHK(glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, surface->targetColorRT, 0));

		GLES_CHK(glBindTexture(GL_TEXTURE_2D, 0));
	}

#if GL_APPLE_framebuffer_multisample
	if(_supportsMSAA && surface->msaaSamples > 1)
	{
		GLES_CHK(glGenRenderbuffersOES(1, &surface->msaaColorRB));
		GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->msaaColorRB));

		GLES_CHK(glGenFramebuffersOES(1, &surface->msaaFB));
		GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->msaaFB));

		GLES_CHK(glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, surface->msaaSamples, surface->colorFormat, surface->targetW, surface->targetH));
		GLES_CHK(glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, surface->msaaColorRB));
	}
#endif
}

void CreateSharedDepthbuffer(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);
	DestroySharedDepthbuffer(surface);

	surface->depthFormat = surface->use24bitDepth ? GL_DEPTH_COMPONENT24_OES : GL_DEPTH_COMPONENT16_OES;

	GLES_CHK(glGenRenderbuffersOES(1, &surface->depthRB));
	GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->depthRB));

	bool needMSAA = GL_APPLE_framebuffer_multisample && (surface->msaaSamples > 1);

#if GL_APPLE_framebuffer_multisample
	if(needMSAA)
		GLES_CHK(glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, surface->msaaSamples, surface->depthFormat, surface->targetW, surface->targetH));
#endif

	if(!needMSAA)
		GLES_CHK(glRenderbufferStorageOES(GL_RENDERBUFFER_OES, surface->depthFormat, surface->targetW, surface->targetH));

	GLES_CHK(glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, surface->depthRB));
}

void CreateUnityRenderBuffers(UnityRenderingSurface* surface)
{
	extern void* UnityCreateUpdateExternalColorSurface(int api, void* surf, unsigned texid, unsigned rbid, int width, int height, bool is32bit);
	extern void* UnityCreateUpdateExternalDepthSurface(int api, void* surf, unsigned texid, unsigned rbid, int width, int height, bool is24bit);

	int w 	= surface->targetW;
	int h 	= surface->targetH;
	int api = surface->context.API;

	unsigned texid = 0, rbid = 0;

	if(surface->msaaFB)			rbid  = surface->msaaColorRB;
	else if(surface->targetFB)	texid = surface->targetColorRT;
	else						rbid  = surface->systemColorRB;

	surface->unityColorBuffer = UnityCreateUpdateExternalColorSurface(api, surface->unityColorBuffer, texid, rbid, w, h, surface->use32bitColor);
	surface->unityDepthBuffer = UnityCreateUpdateExternalDepthSurface(api, surface->unityDepthBuffer, 0, surface->depthRB, w, h, surface->use24bitDepth);
}

void DestroySystemRenderingSurface(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);

	GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, 0));
	GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0));

	if(surface->systemColorRB)
	{
		GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemColorRB));
		DeallocateRenderBufferStorageFromEAGLLayer(surface->context);

		GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, 0));
		GLES_CHK(glDeleteRenderbuffersOES(1, &surface->systemColorRB));
		surface->systemColorRB = 0;
	}

	if(surface->depthRB && surface->targetFB == 0 && surface->msaaFB == 0)
	{
		GLES_CHK(glDeleteRenderbuffersOES(1, &surface->depthRB));
		surface->depthRB = 0;
	}

	if(surface->systemFB)
	{
		GLES_CHK(glDeleteFramebuffersOES(1, &surface->systemFB));
		surface->systemFB = 0;
	}
}

void DestroyRenderingSurface(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);

	if(surface->targetColorRT)
	{
		GLES_CHK(glDeleteTextures(1, &surface->targetColorRT));
		surface->targetColorRT = 0;
	}

	if(surface->targetFB)
	{
		GLES_CHK(glDeleteFramebuffersOES(1, &surface->targetFB));
		surface->targetFB = 0;
	}

	if(surface->msaaColorRB)
	{
		GLES_CHK(glDeleteRenderbuffersOES(1, &surface->msaaColorRB));
		surface->msaaColorRB = 0;
	}

	if(surface->msaaFB)
	{
		GLES_CHK(glDeleteFramebuffersOES(1, &surface->msaaFB));
		surface->msaaFB = 0;
	}
}

void DestroySharedDepthbuffer(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);

	if(surface->depthRB)
	{
		GLES_CHK(glDeleteRenderbuffersOES(1, &surface->depthRB));
		surface->depthRB = 0;
	}
}

void DestroyUnityRenderBuffers(UnityRenderingSurface* surface)
{
	EAGLContextSetCurrentAutoRestore autorestore(surface->context);

	extern void UnityDestroyExternalColorSurface(int api, void* surf);
	extern void UnityDestroyExternalDepthSurface(int api, void* surf);

	if(surface->unityColorBuffer)
	{
		UnityDestroyExternalColorSurface(surface->context.API, surface->unityColorBuffer);
		surface->unityColorBuffer = 0;
	}

	if(surface->unityDepthBuffer)
	{
		UnityDestroyExternalDepthSurface(surface->context.API, surface->unityDepthBuffer);
		surface->unityDepthBuffer = 0;
	}
}

void PreparePresentRenderingSurface(UnityRenderingSurface* surface, EAGLContext* mainContext)
{
	{
		EAGLContextSetCurrentAutoRestore autorestore(surface->context);

	#if GL_APPLE_framebuffer_multisample
		if(surface->msaaSamples > 1 && _supportsMSAA)
		{
			Profiler_StartMSAAResolve();

			GLuint targetFB = surface->targetFB ? surface->targetFB : surface->systemFB;

			GLES_CHK(glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, surface->msaaFB));
			GLES_CHK(glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, targetFB));
			GLES_CHK(glResolveMultisampleFramebufferAPPLE());

			Profiler_EndMSAAResolve();
		}
	#endif

		if(surface->allowScreenshot && UnityIsCaptureScreenshotRequested())
		{
			GLint targetFB = surface->targetFB ? surface->targetFB : surface->systemFB;
			GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, targetFB));
			UnityCaptureScreenshot();
		}
	}

	if(surface->targetColorRT)
	{
		// shaders are bound to context
		EAGLContextSetCurrentAutoRestore autorestore(mainContext);

		gDefaultFBO = surface->systemFB;
		GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO));
		UnityBlitToSystemFB(surface->targetColorRT, surface->targetW, surface->targetH, surface->systemW, surface->systemH);
	}

#if GL_EXT_discard_framebuffer
	if(_supportsDiscard)
	{
		EAGLContextSetCurrentAutoRestore autorestore(surface->context);

		GLenum	discardAttach[] = {GL_COLOR_ATTACHMENT0_OES, GL_DEPTH_ATTACHMENT_OES, GL_STENCIL_ATTACHMENT_OES};

		if(surface->msaaFB)
			GLES_CHK(glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, discardAttach));

		if(surface->targetFB)
		{
			GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->targetFB));
			GLES_CHK(glDiscardFramebufferEXT(GL_FRAMEBUFFER_OES, 3, discardAttach));
		}

		GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFB));
		GLES_CHK(glDiscardFramebufferEXT(GL_FRAMEBUFFER_OES, 2, &discardAttach[1]));
	}
#endif
}

void SetupUnityDefaultFBO(UnityRenderingSurface* surface)
{
	extern GLint gDefaultFBO;
	if(surface->msaaFB)			gDefaultFBO = surface->msaaFB;
	else if(surface->targetFB)	gDefaultFBO = surface->targetFB;
	else						gDefaultFBO = surface->systemFB;

	GLES_CHK(glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO));
}


@implementation GLView
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}
@end


extern "C" bool UnityResolveMSAA(GLuint destFBO, GLuint colorTex, GLuint colorBuf, GLuint depthTex, GLuint depthBuf)
{
#if GL_APPLE_framebuffer_multisample

	// TODO: well - only mainScreen for now
	extern const UnityRenderingSurface* UnityDisplayManager_MainDisplayRenderingSurface();
	const UnityRenderingSurface& targetSurface = *UnityDisplayManager_MainDisplayRenderingSurface();

	if (targetSurface.msaaSamples > 1 && _supportsMSAA && destFBO!=targetSurface.msaaFB && destFBO!=targetSurface.systemFB)
	{
		Profiler_StartMSAAResolve();

		GLint oldFBO;
		GLES_CHK( glGetIntegerv (GL_FRAMEBUFFER_BINDING_OES, &oldFBO) );

		UNITY_DBG_LOG ("UnityResolveMSAA: samples=%i msaaFBO=%i destFBO=%i colorTex=%i colorRB=%i depthTex=%i depthRB=%i\n", targetSurface.msaaSamples, targetSurface.msaaFB, destFBO, colorTex, colorBuf, depthTex, depthBuf);
		UNITY_DBG_LOG ("  bind dest as DRAW FBO and textures/buffers into it\n");

		GLES_CHK( glBindFramebufferOES (GL_DRAW_FRAMEBUFFER_APPLE, destFBO) );
		if (colorTex)
			GLES_CHK( glFramebufferTexture2DOES( GL_DRAW_FRAMEBUFFER_APPLE, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTex, 0 ) );
		else if (colorBuf)
			GLES_CHK( glFramebufferRenderbufferOES (GL_DRAW_FRAMEBUFFER_APPLE, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBuf) );

		if (depthTex)
			GLES_CHK( glFramebufferTexture2DOES( GL_DRAW_FRAMEBUFFER_APPLE, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTex, 0 ) );
		else if (depthBuf)
			GLES_CHK( glFramebufferRenderbufferOES (GL_DRAW_FRAMEBUFFER_APPLE, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuf) );

		UNITY_DBG_LOG ("  bind msaa as READ FBO\n");
		GLES_CHK( glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, targetSurface.msaaFB) );

		UNITY_DBG_LOG ("  glResolveMultisampleFramebufferAPPLE ();\n");
		GLES_CHK( glResolveMultisampleFramebufferAPPLE() );

		GLES_CHK( glBindFramebufferOES (GL_FRAMEBUFFER_OES, oldFBO) );

		Profiler_EndMSAAResolve();
		return true;
	}
	#endif
	return false;
}

extern "C" bool UnityNeedResolveMSAA(GLuint destFBO)
{
#if GL_APPLE_framebuffer_multisample
	// TODO: well - only mainScreen for now
	extern const UnityRenderingSurface* UnityDisplayManager_MainDisplayRenderingSurface();
	const UnityRenderingSurface& targetSurface = *UnityDisplayManager_MainDisplayRenderingSurface();

	if (targetSurface.msaaSamples > 1 && _supportsMSAA && destFBO!=targetSurface.msaaFB && destFBO!=targetSurface.systemFB)
		return true;
#endif

	return false;
}


void CheckGLESError(const char* file, int line)
{
	GLenum e = glGetError();
	if( e )
		printf_console ("OpenGLES error 0x%04X in %s:%i\n", e, file, line);
}




