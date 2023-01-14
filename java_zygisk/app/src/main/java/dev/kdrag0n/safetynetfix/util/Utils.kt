package dev.kdrag0n.safetynetfixjukmisael

import android.app.Application
import android.util.Log

private const val DEBUG = true
private const val TAG = "SNFixJ/Java"

internal fun <T> Any.get(name: String) = this::class.java.getDeclaredField(name).let { field ->
    field.isAccessible = true
    @Suppress("unchecked_cast")
    field.get(this) as T
}

internal fun logDebug(msg: String) {
    if (DEBUG) {
        Log.d(TAG, "[${Application.getProcessName()}] $msg")
    }
}

internal fun logDebug(msg: String, e: Throwable) {
    if (DEBUG) {
        Log.d(TAG, "[${Application.getProcessName()}] $msg", e)
    }
}
