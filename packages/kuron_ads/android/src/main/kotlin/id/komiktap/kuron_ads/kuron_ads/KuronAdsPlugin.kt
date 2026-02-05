package id.komiktap.kuron_ads.kuron_ads

import android.app.Activity
import com.startapp.sdk.adsbase.StartAppAd
import com.startapp.sdk.adsbase.StartAppSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** KuronAdsPlugin */
class KuronAdsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kuron_ads")
        channel.setMethodCallHandler(this)
        
        // Register Banner Factory
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "kuron_ads/banner",
            BannerNativeViewFactory()
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setTestAdsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                StartAppSDK.setTestAdsEnabled(enabled)
                result.success(null)
            }
            "showInterstitial" -> {
                if (activity != null) {
                    StartAppAd.showAd(activity)
                    result.success(true)
                } else {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware Implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
