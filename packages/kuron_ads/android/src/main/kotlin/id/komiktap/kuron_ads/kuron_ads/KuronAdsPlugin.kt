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

import com.startapp.sdk.adsbase.Ad
import com.startapp.sdk.adsbase.adlisteners.AdDisplayListener
import com.startapp.sdk.adsbase.adlisteners.AdEventListener

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
                val currentActivity = activity
                if (currentActivity != null) {
                    val startAppAd = StartAppAd(currentActivity)
                    // Load ad with listener to know when to show
                    startAppAd.loadAd(object : AdEventListener {
                        override fun onReceiveAd(ad: Ad) {
                            // Ad received, now show it with display listener
                            startAppAd.showAd(object : AdDisplayListener {
                                override fun adHidden(ad: Ad) {
                                    result.success(true)
                                }

                                override fun adDisplayed(ad: Ad) {}

                                override fun adClicked(ad: Ad) {}

                                override fun adNotDisplayed(ad: Ad) {
                                    result.success(false)
                                }
                            })
                        }

                        override fun onFailedToReceiveAd(ad: Ad?) {
                            result.success(false)
                        }
                    })
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
