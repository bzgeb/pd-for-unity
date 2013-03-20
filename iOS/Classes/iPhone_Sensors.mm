#import "iPhone_Sensors.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#include "iPhone_View.h"
#include "iPhone_OrientationSupport.h"

static bool gCompensateSensors = true;
bool gEnableGyroscope = false;
bool IsCompensatingSensors() { return gCompensateSensors; }
void SetCompensatingSensors(bool val) { gCompensateSensors = val;}

void UnityDidAccelerate(float x, float y, float z, NSTimeInterval timestamp);

struct Vector3f
{
	float x, y, z;
};

struct Quaternion4f
{
	float x, y, z, w;
};

inline float UnityReorientHeading(float heading)
{
	if (IsCompensatingSensors())
	{
		float rotateBy = 0.f;
		switch (UnityCurrentOrientation())
		{
			case portraitUpsideDown:
				rotateBy = -180.f;
				break;
			case landscapeLeft:
				rotateBy = -270.f;
				break;
			case landscapeRight:
				rotateBy = -90.f;
				break;
			default:
				break;
		}

		return fmodf((360.f + heading + rotateBy), 360.f);
	}
	else
	{
		return heading;
	}
}

inline Vector3f UnityReorientVector3(float x, float y, float z)
{
	if (IsCompensatingSensors())
	{
		Vector3f res;
		switch (UnityCurrentOrientation())
		{
			case portraitUpsideDown:
				{ res = (Vector3f){-x, -y, z}; }
				break;
			case landscapeLeft:
				{ res = (Vector3f){-y, x, z}; }
				break;
			case landscapeRight:
				{ res = (Vector3f){y, -x, z}; }
				break;
			default:
				{ res = (Vector3f){x, y, z}; }
		}
		return res;
	}
	else
	{
		return (Vector3f){x, y, z};
	}
}

static Quaternion4f gQuatRot[4] =
{	// { x*sin(theta/2), y*sin(theta/2), z*sin(theta/2), cos(theta/2) }
	// => { 0, 0, sin(theta/2), cos(theta/2) } (since <vec> = { 0, 0, +/-1})
	{ 0.f, 0.f, 0.f /*sin(0)*/, 1.f /*cos(0)*/},	// ROTATION_0, theta = 0 rad
	{ 0.f, 0.f, (float)sqrt(2) * 0.5f /*sin(pi/4)*/, -(float)sqrt(2) * 0.5f /*cos(pi/4)*/},	// ROTATION_90, theta = pi/4 rad
	{ 0.f, 0.f, 1.f /*sin(pi/2)*/, 0.f /*cos(pi/2)*/},	// ROTATION_180, theta = pi rad
	{ 0.f, 0.f, -(float)sqrt(2) * 0.5f/*sin(3pi/4)*/, -(float)sqrt(2) * 0.5f /*cos(3pi/4)*/}	// ROTATION_270, theta = 3pi/2 rad
};

inline void MultQuat(Quaternion4f& result, const Quaternion4f& lhs, const Quaternion4f& rhs)
{
	result.x = lhs.w*rhs.x + lhs.x*rhs.w + lhs.y*rhs.z - lhs.z*rhs.y;
	result.y = lhs.w*rhs.y + lhs.y*rhs.w + lhs.z*rhs.x - lhs.x*rhs.z;
	result.z = lhs.w*rhs.z + lhs.z*rhs.w + lhs.x*rhs.y - lhs.y*rhs.x;
	result.w = lhs.w*rhs.w - lhs.x*rhs.x - lhs.y*rhs.y - lhs.z*rhs.z;
}

inline Quaternion4f UnityReorientQuaternion(float x, float y, float z, float w)
{
	if (IsCompensatingSensors())
	{
		Quaternion4f res, inp = {x, y, z, w};
		switch (UnityCurrentOrientation())
		{
			case landscapeLeft:
				MultQuat(res, inp, gQuatRot[1]);
				break;
			case portraitUpsideDown:
				MultQuat(res, inp, gQuatRot[2]);
				break;
			case landscapeRight:
				MultQuat(res, inp, gQuatRot[3]);
				break;
			default:
				res = inp;
		}
		return res;
	}
	else
	{
		return (Quaternion4f){x, y, z, w};
	}
}

void SetGyroRotationRate(int idx, float x, float y, float z);
void SetGyroRotationRateUnbiased(int idx, float x, float y, float z);
void SetGravity(int idx, float x, float y, float z);
void SetUserAcceleration(int idx, float x, float y, float z);
void SetAttitude(int idx, float x, float y, float z, float w);

static CMMotionManager *sMotionManager = nil;
static NSOperationQueue* sMotionQueue = nil;

// Current update interval or 0.0f if not initialized. This is returned
// to the user as current update interval and this value is set to 0.0f when
// gyroscope is disabled.
static float sUpdateInterval = 0.0f;

// Update interval set by the user. Core motion will be set-up to use
// this update interval after disabling and re-enabling gyroscope
// so users can set update interval, disable gyroscope, enable gyroscope and
// after that gyroscope will be updated at this previously set interval.
static float sUserUpdateInterval = 1.0f / 30.0f;

