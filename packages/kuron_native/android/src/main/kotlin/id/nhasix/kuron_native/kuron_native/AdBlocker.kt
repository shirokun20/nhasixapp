package id.nhasix.kuron_native.kuron_native

import android.net.Uri

object AdBlocker {
    // A small subset of common ad/tracking domains for demonstration.
    // In a real production app, this should be loaded from a file or API.
    private val AD_HOSTS = setOf(
        "doubleclick.net",
        "googleadservices.com",
        "googlesyndication.com",
        "adservice.google.com",
        "adnxs.com",
        "criteo.com",
        "rubiconproject.com",
        "taboola.com",
        "outbrain.com",
        "popads.net",
        "propellerads.com",
        "adroll.com",
        "adcolony.com",
        "unityads.unity3d.com",
        "applovin.com",
        "vungle.com",
        "chartboost.com",
        "flurry.com",
        "mopub.com",
        "tapjoy.com",
        "ironsrc.com",
        // Analytics
        "google-analytics.com",
        "analytics.google.com",
        "googletagmanager.com",
        "facebook.com/tr",
        "connect.facebook.net",
        // Adult / Gambling keywords in host (simplified check)
        "bet365", "poker", "casino", "slot",
        "porn", "xxx", "sex", "adult"
    )

    fun isAd(url: String?): Boolean {
        if (url == null) return false
        
        val host = Uri.parse(url).host?.lowercase() ?: return false
        
        // 1. Direct Host Match
        if (AD_HOSTS.contains(host)) return true
        
        // 2. Contains Keyword (Naive but effective for some)
        for (keyword in AD_HOSTS) {
            if (host.contains(keyword)) return true
        }

        return false
    }
}
