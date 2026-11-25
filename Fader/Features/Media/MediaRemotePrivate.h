#ifndef MediaRemotePrivate_h
#define MediaRemotePrivate_h

#include <CoreFoundation/CoreFoundation.h>
#include <dispatch/dispatch.h>

void MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t queue);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, void (^handler)(CFDictionaryRef info));
void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue, void (^handler)(Boolean isPlaying));
Boolean MRMediaRemoteSendCommand(uint32_t command, CFDictionaryRef options);
void MRMediaRemoteSetElapsedTime(double elapsedTime);

#endif
