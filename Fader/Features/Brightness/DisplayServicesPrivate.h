#ifndef DisplayServicesPrivate_h
#define DisplayServicesPrivate_h

#include <CoreGraphics/CoreGraphics.h>
#include <stdbool.h>

int DisplayServicesGetBrightness(CGDirectDisplayID display, float *brightness);
int DisplayServicesSetBrightness(CGDirectDisplayID display, float brightness);
bool DisplayServicesCanChangeBrightness(CGDirectDisplayID display);

#endif
