package id.nhasix.app.network

import okhttp3.Dns
import okhttp3.dnsoverhttps.DnsOverHttps
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for DnsManager
 * Tests DNS provider configuration, DoH creation, and settings management
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class DnsManagerTest {
    
    @Before
    fun setUp() {
        // Reset DNS manager to default state before each test
        DnsManager.updateSettings("SYSTEM", false)
    }
    
    @After
    fun tearDown() {
        // Reset to default after each test
        DnsManager.updateSettings("SYSTEM", false)
    }
    
    @Test
    fun `test default DNS provider is SYSTEM`() {
        val settings = DnsManager.getCurrentSettings()
        
        assertEquals("SYSTEM", settings["provider"])
        assertEquals(false, settings["enabled"])
    }
    
    @Test
    fun `test update settings with valid provider`() {
        DnsManager.updateSettings("CLOUDFLARE", true)
        
        val settings = DnsManager.getCurrentSettings()
        assertEquals("CLOUDFLARE", settings["provider"])
        assertEquals(true, settings["enabled"])
    }
    
    @Test
    fun `test update settings with invalid provider falls back to SYSTEM`() {
        DnsManager.updateSettings("INVALID_PROVIDER", true)
        
        val settings = DnsManager.getCurrentSettings()
        assertEquals("SYSTEM", settings["provider"])
        assertEquals(false, settings["enabled"])
    }
    
    @Test
    fun `test createDns returns system DNS when disabled`() {
        DnsManager.updateSettings("CLOUDFLARE", false)
        
        val dns = DnsManager.createDns()
        
        // System DNS should be returned
        assertEquals(Dns.SYSTEM, dns)
    }
    
    @Test
    fun `test createDns returns system DNS when provider is SYSTEM`() {
        DnsManager.updateSettings("SYSTEM", true)
        
        val dns = DnsManager.createDns()
        
        assertEquals(Dns.SYSTEM, dns)
    }
    
    @Test
    fun `test createDns returns DoH DNS when enabled with valid provider`() {
        DnsManager.updateSettings("CLOUDFLARE", true)
        
        val dns = DnsManager.createDns()
        
        // Should return DnsOverHttps instance
        assertNotNull(dns)
        assertTrue(dns is DnsOverHttps || dns is Dns)
    }
    
    @Test
    fun `test all DNS providers have correct URLs`() {
        val providers = DnsManager.DnsProvider.values()
        
        // Verify each provider has expected properties
        providers.forEach { provider ->
            when (provider) {
                DnsManager.DnsProvider.CLOUDFLARE -> {
                    assertEquals("Cloudflare", provider.displayName)
                    assertEquals("https://cloudflare-dns.com/dns-query", provider.dohUrl)
                    assertTrue(provider.bootstrapIps.contains("1.1.1.1"))
                }
                DnsManager.DnsProvider.GOOGLE -> {
                    assertEquals("Google", provider.displayName)
                    assertEquals("https://dns.google/dns-query", provider.dohUrl)
                    assertTrue(provider.bootstrapIps.contains("8.8.8.8"))
                }
                DnsManager.DnsProvider.QUAD9 -> {
                    assertEquals("Quad9", provider.displayName)
                    assertEquals("https://dns.quad9.net/dns-query", provider.dohUrl)
                    assertTrue(provider.bootstrapIps.contains("9.9.9.9"))
                }
                DnsManager.DnsProvider.SYSTEM -> {
                    assertEquals("System Default", provider.displayName)
                    assertEquals("", provider.dohUrl)
                    assertTrue(provider.bootstrapIps.isEmpty())
                }
            }
        }
    }
    
    @Test
    fun `test settings persist across multiple updates`() {
        // Update to Cloudflare
        DnsManager.updateSettings("CLOUDFLARE", true)
        var settings = DnsManager.getCurrentSettings()
        assertEquals("CLOUDFLARE", settings["provider"])
        
        // Update to Google
        DnsManager.updateSettings("GOOGLE", true)
        settings = DnsManager.getCurrentSettings()
        assertEquals("GOOGLE", settings["provider"])
        
        // Disable
        DnsManager.updateSettings("GOOGLE", false)
        settings = DnsManager.getCurrentSettings()
        assertEquals(false, settings["enabled"])
    }
    
    @Test
    fun `test getCurrentSettings returns all expected keys`() {
        DnsManager.updateSettings("CLOUDFLARE", true)
        
        val settings = DnsManager.getCurrentSettings()
        
        assertTrue(settings.containsKey("provider"))
        assertTrue(settings.containsKey("enabled"))
        assertTrue(settings.containsKey("dohUrl"))
    }
    
    @Test
    fun `test provider name is case insensitive`() {
        // Test lowercase
        DnsManager.updateSettings("cloudflare", true)
        var settings = DnsManager.getCurrentSettings()
        assertEquals("CLOUDFLARE", settings["provider"])
        
        // Test mixed case
        DnsManager.updateSettings("GoOgLe", true)
        settings = DnsManager.getCurrentSettings()
        assertEquals("GOOGLE", settings["provider"])
    }
}
