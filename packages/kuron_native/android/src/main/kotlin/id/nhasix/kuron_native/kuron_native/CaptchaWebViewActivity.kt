package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebSettings
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat

class CaptchaWebViewActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PROVIDER = "extra_provider"
        const val EXTRA_SITE_KEY = "extra_site_key"
        const val EXTRA_BASE_URL = "extra_base_url"

        const val RESULT_SUCCESS = "result_success"
        const val RESULT_TOKEN = "result_token"
        const val RESULT_ERROR_CODE = "result_error_code"
        const val RESULT_ERROR_MESSAGE = "result_error_message"

        private const val MENU_RELOAD = 100

        fun createIntent(
            context: Context,
            provider: String,
            siteKey: String,
            baseUrl: String?
        ): Intent {
            return Intent(context, CaptchaWebViewActivity::class.java).apply {
                putExtra(EXTRA_PROVIDER, provider)
                putExtra(EXTRA_SITE_KEY, siteKey)
                putExtra(EXTRA_BASE_URL, baseUrl)
            }
        }
    }

    private lateinit var webView: WebView
    private lateinit var provider: String
    private lateinit var siteKey: String
    private lateinit var resolvedBaseUrl: String

    private var challengeErrorCode: String? = null
    private var challengeErrorMessage: String? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep toolbar/content below system status and navigation bars.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        provider = intent.getStringExtra(EXTRA_PROVIDER)?.trim().orEmpty()
        siteKey = intent.getStringExtra(EXTRA_SITE_KEY)?.trim().orEmpty()
        resolvedBaseUrl = normalizeBaseUrl(intent.getStringExtra(EXTRA_BASE_URL))

        if (provider.isEmpty() || siteKey.isEmpty()) {
            finishWithResult(
                success = false,
                errorCode = "invalid_args",
                errorMessage = "Missing provider or site key",
            )
            return
        }

        val root = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            layoutParams = android.view.ViewGroup.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }

        ViewCompat.setOnApplyWindowInsetsListener(root) { view, windowInsets ->
            val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(insets.left, insets.top, insets.right, insets.bottom)
            WindowInsetsCompat.CONSUMED
        }

        val toolbar = Toolbar(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.util.TypedValue.applyDimension(
                    android.util.TypedValue.COMPLEX_UNIT_DIP,
                    56f,
                    resources.displayMetrics,
                ).toInt(),
            )
            setBackgroundColor(android.graphics.Color.parseColor("#FFFFFF"))
            title = "Solve CAPTCHA"
        }
        root.addView(toolbar)

        webView = WebView(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f,
            )
        }
        root.addView(webView)

        setContentView(root)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        with(webView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            javaScriptCanOpenWindowsAutomatically = true
            useWideViewPort = true
            loadWithOverviewMode = true
            mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
        }

        webView.addJavascriptInterface(CaptchaBridge(), "AndroidCaptcha")
        webView.webChromeClient = WebChromeClient()
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                challengeErrorCode = null
                challengeErrorMessage = null
            }

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                super.onReceivedError(view, request, error)
                if (request?.isForMainFrame == true) {
                    challengeErrorCode = "resource_error"
                    challengeErrorMessage = error?.description?.toString() ?: "Unknown web resource error"
                }
            }

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                return false
            }
        }

        loadCaptchaHtml()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menu.add(0, MENU_RELOAD, 0, "Reload")
            .setIcon(android.R.drawable.ic_popup_sync)
            .setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finishWithResult(
                    success = false,
                    errorCode = challengeErrorCode,
                    errorMessage = challengeErrorMessage,
                )
                true
            }
            MENU_RELOAD -> {
                loadCaptchaHtml()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            finishWithResult(
                success = false,
                errorCode = challengeErrorCode,
                errorMessage = challengeErrorMessage,
            )
        }
    }

    private fun loadCaptchaHtml() {
        challengeErrorCode = null
        challengeErrorMessage = null
        webView.loadDataWithBaseURL(
            resolvedBaseUrl,
            buildCaptchaHtml(provider, siteKey),
            "text/html",
            "utf-8",
            null,
        )
    }

    private fun normalizeBaseUrl(baseUrl: String?): String {
        val value = baseUrl?.trim().orEmpty()
        if (value.isEmpty()) {
            return "https://localhost/"
        }

        return try {
            val uri = android.net.Uri.parse(value)
            if (uri.scheme.isNullOrEmpty() || uri.host.isNullOrEmpty()) {
                "https://localhost/"
            } else {
                "${uri.scheme}://${uri.host}"
            }
        } catch (_: Exception) {
            "https://localhost/"
        }
    }

    private fun buildCaptchaHtml(provider: String, siteKey: String): String {
        val lower = provider.lowercase()
        return if (lower.contains("turnstile")) {
            """
<!doctype html>
<html>
  <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
      body { font-family: sans-serif; padding: 16px; background: #fafafa; }
      .card { max-width: 460px; margin: 32px auto; background: #fff; border-radius: 12px; padding: 16px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }
      p { line-height: 1.4; }
    </style>
  </head>
  <body>
        <div class="card">
      <h3>Cloudflare Turnstile</h3>
      <p>Please complete the challenge. Token is submitted automatically.</p>
            <div class="cf-turnstile" data-sitekey="$siteKey" data-callback="onSolved" data-error-callback="onError" data-expired-callback="onExpired" data-retry="never"></div>
    </div>
    <script>
      function onSolved(token) {
        if (window.AndroidCaptcha && token) {
          window.AndroidCaptcha.postToken(token);
        }
      }
      function onError(code) {
        if (window.AndroidCaptcha) {
          window.AndroidCaptcha.postEvent('error:' + (code || 'unknown'));
        }
      }
      function onExpired() {
        if (window.AndroidCaptcha) {
          window.AndroidCaptcha.postEvent('error:expired');
        }
      }
    </script>
  </body>
</html>
""".trimIndent()
        } else if (lower.contains("hcaptcha")) {
            """
<!doctype html>
<html>
  <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <script src="https://js.hcaptcha.com/1/api.js" async defer></script>
    <style>
      body { font-family: sans-serif; padding: 16px; background: #fafafa; }
      .card { max-width: 460px; margin: 32px auto; background: #fff; border-radius: 12px; padding: 16px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }
      p { line-height: 1.4; }
    </style>
  </head>
  <body>
        <div class="card">
      <h3>hCaptcha</h3>
      <p>Please complete the challenge. Token is submitted automatically.</p>
            <div class="h-captcha" data-sitekey="$siteKey" data-callback="onSolved" data-expired-callback="onExpired"></div>
    </div>
    <script>
      function onSolved(token) {
        if (window.AndroidCaptcha && token) {
          window.AndroidCaptcha.postToken(token);
        }
      }
      function onExpired() {
        if (window.AndroidCaptcha) {
          window.AndroidCaptcha.postEvent('error:expired');
        }
      }
    </script>
  </body>
</html>
""".trimIndent()
        } else {
            """
<!doctype html>
<html>
    <body style="font-family:sans-serif;padding:16px;">
    <h3>Unsupported CAPTCHA Provider</h3>
    <p>Provider: $provider</p>
    <p>This provider is not yet supported in native solver.</p>
  </body>
</html>
""".trimIndent()
        }
    }

    private fun finishWithResult(
        success: Boolean,
        token: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null,
    ) {
        val intent = Intent().apply {
            putExtra(RESULT_SUCCESS, success)
            putExtra(RESULT_TOKEN, token)
            putExtra(RESULT_ERROR_CODE, errorCode)
            putExtra(RESULT_ERROR_MESSAGE, errorMessage)
        }
        setResult(Activity.RESULT_OK, intent)
        finish()
    }

    private inner class CaptchaBridge {
        @JavascriptInterface
        fun postToken(token: String?) {
            runOnUiThread {
                val normalized = token?.trim().orEmpty()
                if (normalized.isNotEmpty()) {
                    finishWithResult(success = true, token = normalized)
                }
            }
        }

        @JavascriptInterface
        fun postEvent(value: String?) {
            runOnUiThread {
                val payload = value?.trim().orEmpty()
                if (payload.startsWith("error:")) {
                    val code = payload.removePrefix("error:").trim().ifEmpty { "unknown" }
                    challengeErrorCode = code
                    challengeErrorMessage = "CAPTCHA challenge failed ($code)"
                }
            }
        }
    }
}
