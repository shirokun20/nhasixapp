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

class WebViewActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_URL = "extra_url"
        const val EXTRA_USER_AGENT = "extra_user_agent"
        const val EXTRA_SUCCESS_FILTERS = "extra_success_filters"
        const val EXTRA_INITIAL_COOKIE = "extra_initial_cookie"

        const val RESULT_COOKIES = "result_cookies" // ArrayList<String>
        const val RESULT_USER_AGENT = "result_user_agent"
        
        fun createIntent(
            context: Context, 
            url: String, 
            userAgent: String?, 
            successFilters: List<String>?,
            initialCookie: String?
        ): Intent {
            return Intent(context, WebViewActivity::class.java).apply {
                putExtra(EXTRA_URL, url)
                if (userAgent != null) putExtra(EXTRA_USER_AGENT, userAgent)
                if (successFilters != null) putStringArrayListExtra(EXTRA_SUCCESS_FILTERS, ArrayList(successFilters))
                if (initialCookie != null) putExtra(EXTRA_INITIAL_COOKIE, initialCookie)
            }
        }
    }

    private lateinit var webView: WebView
    private var successFilters: List<String> = emptyList()

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Setup ActionBar
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = "Login"

        webView = WebView(this)
        setContentView(webView)

        val url = intent.getStringExtra(EXTRA_URL) ?: run {
            finish()
            return
        }
        val userAgent = intent.getStringExtra(EXTRA_USER_AGENT)
        val initialCookie = intent.getStringExtra(EXTRA_INITIAL_COOKIE)
        successFilters = intent.getStringArrayListExtra(EXTRA_SUCCESS_FILTERS) ?: emptyList()

        // Sync Initial Cookies if provided
        if (initialCookie != null) {
            val cookieManager = CookieManager.getInstance()
            cookieManager.setAcceptCookie(true)
            // Initial cookie string might be "key=value; key2=value2"
            // setCookie expects one at a time usually, but let's try to parse or set for domain
            // Here we assume the URL domain is the target.
            // A robust parsing might be needed if multiple domains, but usually it's for the target URL.
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
        val cookies = cookieManager.getCookie(currentUrl) // Returns "key=value; key2=value2"
        
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
