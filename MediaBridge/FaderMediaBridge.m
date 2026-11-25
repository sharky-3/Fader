#import <Foundation/Foundation.h>
#import <dlfcn.h>

typedef void (*FMRRegisterFunction)(dispatch_queue_t queue);
typedef void (*FMRGetInfoFunction)(dispatch_queue_t queue, void (^handler)(CFDictionaryRef info));
typedef void (*FMRIsPlayingFunction)(dispatch_queue_t queue, void (^handler)(Boolean playing));
typedef Boolean (*FMRSendCommandFunction)(uint32_t command, CFDictionaryRef options);
typedef void (*FMRSetElapsedFunction)(double elapsed);

static FMRRegisterFunction FMRRegister;
static FMRGetInfoFunction FMRGetInfo;
static FMRIsPlayingFunction FMRIsPlaying;
static FMRSendCommandFunction FMRSendCommand;
static FMRSetElapsedFunction FMRSetElapsed;
static NSData *FMRLastArtwork;
static NSMutableData *FMRInputBuffer;
static dispatch_source_t FMRInputSource;
static dispatch_source_t FMRPublishTimer;

static void FMREmit(NSDictionary *payload) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (data == nil) {
        return;
    }
    fwrite(data.bytes, 1, data.length, stdout);
    fputc('\n', stdout);
    fflush(stdout);
}

static id FMRValue(NSDictionary *info, NSString *key) {
    id value = info[[@"kMRMediaRemoteNowPlayingInfo" stringByAppendingString:key]];
    return value == [NSNull null] ? nil : value;
}

static void FMRPublishNow(void) {
    FMRGetInfo(dispatch_get_main_queue(), ^(CFDictionaryRef raw) {
        NSDictionary *info = raw == NULL ? nil : [(__bridge NSDictionary *)raw copy];
        FMRIsPlaying(dispatch_get_main_queue(), ^(Boolean playing) {
            if (info.count == 0) {
                FMRLastArtwork = nil;
                FMREmit(@{ @"empty": @YES });
                return;
            }
            NSMutableDictionary *payload = [NSMutableDictionary dictionary];
            payload[@"playing"] = @(playing != 0);
            for (NSString *key in @[ @"Title", @"Artist", @"Album" ]) {
                id value = FMRValue(info, key);
                if ([value isKindOfClass:[NSString class]]) {
                    payload[key.lowercaseString] = value;
                }
            }
            NSDictionary *numbers = @{ @"Duration": @"duration", @"ElapsedTime": @"elapsed", @"PlaybackRate": @"rate" };
            for (NSString *key in numbers) {
                id value = FMRValue(info, key);
                if ([value isKindOfClass:[NSNumber class]]) {
                    payload[numbers[key]] = value;
                }
            }
            id timestamp = FMRValue(info, @"Timestamp");
            if ([timestamp isKindOfClass:[NSDate class]]) {
                payload[@"timestamp"] = @([(NSDate *)timestamp timeIntervalSince1970]);
            }
            id artwork = FMRValue(info, @"ArtworkData");
            if ([artwork isKindOfClass:[NSData class]] && [(NSData *)artwork length] > 0) {
                if ([FMRLastArtwork isEqualToData:artwork]) {
                    payload[@"artwork"] = @"same";
                } else {
                    FMRLastArtwork = artwork;
                    payload[@"artwork"] = @"new";
                    payload[@"artworkData"] = [(NSData *)artwork base64EncodedStringWithOptions:0];
                }
            } else {
                FMRLastArtwork = nil;
                payload[@"artwork"] = @"none";
            }
            FMREmit(payload);
        });
    });
}

static void FMRPublish(void) {
    dispatch_source_set_timer(FMRPublishTimer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_MSEC)), DISPATCH_TIME_FOREVER, (uint64_t)(10 * NSEC_PER_MSEC));
}

static void FMRHandleLine(NSString *line) {
    NSArray<NSString *> *parts = [line componentsSeparatedByString:@" "];
    NSString *command = parts.firstObject;
    NSDictionary<NSString *, NSNumber *> *commands = @{ @"play": @0, @"pause": @1, @"toggle": @2, @"next": @4, @"previous": @5 };
    if (commands[command] != nil) {
        FMRSendCommand(commands[command].unsignedIntValue, NULL);
        FMRPublish();
    } else if ([command isEqualToString:@"seek"] && parts.count > 1) {
        FMRSetElapsed(parts[1].doubleValue);
        FMRPublish();
    } else if ([command isEqualToString:@"refresh"]) {
        FMRPublishNow();
    }
}

static void FMRReadInput(void) {
    char chunk[4096];
    ssize_t count = read(STDIN_FILENO, chunk, sizeof(chunk));
    if (count <= 0) {
        exit(0);
    }
    [FMRInputBuffer appendBytes:chunk length:(NSUInteger)count];
    while (YES) {
        NSRange newline = [FMRInputBuffer rangeOfData:[NSData dataWithBytes:"\n" length:1] options:0 range:NSMakeRange(0, FMRInputBuffer.length)];
        if (newline.location == NSNotFound) {
            break;
        }
        NSData *lineData = [FMRInputBuffer subdataWithRange:NSMakeRange(0, newline.location)];
        [FMRInputBuffer replaceBytesInRange:NSMakeRange(0, newline.location + 1) withBytes:NULL length:0];
        NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            FMRHandleLine(trimmed);
        }
    }
}

__attribute__((visibility("default")))
void fader_bridge_run(void *interpreter, void *code) {
    @autoreleasepool {
        void *handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW);
        if (handle != NULL) {
            FMRRegister = (FMRRegisterFunction)dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications");
            FMRGetInfo = (FMRGetInfoFunction)dlsym(handle, "MRMediaRemoteGetNowPlayingInfo");
            FMRIsPlaying = (FMRIsPlayingFunction)dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying");
            FMRSendCommand = (FMRSendCommandFunction)dlsym(handle, "MRMediaRemoteSendCommand");
            FMRSetElapsed = (FMRSetElapsedFunction)dlsym(handle, "MRMediaRemoteSetElapsedTime");
        }
        if (FMRRegister == NULL || FMRGetInfo == NULL || FMRIsPlaying == NULL || FMRSendCommand == NULL || FMRSetElapsed == NULL) {
            FMREmit(@{ @"error": @"unavailable" });
            exit(1);
        }
        FMRInputBuffer = [NSMutableData data];
        FMRPublishTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(FMRPublishTimer, DISPATCH_TIME_FOREVER, DISPATCH_TIME_FOREVER, 0);
        dispatch_source_set_event_handler(FMRPublishTimer, ^{
            FMRPublishNow();
        });
        dispatch_resume(FMRPublishTimer);
        FMRRegister(dispatch_get_main_queue());
        NSArray<NSString *> *names = @[
            @"kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            @"kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            @"kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            @"kMRMediaRemoteNowPlayingPlaybackQueueChangedNotification"
        ];
        for (NSString *name in names) {
            [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
                FMRPublish();
            }];
        }
        FMRInputSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, STDIN_FILENO, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(FMRInputSource, ^{
            FMRReadInput();
        });
        dispatch_resume(FMRInputSource);
        FMREmit(@{ @"ready": @YES });
        FMRPublishNow();
    }
    CFRunLoopRun();
    exit(0);
}
