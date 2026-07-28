package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabsIntent

class CustomTabFallbackActivity : AppCompatActivity() {

    companion object {
        const val TAG = "CustomTabFallback"
        const val EXTRA_URL = "extra_url"

        const val RESULT_COOKIES = "result_cookies"
        const val RESULT_URL = "result_url"

        fun createIntent(context: Context, url: String): Intent {
            return Intent(context, CustomTabFallbackActivity::class.java).apply {
                putExtra(EXTRA_URL, url)
            }
        }
    }

    private var hasBeenStopped = false
    private var finished = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent.getStringExtra(EXTRA_URL)
        if (url.isNullOrBlank()) {
            android.util.Log.w(TAG, "No URL provided, finishing.")
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }

        android.util.Log.i(TAG, "Launching Chrome Custom Tab for: $url")

        try {
            val builder = CustomTabsIntent.Builder()
            val customTabsIntent = builder.build()
            customTabsIntent.launchUrl(this, Uri.parse(url))
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to launch Custom Tab: ${e.message}")
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    override fun onStop() {
        super.onStop()
        hasBeenStopped = true
    }

    override fun onResume() {
        super.onResume()
        if (hasBeenStopped && !finished) {
            finished = true
            Handler(Looper.getMainLooper()).postDelayed({
                if (!isFinishing && !isDestroyed) {
                    extractCookiesAndFinish()
                }
            }, 500)
        }
    }

    private fun extractCookiesAndFinish() {
        val url = intent.getStringExtra(EXTRA_URL) ?: ""
        val cookieManager = CookieManager.getInstance()
        cookieManager.flush()

        val rawCookies = cookieManager.getCookie(url) ?: ""
        val cookieList = ArrayList(
            rawCookies.split(";").map { it.trim() }.filter { it.isNotBlank() }
        )

        android.util.Log.i(TAG, "Extracted ${cookieList.size} cookie(s) for $url")

        val resultIntent = Intent().apply {
            putStringArrayListExtra(RESULT_COOKIES, cookieList)
            putExtra(RESULT_URL, url)
        }
        setResult(Activity.RESULT_OK, resultIntent)
        finish()
    }
}
