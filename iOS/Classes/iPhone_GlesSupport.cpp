
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <OpenGLES/ES2/glext.h>

#include <stdio.h>

#include "iPhone_GlesSupport.h"
#include "iPhone_Profiler.h"


void	UnityCaptureScreenshot();
bool	UnityIsCaptureScreenshotRequested();

bool 	UnityHasRenderingAPIExtension(const char* extension);
int 	UnityGetDesiredMSAASampleCount(int defaultSampleCount);
void 	UnityGetRenderingResolution(unsigned* w, unsigned* h);
void    UnityBlitToSystemFB(unsigned tex, unsigned w, unsigned h, unsigned sysw, unsigned sysh);

bool	UnityUse32bitDisplayBuffer();

extern 	GLint	gDefaultFBO;


extern "C" void InitEAGLLayer(void* eaglLayer, bool use32bitColor);
extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglLayer);
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer();

void InitGLES()
{
#if GL_EXT_discard_framebuffer
	_supportsDiscard = UnityHasRenderingAPIExtension("GL_EXT_discard_framebuffer");
#endif

#if GL_APPLE_framebuffer_multisample
	_supportsMSAA = UnityHasRenderingAPIExtension("GL_APPLE_framebuffer_multisample");
#endif
}


void CreateSurfaceGLES(EAGLSurfaceDesc* surface)
{
	GLuint oldRenderbuffer;
	GLES_CHK( glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint*)&oldRenderbuffer) );

	DestroySurfaceGLES(surface);

	InitEAGLLayer(surface->eaglLayer, surface->use32bitColor);

	GLES_CHK( glGenRenderbuffersOES(1, &surface->systemRenderbuffer) );
	GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );

	if( !AllocateRenderBufferStorageFromEAGLLayer(surface->eaglLayer) )
	{
		GLES_CHK( glDeleteRenderbuffersOES(1, &surface->systemRenderbuffer) );
		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_BINDING_OES, oldRenderbuffer) );

		printf_console("FAILED allocating render buffer storage from gles context\n");
		return;
	}

	GLES_CHK( glGenFramebuffersOES(1, &surface->systemFramebuffer) );
	GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFramebuffer) );
	GLES_CHK( glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );

	gDefaultFBO = surface->systemFramebuffer;

	CreateRenderingSurfaceGLES(surface);
}

void DestroySurfaceGLES(EAGLSurfaceDesc* surface)
{
	if( surface->systemRenderbuffer )
	{
		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );
		DeallocateRenderBufferStorageFromEAGLLayer();

		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, 0) );
		GLES_CHK( glDeleteRenderbuffersOES(1, &surface->systemRenderbuffer) );

		surface->systemRenderbuffer = 0;
	}

	if( surface->systemFramebuffer )
	{
		GLES_CHK( glDeleteFramebuffersOES(1, &surface->systemFramebuffer) );
		surface->systemFramebuffer = 0;
	}

	DestroyRenderingSurfaceGLES(surface);

	if(surface->depthbuffer)
	{
		GLES_CHK( glDeleteRenderbuffersOES(1, &surface->depthbuffer) );
		surface->depthbuffer = 0;
	}
}


bool NeedRecreateRenderingSurfaceGLES(EAGLSurfaceDesc* surface)
{
	unsigned requestedW, requestedH;
	UnityGetRenderingResolution(&requestedW, &requestedH);

	if(requestedW != surface->targetW || requestedH != surface->targetH)
		return true;

#if GL_APPLE_framebuffer_multisample
	if( _supportsMSAA && UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT) != surface->msaaSamples )
		return true;
#endif

	return false;
}

