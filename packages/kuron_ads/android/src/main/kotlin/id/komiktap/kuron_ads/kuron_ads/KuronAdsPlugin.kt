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
import com.startapp.sdk.adsbase.StartAppAd.AdMode
import com.startapp.sdk.adsbase.adlisteners.AdDisplayListener
import com.startapp.sdk.adsbase.adlisteners.AdEventListener
import com.startapp.sdk.adsbase.adlisteners.VideoListener
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build

/** KuronAdsPlugin */
class KuronAdsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var bannerFactory: BannerNativeViewFactory

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kuron_ads")
        channel.setMethodCallHandler(this)
        
        // Register Banner Factory
        bannerFactory = BannerNativeViewFactory()
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "kuron_ads/banner",
            bannerFactory
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val appId = call.argument<String>("appId")
                val testMode = call.argument<Boolean>("testMode") ?: false
                val currentActivity = activity
                
                if (appId != null && currentActivity != null) {
                    try {
                        // Initialize StartApp SDK
                        StartAppSDK.init(currentActivity, appId, true)
                        StartAppSDK.setTestAdsEnabled(testMode)
                        StartAppAd.disableSplash()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", e.message, null)
                    }
                } else {
                     if (appId == null) {
                        result.error("INVALID_ARGS", "App ID is required", null)
                     } else {
                        result.error("NO_ACTIVITY", "Activity is null", null)
                     }
                }
            }
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
                    startAppAd.loadAd(StartAppAd.AdMode.AUTOMATIC, object : AdEventListener {
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
            "showRewardedVideo" -> {
                val currentActivity = activity
                if (currentActivity != null) {
                    val startAppAd = StartAppAd(currentActivity)
                    
                    // Gunakan variabel state untuk mencegah double result
                    var isResultSent = false

                    startAppAd.setVideoListener(VideoListener {
                        if (!isResultSent) {
                            isResultSent = true
                            result.success(true) // Video berhasil ditonton sampai selesai
                        }
                    })

                    startAppAd.loadAd(StartAppAd.AdMode.REWARDED_VIDEO, object : AdEventListener {
                        override fun onReceiveAd(ad: Ad) {
                            startAppAd.showAd(object : AdDisplayListener {
                                override fun adHidden(ad: Ad) {
                                    // Iklan ditutup (bisa karena selesai atau di-skip)
                                    if (!isResultSent) {
                                        isResultSent = true
                                        result.success(false) // Dianggap false jika belum selesai
                                    }
                                }
                                override fun adDisplayed(ad: Ad) {}
                                override fun adClicked(ad: Ad) {}
                                override fun adNotDisplayed(ad: Ad) { 
                                    if (!isResultSent) {
                                        isResultSent = true
                                        result.success(false) 
                                    }
                                }
                            })
                        }
                        override fun onFailedToReceiveAd(ad: Ad?) { 
                            if (!isResultSent) {
                                isResultSent = true
                                result.success(false) 
                            }
                        }
                    })
                } else {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                }
            }
            "checkPrivateDns" -> {
                val currentActivity = activity
                if (currentActivity != null) {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            val cm = currentActivity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                            val network = cm.activeNetwork
                            val linkProps = cm.getLinkProperties(network)
                            val dns = linkProps?.privateDnsServerName ?: ""
                            result.success(dns)
                        } else {
                            result.success("")
                        }
                    } catch (e: Exception) {
                        result.success("")
                    }
                } else {
                    result.success("")
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
        if (this::bannerFactory.isInitialized) {
            bannerFactory.setActivity(binding.activity)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        if (this::bannerFactory.isInitialized) {
            bannerFactory.setActivity(null)
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (this::bannerFactory.isInitialized) {
            bannerFactory.setActivity(binding.activity)
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
        if (this::bannerFactory.isInitialized) {
            bannerFactory.setActivity(null)
        }
    }
}
