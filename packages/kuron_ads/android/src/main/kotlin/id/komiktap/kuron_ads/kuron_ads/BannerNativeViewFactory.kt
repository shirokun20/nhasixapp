package id.komiktap.kuron_ads.kuron_ads

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BannerNativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    private var activity: Activity? = null

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return BannerNativeView(context, activity, viewId, creationParams)
    }
}
