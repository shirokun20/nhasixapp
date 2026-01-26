package id.nhasix.app.network

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber

/**
 * MethodChannel for DNS settings synchronization between Flutter and Native
 */
class DnsMethodChannel(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "id.nhasix.app/dns")
    
    companion object {
        private const val TAG = "DnsMethodChannel"
        private const val METHOD_UPDATE_SETTINGS = "updateDnsSettings"
        private const val METHOD_GET_SETTINGS = "getDnsSettings"
    }
    
    init {
        channel.setMethodCallHandler(this)
        Timber.tag(TAG).d("DNS MethodChannel initialized")
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_UPDATE_SETTINGS -> handleUpdateSettings(call, result)
            METHOD_GET_SETTINGS -> handleGetSettings(result)
            else -> result.notImplemented()
        }
    }
    
    /**
     * Update DNS settings from Flutter
     * Expected arguments:
     * - provider: String (SYSTEM, CLOUDFLARE, GOOGLE, QUAD9)
     * - enabled: Boolean
     */
    private fun handleUpdateSettings(call: MethodCall, result: MethodChannel.Result) {
        try {
            val provider = call.argument<String>("provider") ?: "SYSTEM"
            val enabled = call.argument<Boolean>("enabled") ?: false
            
            Timber.tag(TAG).d("Updating DNS settings: provider=$provider, enabled=$enabled")
            
            DnsManager.updateSettings(provider, enabled)
            
            result.success(null)
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to update DNS settings")
            result.error("DNS_UPDATE_ERROR", e.message, null)
        }
    }
    
    /**
     * Get current DNS settings
     */
    private fun handleGetSettings(result: MethodChannel.Result) {
        try {
            val settings = DnsManager.getCurrentSettings()
            result.success(settings)
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Failed to get DNS settings")
            result.error("DNS_GET_ERROR", e.message, null)
        }
    }
}
