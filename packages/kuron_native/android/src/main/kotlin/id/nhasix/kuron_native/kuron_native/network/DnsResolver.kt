package id.nhasix.kuron_native.kuron_native.network

import android.content.Context
import android.content.SharedPreferences
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

class DnsResolver(
    private val context: Context,
    private val prefs: SharedPreferences,
) {
    companion object {
        private const val PREF_DOH_PROVIDER = "doh_provider"
        private const val DEFAULT_DOH_PROVIDER = -1 // Disabled by default
    }

    private var cachedClient: OkHttpClient? = null
    private var cachedProvider: Int = -2 // Sentinel to detect changes

    fun getHttpClient(): OkHttpClient {
        val currentProvider = prefs.getInt(PREF_DOH_PROVIDER, DEFAULT_DOH_PROVIDER)

        // Return cached client if provider hasn't changed
        if (cachedClient != null && cachedProvider == currentProvider) {
            return cachedClient!!
        }

        // Build new client with current provider
        val builder = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .callTimeout(2, TimeUnit.MINUTES)

        when (currentProvider) {
            PREF_DOH_CLOUDFLARE -> builder.dohCloudflare()
            PREF_DOH_GOOGLE -> builder.dohGoogle()
            PREF_DOH_ADGUARD -> builder.dohAdGuard()
            PREF_DOH_QUAD9 -> builder.dohQuad9()
            else -> builder // No DoH, use default DNS
        }

        val client = builder.build()
        cachedClient = client
        cachedProvider = currentProvider
        return client
    }

    fun setDohProvider(provider: Int) {
        prefs.edit().putInt(PREF_DOH_PROVIDER, provider).apply()
        cachedClient?.dispatcher?.executorService?.shutdown()
        cachedClient = null
        cachedProvider = -2
    }

    fun getDohProvider(): Int = prefs.getInt(PREF_DOH_PROVIDER, DEFAULT_DOH_PROVIDER)

    fun clearCache() {
        cachedClient?.dispatcher?.executorService?.shutdown()
        cachedClient = null
        cachedProvider = -2
    }
}
