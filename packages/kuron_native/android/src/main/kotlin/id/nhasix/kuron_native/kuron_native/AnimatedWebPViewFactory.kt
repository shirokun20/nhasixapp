package id.nhasix.kuron_native.kuron_native

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Factory that creates [AnimatedWebPView] instances for Flutter's PlatformView system. */
class AnimatedWebPViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        AnimatedWebPView(context, viewId, args)
}