void CreateRenderingSurfaceGLES(EAGLSurfaceDesc* surface)
{
	gDefaultFBO = surface->systemFramebuffer;

	GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFramebuffer) );
	GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );

	DestroyRenderingSurfaceGLES(surface);

	GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFramebuffer) );
	GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );

	if( surface->targetW != surface->systemW || surface->targetH != surface->systemH )
	{
		GLES_CHK( glGenTextures(1, &surface->targetRT) );
		GLES_CHK( glBindTexture(GL_TEXTURE_2D, surface->targetRT) );
        GLES_CHK( glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GLES_UPSCALE_FILTER) );
        GLES_CHK( glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GLES_UPSCALE_FILTER) );
        GLES_CHK( glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE) );
        GLES_CHK( glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE) );

        GLenum fmt  = surface->use32bitColor ? GL_RGBA : GL_RGB;
        GLenum type = surface->use32bitColor ? GL_UNSIGNED_BYTE : GL_UNSIGNED_SHORT_5_6_5;
        GLES_CHK( glTexImage2D(GL_TEXTURE_2D, 0, fmt, surface->targetW, surface->targetH, 0, fmt, type, 0) );

		GLES_CHK( glGenFramebuffersOES(1, &surface->targetFramebuffer) );
		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->targetFramebuffer) );
		GLES_CHK( glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, surface->targetRT, 0) );

		GLES_CHK( glBindTexture(GL_TEXTURE_2D, 0) );
		gDefaultFBO = surface->targetFramebuffer;
	}

#if GL_APPLE_framebuffer_multisample
	if(_supportsMSAA && surface->msaaSamples > 1)
	{
		GLES_CHK( glGenRenderbuffersOES(1, &surface->msaaRenderbuffer) );
		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->msaaRenderbuffer) );

		GLES_CHK( glGenFramebuffersOES(1, &surface->msaaFramebuffer) );
		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->msaaFramebuffer) );

		GLES_CHK( glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, surface->msaaSamples, surface->format, surface->targetW, surface->targetH) );
		GLES_CHK( glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, surface->msaaRenderbuffer) );

		gDefaultFBO = surface->msaaFramebuffer;
	}
#endif

	GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO) );
	if(surface->depthFormat != 0)
	{
		GLES_CHK( glGenRenderbuffersOES(1, &surface->depthbuffer) );
		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->depthbuffer) );

		bool needMSAA = GL_APPLE_framebuffer_multisample && (surface->msaaSamples > 1);

	#if GL_APPLE_framebuffer_multisample
		if(needMSAA)
			GLES_CHK( glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, surface->msaaSamples, surface->depthFormat, surface->targetW, surface->targetH) );
	#endif

		if(!needMSAA)
			GLES_CHK( glRenderbufferStorageOES(GL_RENDERBUFFER_OES, surface->depthFormat, surface->targetW, surface->targetH) );

		GLES_CHK( glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, surface->depthbuffer) );
	}
}

void DestroyRenderingSurfaceGLES(EAGLSurfaceDesc* surface)
{
	if( (surface->msaaFramebuffer || surface->targetFramebuffer) && surface->depthbuffer )
	{
		GLES_CHK( glDeleteRenderbuffersOES(1, &surface->depthbuffer) );
		surface->depthbuffer = 0;
	}

	if(surface->targetRT)
	{
		GLES_CHK( glDeleteTextures(1, &surface->targetRT) );
		surface->targetRT = 0;
	}

	if(surface->targetFramebuffer)
	{
		GLES_CHK( glDeleteFramebuffersOES(1, &surface->targetFramebuffer) );
		surface->targetFramebuffer = 0;
	}

	if(surface->msaaRenderbuffer)
	{
		GLES_CHK( glDeleteRenderbuffersOES(1, &surface->msaaRenderbuffer) );
		surface->msaaRenderbuffer = 0;
	}

	if(surface->msaaFramebuffer)
	{
		GLES_CHK( glDeleteFramebuffersOES(1, &surface->msaaFramebuffer) );
		surface->msaaFramebuffer = 0;
	}
}

