
#include "EAGLContextHelper.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglContext, void* eaglLayer)
{
    return [(EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)eaglLayer];
}
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer(void* eaglContext)
{
    [(EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:nil];
}

EAGLContext* CreateContext(EAGLContext* parent)
{
    EAGLContext* ret = nil;

    if(parent)
    {
        ret = [[EAGLContext alloc] initWithAPI:[parent API] sharegroup:[parent sharegroup]];
    }
    else
    {
        extern bool UnityIsRenderingAPISupported(int renderingApi);

        for(int api = kEAGLRenderingAPIOpenGLES2 ; api >= kEAGLRenderingAPIOpenGLES1 && !ret ; --api)
        {
            if (UnityIsRenderingAPISupported(api))
                ret = [[EAGLContext alloc] initWithAPI:api];
        }
    }

    return ret;
}

EAGLContextSetCurrentAutoRestore::EAGLContextSetCurrentAutoRestore(EAGLContext* cur_)
  : old([EAGLContext currentContext]),
    cur(cur_)
{
    if (old != cur)
        [EAGLContext setCurrentContext:cur];
}

EAGLContextSetCurrentAutoRestore::~EAGLContextSetCurrentAutoRestore()
{
    if (old != cur)
        [EAGLContext setCurrentContext:old];
}
