#include <jni.h>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <android/log.h>

#include <riru.h>
#include <malloc.h>
#include <config.h>

#include <memory>

#define  LOG_TAG    "SafetynetRiru/JNI"
#ifndef NDEBUG
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#else
#define  LOGD(...)
#endif

const char* const UNSTABLE_PROCESS = "com.google.android.gms.unstable";
const char* const ENTRY_CLASS_NAME = "dev.kdrag0n.safetynetriru.EntryPoint";

class SafetyNet {
public:
    SafetyNet(JNIEnv* env, jstring niceName)
    {
        const std::string processName = env->GetStringUTFChars(niceName, nullptr);
        mSpecializePending = (processName == UNSTABLE_PROCESS);
        env->ReleaseStringUTFChars(niceName, processName.c_str());
    }

    void specialize(JNIEnv* env)
    {
        if (!mModuleDex || !mSpecializePending) {
            riru_set_unload_allowed(true);
            return;
        }

        // First, get the system classloader
        jclass clClass = env->FindClass("java/lang/ClassLoader");
        jmethodID getSystemClassLoader = env->GetStaticMethodID(clClass, "getSystemClassLoader", "()Ljava/lang/ClassLoader;");
        jobject systemClassLoader = env->CallStaticObjectMethod(clClass, getSystemClassLoader);

        // Assuming we have a valid mapped module, load it.
        jobject buf = env->NewDirectByteBuffer(mModuleDex.get(), mModuleDexSize);
        jclass dexClClass = env->FindClass("dalvik/system/InMemoryDexClassLoader");
        jmethodID dexClInit = env->GetMethodID(dexClClass, "<init>", "(Ljava/nio/ByteBuffer;Ljava/lang/ClassLoader;)V");
        jobject dexCl = env->NewObject(dexClClass, dexClInit, buf, systemClassLoader);

        // Load the class
        jmethodID loadClass = env->GetMethodID(clClass, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
        jstring entryClassName = env->NewStringUTF(ENTRY_CLASS_NAME);
        jobject entryClassObj = env->CallObjectMethod(dexCl, loadClass, entryClassName);

                // Call init. Static initializers don't run when merely calling loadClass from JNI.
        jclass entryClass = static_cast<jclass>(entryClassObj);
        jmethodID entryInit = env->GetStaticMethodID(entryClass, "init", "()V");
        env->CallStaticVoidMethod(entryClass, entryInit);
        LOGD("Specialization complete");
    }

    void setModule(std::unique_ptr<void, decltype(munmap)*> moduleDex, ssize_t moduleDexSize)
    {
        mModuleDex = std::move(moduleDex);
        mModuleDexSize = moduleDexSize;
    }

private:
    bool mSpecializePending = false;
    std::unique_ptr<void, decltype(munmap)*> mModuleDex;
    ssize_t mModuleDexSize = 0;
};

extern "C" {
    JNIEXPORT void JNICALL Java_dev_kdrag0n_safetynetriru_Main_updateNiceName(JNIEnv* env, jobject, jstring niceName)
    {
        static SafetyNet safetyNet(env, niceName);
        safetyNet.updateNiceName(env, niceName);
    }

    JNIEXPORT void JNICALL Java_dev_kdrag0n_safetynetriru_Main_specializeCommon(JNIEnv* env)
    {
        static SafetyNet safetyNet(env, nullptr);
        safetyNet.specialize(env);
    }

    JNIEXPORT void JNICALL Java_dev_kdrag0n_safetynetriru_Main_loadModule(JNIEnv* env, jclass, jstring path)
    {
        static SafetyNet safetyNet(env, nullptr);
        const char* filePath = env->GetStringUTFChars(path, nullptr);
        int fd = open(filePath, O_RDONLY);
        if (fd < 0) {
            LOGD("Failed to open file: %s", filePath);
            return;
        }

        // Get size
        ssize_t fileSize = lseek(fd, 0, SEEK_END);
        if (fileSize < 0) {
            LOGD("Failed to seek file: %s", filePath);
            return;
        }

        void* module = mmap(nullptr, fileSize, PROT_READ, MAP_PRIVATE, fd, 0);
        if (module == MAP_FAILED) {
            LOGD("Failed to mmap file: %s", filePath);
            return;
        }

        safetyNet.setModule(std::unique_ptr<void, decltype(munmap)*>{module, munmap}, fileSize);
        LOGD("Module loaded successfully");
    }
}
