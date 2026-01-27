package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.view.MenuItem
import android.webkit.CookieManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat

class WebViewActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_URL = "extra_url"
        const val EXTRA_USER_AGENT = "extra_user_agent"
        const val EXTRA_SUCCESS_FILTERS = "extra_success_filters"
        const val EXTRA_INITIAL_COOKIE = "extra_initial_cookie"
        const val EXTRA_AUTO_CLOSE_ON_COOKIE = "extra_auto_close_on_cookie"

        const val EXTRA_CLEAR_COOKIES = "extra_clear_cookies"

        const val RESULT_COOKIES = "result_cookies" // ArrayList<String>
        const val RESULT_USER_AGENT = "result_user_agent"
        
        fun createIntent(
            context: Context, 
            url: String, 
            userAgent: String?, 
            successFilters: List<String>?,
            initialCookie: String?,
            autoCloseOnCookie: String? = null,
            clearCookies: Boolean = false
        ): Intent {
            return Intent(context, WebViewActivity::class.java).apply {
                putExtra(EXTRA_URL, url)
                if (userAgent != null) putExtra(EXTRA_USER_AGENT, userAgent)
                if (successFilters != null) putStringArrayListExtra(EXTRA_SUCCESS_FILTERS, ArrayList(successFilters))
                if (initialCookie != null) putExtra(EXTRA_INITIAL_COOKIE, initialCookie)
                if (autoCloseOnCookie != null) putExtra(EXTRA_AUTO_CLOSE_ON_COOKIE, autoCloseOnCookie)
                if (clearCookies) putExtra(EXTRA_CLEAR_COOKIES, true)
            }
        }
    }

    private lateinit var webView: WebView
    private var successFilters: List<String> = emptyList()
    private var autoCloseOnCookie: String? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable Edge-to-Edge (like PdfReaderActivity)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Use NoActionBar theme in Manifest, so we build our own layout
        // Root config
        val rootLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            layoutParams = android.view.ViewGroup.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.view.ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        
        // Handle System Insets (Status Bar)
        ViewCompat.setOnApplyWindowInsetsListener(rootLayout) { view, windowInsets ->
            val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            // Apply top padding so Toolbar doesn't overlap Status Bar
            view.setPadding(insets.left, insets.top, insets.right, insets.bottom) 
            WindowInsetsCompat.CONSUMED
        }

        // Toolbar
        val toolbar = androidx.appcompat.widget.Toolbar(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.util.TypedValue.applyDimension(
                    android.util.TypedValue.COMPLEX_UNIT_DIP, 
                    56f, 
                    resources.displayMetrics
                ).toInt()
            )
            setBackgroundColor(android.graphics.Color.parseColor("#FFFFFF")) // or fetch colorPrimary
            elevation = 4f
            translationZ = 4f
        }
        rootLayout.addView(toolbar)
        setSupportActionBar(toolbar)
        
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = "Login"

        // WebView
        webView = WebView(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f // Weight 1 to fill remaining space
            )
        }
        rootLayout.addView(webView)
        
        setContentView(rootLayout)

        val url = intent.getStringExtra(EXTRA_URL) ?: run {
            finish()
            return
        }
        val userAgent = intent.getStringExtra(EXTRA_USER_AGENT)
        val initialCookie = intent.getStringExtra(EXTRA_INITIAL_COOKIE)
        successFilters = intent.getStringArrayListExtra(EXTRA_SUCCESS_FILTERS) ?: emptyList()
        autoCloseOnCookie = intent.getStringExtra(EXTRA_AUTO_CLOSE_ON_COOKIE)

        // Sync Initial Cookies if provided
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        cookieManager.setAcceptThirdPartyCookies(webView, true)

        val clearCookies = intent.getBooleanExtra(EXTRA_CLEAR_COOKIES, false)
        if (clearCookies) {
             android.util.Log.i("KuronNative", "🧹 Clearing cookies requested.")
             cookieManager.removeAllCookies(null)
             cookieManager.flush()
        }

        if (initialCookie != null) {
            val domain = getDomainFromUrl(url)
            val cookies = initialCookie.split(";")
            for (cookie in cookies) {
                 cookieManager.setCookie(domain, cookie.trim())
            }
            cookieManager.flush()
        }

        with(webView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            if (userAgent != null) {
                userAgentString = userAgent
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                checkForSuccess(url)
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                checkForSuccess(url)
                
                // Update title
                view?.title?.let {
                    supportActionBar?.title = it
                }
                
                // Force sync cookies on page finish
                CookieManager.getInstance().flush()

                // Check for Auto-Close Cookie (Generic)
                if (autoCloseOnCookie != null) {
                    val cookies = CookieManager.getInstance().getCookie(url)
                    if (cookies != null && cookies.contains(autoCloseOnCookie!!)) {
                        android.util.Log.i("KuronNative", "✅ Auto-close cookie '$autoCloseOnCookie' detected! Closing WebView.")
                        finishWithSuccess(url ?: "")
                    }
                }
            }
        }

        webView.loadUrl(url)
    }
    
    private fun getDomainFromUrl(url: String): String {
        return try {
            val uri = android.net.Uri.parse(url)
            uri.host ?: url
        } catch (e: Exception) {
            url
        }
    }

    private fun checkForSuccess(url: String?) {
        if (url == null) return

        // 1. Check URL patterns if filters provided
        if (successFilters.isNotEmpty()) {
            for (filter in successFilters) {
                if (url.contains(filter)) {
                    finishWithSuccess(url)
                    return
                }
            }
        }
        
        // 2. Fallback or specific logic could go here
        // For Crotpedia, we might just rely on the user closing the activity 
        // OR the flutter side passing specific success URLs (like 'wp-admin').
    }

    private fun finishWithSuccess(currentUrl: String) {
        val cookieManager = CookieManager.getInstance()
        cookieManager.flush() // Ensure sync
        
        val cookies = cookieManager.getCookie(currentUrl) // Returns "key=value; key2=value2"
        android.util.Log.d("KuronNative", "WebView Finishing. URL: $currentUrl")
        android.util.Log.d("KuronNative", "Cookies found: $cookies")
        
        // Helper to get cookies for the base domain too if redirected
        // But getCookie(url) usually gets applicable cookies.
        
        val resultIntent = Intent()
        
        // We return the raw cookie string, let Dart parse it to list if needed
        // Or we can split it here.
        if (cookies != null) {
            val cookieList = ArrayList(cookies.split(";").map { it.trim() })
            resultIntent.putStringArrayListExtra(RESULT_COOKIES, cookieList)
        }
        
        resultIntent.putExtra(RESULT_USER_AGENT, webView.settings.userAgentString)
        
        setResult(Activity.RESULT_OK, resultIntent)
        finish()
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == android.R.id.home) {
            // Check for cookies even on manual close, 
            // incase user logged in but didn't trigger a specific URL filter
            finishWithSuccess(webView.url ?: "")
            return true
        }
        return super.onOptionsItemSelected(item)
    }
    
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            // Return validation on back press too
            finishWithSuccess(webView.url ?: "")
        }
    }
}
