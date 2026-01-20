package id.nhasix.app.network

import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.dnsoverhttps.DnsOverHttps
import okhttp3.Dns
import timber.log.Timber
import java.net.InetAddress

/**
 * DNS Manager for native downloads with DNS-over-HTTPS support
 * Provides custom DNS resolution for OkHttp clients used in DownloadWorker
 */
object DnsManager {
    private const val TAG = "DnsManager"
    
    /**
     * DNS Provider options
     */
    enum class DnsProvider(
        val displayName: String,
        val dohUrl: String,
        val bootstrapIps: List<String>
    ) {
        SYSTEM("System Default", "", emptyList()),
        CLOUDFLARE("Cloudflare", "https://cloudflare-dns.com/dns-query", listOf("1.1.1.1", "1.0.0.1")),
        GOOGLE("Google", "https://dns.google/dns-query", listOf("8.8.8.8", "8.8.4.4")),
        QUAD9("Quad9", "https://dns.quad9.net/dns-query", listOf("9.9.9.9", "149.112.112.112"))
    }
    
    /**
     * Current DNS configuration
     */
    private var currentProvider: DnsProvider = DnsProvider.SYSTEM
    private var isEnabled: Boolean = false
    
    /**
     * Update DNS settings from Flutter
     */
    fun updateSettings(providerName: String, enabled: Boolean) {
        try {
            currentProvider = DnsProvider.valueOf(providerName.uppercase())
            isEnabled = enabled
            Timber.tag(TAG).i("DNS settings updated: provider=$providerName, enabled=$enabled")
        } catch (e: IllegalArgumentException) {
            Timber.tag(TAG).e(e, "Invalid DNS provider: $providerName, falling back to SYSTEM")
            currentProvider = DnsProvider.SYSTEM
            isEnabled = false
        }
    }
    
    /**
     * Create DNS instance based on current settings
     * Returns either DoH DNS or system DNS
     */
    fun createDns(): Dns {
        return if (isEnabled && currentProvider != DnsProvider.SYSTEM) {
            createDohDns(currentProvider)
        } else {
            Timber.tag(TAG).d("Using system DNS")
            Dns.SYSTEM
        }
    }
    
    /**
     * Create DNS-over-HTTPS resolver for specified provider
     */
    private fun createDohDns(provider: DnsProvider): Dns {
        Timber.tag(TAG).i("Creating DoH DNS for provider: ${provider.displayName}")
        
        return try {
            // Create bootstrap OkHttp client for DoH queries
            val bootstrapClient = OkHttpClient.Builder()
                .build()
            
            // Create DoH DNS instance
            DnsOverHttps.Builder()
                .client(bootstrapClient)
                .url(provider.dohUrl.toHttpUrl())
                .bootstrapDnsHosts(getBootstrapAddresses(provider))
                .build()
                .also {
                    Timber.tag(TAG).d("DoH DNS created successfully for ${provider.displayName}")
                }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to create DoH DNS, falling back to system DNS")
            Dns.SYSTEM
        }
    }
    
    /**
     * Get bootstrap DNS server addresses for the provider
     * These are used to resolve the DoH server itself
     */
    private fun getBootstrapAddresses(provider: DnsProvider): List<InetAddress> {
        return provider.bootstrapIps.mapNotNull { ip ->
            try {
                InetAddress.getByName(ip)
            } catch (e: Exception) {
                Timber.tag(TAG).w(e, "Failed to parse bootstrap IP: $ip")
                null
            }
        }.also { addresses ->
            Timber.tag(TAG).d("Bootstrap addresses: ${addresses.size} for ${provider.displayName}")
        }
    }
    
    /**
     * Get current DNS settings as map (for debugging)
     */
    fun getCurrentSettings(): Map<String, Any> {
        return mapOf(
            "provider" to currentProvider.name,
            "enabled" to isEnabled,
            "dohUrl" to currentProvider.dohUrl
        )
    }
}
