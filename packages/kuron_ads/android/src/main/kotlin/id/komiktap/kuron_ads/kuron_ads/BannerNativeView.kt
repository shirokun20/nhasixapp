package id.komiktap.kuron_ads.kuron_ads

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import com.startapp.sdk.ads.banner.Banner
import com.startapp.sdk.ads.banner.BannerListener
import io.flutter.plugin.platform.PlatformView

class BannerNativeView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val container: FrameLayout = FrameLayout(context)
    private var banner: Banner? = null

    init {
        // Setup container with gravity center
        container.setBackgroundColor(Color.TRANSPARENT)
        
        // Initialize Start.io Banner
        banner = Banner(context)
        val params = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        params.gravity = Gravity.CENTER
        
        // Add listener for debug logging
        banner?.setBannerListener(object : BannerListener {
            override fun onReceiveAd(p0: View?) {
                println("KuronAds: Banner Ad Received")
            }
            override fun onFailedToReceiveAd(p0: View?) {
                println("KuronAds: Banner Ad Failed to Receive")
            }
            override fun onClick(p0: View?) {}
            override fun onImpression(p0: View?) {}
        })

        container.addView(banner, params)
        banner?.loadAd()
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        banner?.hideBanner()
    }
}
