package dev.kdrag0n.safetynetfix

import dev.kdrag0n.safetynetfix.proxy.ProxyKeyStoreSpi
import dev.kdrag0n.safetynetfix.proxy.ProxyProvider
import java.security.KeyStore
import java.security.KeyStoreSpi
import java.security.Security

internal object SecurityHooks {
    private const val ANDROID_KEY_STORE = "AndroidKeyStore"

    fun init() {
        val realProvider = Security.getProvider(ANDROID_KEY_STORE)
        val realKeystore = KeyStore.getInstance(ANDROID_KEY_STORE)
        val realSpi = realKeystore?.getKeyStoreSpi()

        if (realProvider != null && realKeystore != null && realSpi != null) {
            Security.removeProvider(ANDROID_KEY_STORE)
            Security.insertProviderAt(ProxyProvider(realProvider), 1)
            ProxyKeyStoreSpi.androidImpl = realSpi
            Log.i("SecurityHooks","Security hooks installed")
        } else {
            // Log an error message indicating that the expected objects were not found
            Log.e("SecurityHooks","Security hooks not installed, provider, keystore or spi not found")
        }
    }
}