void SensorsCleanup()
{
	if (sMotionManager != nil)
	{
		[sMotionManager stopGyroUpdates];
		[sMotionManager stopDeviceMotionUpdates];
		[sMotionManager stopAccelerometerUpdates];
		[sMotionManager release];
		sMotionManager = nil;
	}
	
	if (sMotionQueue != nil)
	{
		[sMotionQueue release];
		sMotionQueue = nil;
	}
}


void CoreMotionStart()
{
	if (sMotionQueue == nil)
		sMotionQueue = [[NSOperationQueue alloc] init];
	
	if (sMotionManager == nil)
	{		
		sMotionManager = [[CMMotionManager alloc] init];
		
		if (sMotionManager.gyroAvailable && gEnableGyroscope)
		{
			[sMotionManager startGyroUpdates];
			[sMotionManager setGyroUpdateInterval: sUpdateInterval];
		}
		
		if (sMotionManager.deviceMotionAvailable && gEnableGyroscope)
		{
			[sMotionManager startDeviceMotionUpdates];
			[sMotionManager setDeviceMotionUpdateInterval: sUpdateInterval];
		}
		
		if (sMotionManager.accelerometerAvailable)
		{
			int frequency = UnityGetAccelerometerFrequency();
			if (frequency > 0)
			{
				[sMotionManager startAccelerometerUpdatesToQueue: sMotionQueue withHandler: ^( CMAccelerometerData* data, NSError* error) {
					Vector3f res = UnityReorientVector3(data.acceleration.x, data.acceleration.y, data.acceleration.z);
					UnityDidAccelerate(res.x, res.y, res.z, data.timestamp);
				}];
				[sMotionManager setAccelerometerUpdateInterval: 1.0 / frequency];
			}
		}
	}
}

void CoreMotionStop()
{
	if (sMotionManager != nil)
	{
		[sMotionManager stopGyroUpdates];
		[sMotionManager stopDeviceMotionUpdates];
	}
}

void SetGyroUpdateInterval(int idx, float interval)
{
	if (interval < (1.0f / 60.0f))
		interval = (1.0f / 60.0f);
	else if (interval > (1.0f))
		interval = 1.0f;

	sUserUpdateInterval = interval;

	if (sMotionManager)
	{
		sUpdateInterval = interval;

		[sMotionManager setGyroUpdateInterval: interval];
		[sMotionManager setDeviceMotionUpdateInterval: interval];
	}
}

float GetGyroUpdateInterval(int idx)
{
	return sUpdateInterval;
}

void UpdateGyroData()
{
	CMRotationRate rotationRate = { 0.0, 0.0, 0.0 };
	CMRotationRate rotationRateUnbiased = { 0.0, 0.0, 0.0 };
	CMAcceleration userAcceleration = { 0.0, 0.0, 0.0 };
	CMAcceleration gravity = { 0.0, 0.0, 0.0 };
	CMQuaternion attitude = { 0.0, 0.0, 0.0, 1.0 };

	if (sMotionManager != nil)
	{
		CMGyroData *gyroData = sMotionManager.gyroData;
		CMDeviceMotion *motionData = sMotionManager.deviceMotion;

		if (gyroData != nil)
		{
			rotationRate = gyroData.rotationRate;
		}

		if (motionData != nil)
		{
			CMAttitude *att = motionData.attitude;

			attitude = att.quaternion;
			rotationRateUnbiased = motionData.rotationRate;
			userAcceleration = motionData.userAcceleration;
			gravity = motionData.gravity;
		}
	}

	Vector3f reorientedRotRate = UnityReorientVector3(rotationRate.x, rotationRate.y, rotationRate.z);
	SetGyroRotationRate(0, reorientedRotRate.x, reorientedRotRate.y, reorientedRotRate.z);

	Vector3f reorientedRotRateUnbiased = UnityReorientVector3(rotationRateUnbiased.x, rotationRateUnbiased.y, rotationRateUnbiased.z);
	SetGyroRotationRateUnbiased(0, reorientedRotRateUnbiased.x, reorientedRotRateUnbiased.y, reorientedRotRateUnbiased.z);

	Vector3f reorientedUserAcc = UnityReorientVector3(userAcceleration.x, userAcceleration.y, userAcceleration.z);
	SetUserAcceleration(0, reorientedUserAcc.x, reorientedUserAcc.y, reorientedUserAcc.z);

	Vector3f reorientedG = UnityReorientVector3(gravity.x, gravity.y, gravity.z);
	SetGravity(0, reorientedG.x, reorientedG.y, reorientedG.z);

	Quaternion4f reorientedAtt = UnityReorientQuaternion(attitude.x, attitude.y, attitude.z, attitude.w);
	SetAttitude(0, reorientedAtt.x, reorientedAtt.y, reorientedAtt.z, reorientedAtt.w);
}

bool IsGyroEnabled(int idx)
{
	if (sMotionManager == nil)
		return false;

	return sMotionManager.gyroAvailable && sMotionManager.gyroActive;
}

bool IsGyroAvailable()
{
	if (sMotionManager != nil)
		return sMotionManager.gyroAvailable;

	return false;
}

