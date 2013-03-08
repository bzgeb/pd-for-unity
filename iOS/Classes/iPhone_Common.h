
#ifndef _TRAMPOLINE_IPHONE_COMMON_H_
#define _TRAMPOLINE_IPHONE_COMMON_H_

//------------------------------------------------------------------------------

// ios/sdk version

extern	bool	_ios30orNewer;
extern	bool	_ios31orNewer;
extern	bool	_ios43orNewer;
extern	bool	_ios50orNewer;
extern	bool	_ios60orNewer;

#ifdef __IPHONE_6_0
#define UNITY_PRE_IOS6_SDK 0
#else
#define UNITY_PRE_IOS6_SDK 1
#endif


//------------------------------------------------------------------------------

enum DeviceGeneration
{
	deviceUnknown = 0,
	deviceiPhone = 1,
	deviceiPhone3G = 2,
	deviceiPhone3GS = 3,
	deviceiPodTouch1Gen = 4,
	deviceiPodTouch2Gen = 5,
	deviceiPodTouch3Gen = 6,
	deviceiPad1Gen = 7,
	deviceiPhone4 = 8,
	deviceiPodTouch4Gen = 9,
	deviceiPad2Gen = 10,
	deviceiPhone4S = 11,
	deviceiPad3Gen = 12,
	deviceiPhone5 = 13,
	deviceiPodTouch5Gen = 14,
	deviceiPadMini1Gen = 15,
	deviceiPad4Gen = 16,
	deviceiPhoneUnknown = 10001,
	deviceiPadUnknown = 10002,
	deviceiPodTouchUnknown = 10003,
};

enum ScreenOrientation
{
    orientationUnknown,
    portrait,
    portraitUpsideDown,
    landscapeLeft,
    landscapeRight,
    autorotation,
    orientationCount
};

struct UnityFrameStats;


//------------------------------------------------------------------------------

#define ENABLE_UNITY_DEBUG_LOG 0

#if ENABLE_UNITY_DEBUG_LOG
	#define UNITY_DBG_LOG(...)				\
		do 									\
		{									\
			printf_console(__VA_ARGS__);	\
		}									\
		while(0)
#else
	#define UNITY_DBG_LOG(...)				\
		do 									\
		{									\
		}									\
		while(0)
#endif // ENABLE_UNITY_DEBUG_LOG


#endif // _TRAMPOLINE_IPHONE_COMMON_H_
