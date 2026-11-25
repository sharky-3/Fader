#ifndef MultitouchPrivate_h
#define MultitouchPrivate_h

#include <CoreFoundation/CoreFoundation.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t pathIndex;
    int32_t state;
    int32_t fingerID;
    int32_t handID;
    MTVector normalizedVector;
    float zTotal;
    int32_t field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absoluteVector;
    int32_t field14;
    int32_t field15;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;
typedef void *MTActuatorRef;
typedef int (*MTContactCallbackFunction)(MTDeviceRef device, MTTouch *touches, int32_t count, double timestamp, int32_t frame);

CFArrayRef MTDeviceCreateList(void) CF_RETURNS_RETAINED;
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTUnregisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTDeviceStart(MTDeviceRef device, int32_t mode);
void MTDeviceStop(MTDeviceRef device);
bool MTDeviceIsBuiltIn(MTDeviceRef device);
int32_t MTDeviceGetDeviceID(MTDeviceRef device, uint64_t *deviceID);
int32_t MTDeviceGetFamilyID(MTDeviceRef device, int32_t *familyID);

MTActuatorRef MTActuatorCreateFromDeviceID(uint64_t deviceID);
int32_t MTActuatorOpen(MTActuatorRef actuator);
int32_t MTActuatorClose(MTActuatorRef actuator);
int32_t MTActuatorActuate(MTActuatorRef actuator, int32_t actuationID, uint32_t flags, float unknown1, float unknown2);

#endif