void PreparePresentSurfaceGLES(EAGLSurfaceDesc* surface)
{
#if GL_APPLE_framebuffer_multisample
	if( surface->msaaSamples > 1 && _supportsMSAA )
	{
		Profiler_StartMSAAResolve();

		GLuint drawFB = surface->targetFramebuffer ? surface->targetFramebuffer : surface->systemFramebuffer;

		GLES_CHK( glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, surface->msaaFramebuffer) );
		GLES_CHK( glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, drawFB) );
		GLES_CHK( glResolveMultisampleFramebufferAPPLE() );

		Profiler_EndMSAAResolve();
	}
#endif

	// update screenshot from target FBO to get requested resolution
	if( UnityIsCaptureScreenshotRequested() )
	{
		GLint target = surface->targetFramebuffer ? surface->targetFramebuffer : surface->systemFramebuffer;

		GLint curfb = 0;
		GLES_CHK( glGetIntegerv(GL_FRAMEBUFFER_BINDING, &curfb) );

		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, target) );
		UnityCaptureScreenshot();
		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, curfb) );
	}


	if( surface->targetFramebuffer )
	{
		gDefaultFBO = surface->systemFramebuffer;
		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO) );

		UnityBlitToSystemFB(surface->targetRT, surface->targetW, surface->targetH, surface->systemW, surface->systemH);

		gDefaultFBO = surface->msaaFramebuffer ? surface->msaaFramebuffer : surface->targetFramebuffer;
		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO) );
	}

#if GL_EXT_discard_framebuffer
	if( _supportsDiscard )
	{
		GLenum	discardAttach[] = {GL_COLOR_ATTACHMENT0_OES, GL_DEPTH_ATTACHMENT_OES, GL_STENCIL_ATTACHMENT_OES};

		if( surface->msaaFramebuffer )
			GLES_CHK( glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 3, discardAttach) );

		if(surface->targetFramebuffer)
		{
			GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->targetFramebuffer) );
			GLES_CHK( glDiscardFramebufferEXT(GL_FRAMEBUFFER_OES, 3, discardAttach) );
		}

		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, surface->systemFramebuffer) );
		GLES_CHK( glDiscardFramebufferEXT(GL_FRAMEBUFFER_OES, 2, &discardAttach[1]) );

		GLES_CHK( glBindFramebufferOES(GL_FRAMEBUFFER_OES, gDefaultFBO) );
	}
#endif
}

void AfterPresentSurfaceGLES(EAGLSurfaceDesc* surface)
{
	if(surface->use32bitColor != UnityUse32bitDisplayBuffer())
	{
		surface->use32bitColor = UnityUse32bitDisplayBuffer();
		CreateSurfaceGLES(surface);
		GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );
	}

	if(NeedRecreateRenderingSurfaceGLES(surface))
	{
		UnityGetRenderingResolution(&surface->targetW, &surface->targetH);
		surface->msaaSamples = UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT);

		CreateRenderingSurfaceGLES(surface);
	}
}


extern "C" bool UnityResolveMSAA(GLuint destFBO, GLuint colorTex, GLuint colorBuf, GLuint depthTex, GLuint depthBuf)
{
#if GL_APPLE_framebuffer_multisample
	if (_surface.msaaSamples > 1 && _supportsMSAA && destFBO!=_surface.msaaFramebuffer && destFBO!=_surface.systemFramebuffer)
	{
		Profiler_StartMSAAResolve();

		GLint oldFBO;
		GLES_CHK( glGetIntegerv (GL_FRAMEBUFFER_BINDING_OES, &oldFBO) );

		UNITY_DBG_LOG ("UnityResolveMSAA: samples=%i msaaFBO=%i destFBO=%i colorTex=%i colorRB=%i depthTex=%i depthRB=%i\n", _surface.msaaSamples, _surface.msaaFramebuffer, destFBO, colorTex, colorBuf, depthTex, depthBuf);
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
		GLES_CHK( glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, _surface.msaaFramebuffer) );

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
	if (_surface.msaaSamples > 1 && _supportsMSAA && destFBO!=_surface.msaaFramebuffer && destFBO!=_surface.systemFramebuffer)
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