@interface LocationServiceDelegate : NSObject <CLLocationManagerDelegate>
@end

void
UnitySetLastLocation(double timestamp,
					 float latitude,
					 float longitude,
					 float altitude,
					 float horizontalAccuracy,
					 float verticalAccuracy);

void
UnitySetLastHeading(float magneticHeading,
					float trueHeading,
					float rawX, float rawY, float rawZ,
					double timestamp);

struct LocationServiceInfo
{
private:
	LocationServiceDelegate* delegate;
	CLLocationManager* locationManager;
public:
	LocationServiceStatus locationStatus;
	LocationServiceStatus headingStatus;

	float desiredAccuracy;
	float distanceFilter;

	LocationServiceInfo();
	CLLocationManager* GetLocationManager();
};

LocationServiceInfo::LocationServiceInfo()
{
	locationStatus = kLocationServiceStopped;
	desiredAccuracy = kCLLocationAccuracyKilometer;
	distanceFilter = 500;

	headingStatus = kLocationServiceStopped;
}

static LocationServiceInfo gLocationServiceStatus;

CLLocationManager*
LocationServiceInfo::GetLocationManager()
{
	if (locationManager == nil)
	{
		locationManager = [[CLLocationManager alloc] init];
		delegate = [LocationServiceDelegate alloc];

		locationManager.delegate = delegate;
	}

	return locationManager;
}


bool LocationService::IsServiceEnabledByUser()
{
	return [CLLocationManager locationServicesEnabled];
}


void LocationService::SetDesiredAccuracy(float val)
{
	gLocationServiceStatus.desiredAccuracy = val;
}

float LocationService::GetDesiredAccuracy()
{
	return gLocationServiceStatus.desiredAccuracy;
}

void LocationService::SetDistanceFilter(float val)
{
	gLocationServiceStatus.distanceFilter = val;
}

float LocationService::GetDistanceFilter()
{
	return gLocationServiceStatus.distanceFilter;
}

void LocationService::StartUpdatingLocation()
{
	if (gLocationServiceStatus.locationStatus != kLocationServiceRunning)
	{
		CLLocationManager* locationManager = gLocationServiceStatus.GetLocationManager();
		locationManager.desiredAccuracy = gLocationServiceStatus.desiredAccuracy;
		// Set a movement threshold for new events
		locationManager.distanceFilter = gLocationServiceStatus.distanceFilter;
		[locationManager startUpdatingLocation];

		gLocationServiceStatus.locationStatus = kLocationServiceInitializing;
	}
}

void LocationService::StopUpdatingLocation()
{
	if (gLocationServiceStatus.locationStatus == kLocationServiceRunning)
	{
		[gLocationServiceStatus.GetLocationManager() stopUpdatingLocation];
		gLocationServiceStatus.locationStatus = kLocationServiceStopped;
	}
}

void LocationService::SetHeadingUpdatesEnabled(bool enabled)
{
	if (enabled)
	{
		if (gLocationServiceStatus.headingStatus != kLocationServiceRunning &&
			IsHeadingAvailable())
		{
			CLLocationManager* locationManager = gLocationServiceStatus.GetLocationManager();

			[locationManager startUpdatingHeading];
			gLocationServiceStatus.headingStatus = kLocationServiceInitializing;
		}
	}
	else
	{
		if(gLocationServiceStatus.headingStatus == kLocationServiceRunning)
		{
			[gLocationServiceStatus.GetLocationManager() stopUpdatingHeading];
			gLocationServiceStatus.headingStatus = kLocationServiceStopped;
		}
	}

}

bool LocationService::IsHeadingUpdatesEnabled()
{
	return (gLocationServiceStatus.headingStatus == kLocationServiceRunning);
}

int UnityGetLocationStatus()
{
	return gLocationServiceStatus.locationStatus;
}

int UnityGetHeadingStatus()
{
	return gLocationServiceStatus.headingStatus;
}

bool LocationService::IsHeadingAvailable()
{
	return [CLLocationManager headingAvailable];
}

@implementation LocationServiceDelegate

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	gLocationServiceStatus.locationStatus = kLocationServiceRunning;

	UnitySetLastLocation([newLocation.timestamp timeIntervalSince1970],
						 newLocation.coordinate.latitude,
						 newLocation.coordinate.longitude,
						 newLocation.altitude,
						 newLocation.horizontalAccuracy,
						 newLocation.verticalAccuracy);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
	gLocationServiceStatus.headingStatus = kLocationServiceRunning;

	Vector3f reorientedRawHeading = UnityReorientVector3(newHeading.x, newHeading.y, newHeading.z);

	UnitySetLastHeading(UnityReorientHeading(newHeading.magneticHeading),
						UnityReorientHeading(newHeading.trueHeading),
						reorientedRawHeading.x, reorientedRawHeading.y, reorientedRawHeading.z,
						[newHeading.timestamp timeIntervalSince1970]);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	return NO;
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error;
{
	gLocationServiceStatus.locationStatus = kLocationServiceFailed;
	gLocationServiceStatus.headingStatus = kLocationServiceFailed;
}

@end

