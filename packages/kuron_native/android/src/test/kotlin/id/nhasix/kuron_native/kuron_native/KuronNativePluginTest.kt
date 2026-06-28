package id.nhasix.kuron_native.kuron_native

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import id.nhasix.kuron_native.kuron_native.network.DnsResolver

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class KuronNativePluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = KuronNativePlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun onMethodCall_setDohProvider_invokesResolverAndReturnsTrue() {
        val plugin = KuronNativePlugin()
        val mockResolver = Mockito.mock(DnsResolver::class.java)

        // Inject mock resolver via reflection (avoids Robolectric/Context dependency)
        val resolverField = KuronNativePlugin::class.java.getDeclaredField("dnsResolver")
        resolverField.isAccessible = true
        resolverField.set(plugin, mockResolver)

        val call = MethodCall("setDohProvider", mapOf("provider" to 1))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResolver).setDohProvider(1)
        Mockito.verify(mockResult).success(true)
    }

    @Test
    fun onMethodCall_getDohProvider_invokesResolverAndReturnsInt() {
        val plugin = KuronNativePlugin()
        val mockResolver = Mockito.mock(DnsResolver::class.java)

        val resolverField = KuronNativePlugin::class.java.getDeclaredField("dnsResolver")
        resolverField.isAccessible = true
        resolverField.set(plugin, mockResolver)
        Mockito.`when`(mockResolver.getDohProvider()).thenReturn(2)

        val call = MethodCall("getDohProvider", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResolver).getDohProvider()
        Mockito.verify(mockResult).success(2)
    }
}
