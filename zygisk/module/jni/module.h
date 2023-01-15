#pragma once

namespace safetynetfixjukmisael {

static constexpr auto TAG = "SNFixJ/JNI";

static constexpr auto MODULE_DEX_PATH = "/data/adb/modules/safetynet-fix-jukmisael/classes.dex";

#define LOGD(...)     __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

#define LOGI(...)     __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...)     __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define LOGERRNO(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__ ": %d (%s)", errno, strerror(errno))

}
