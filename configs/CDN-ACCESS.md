# 🚀 How to Access Configs via CDN

## ✅ **Config Already on GitHub!**

Branch: `feat/multi-source-migration-phase-4`
Commit: `80dcb34`

## 📡 **CDN Access (jsdelivr)**

jsdelivr **automatically** mirrors GitHub repos. No upload needed!

### **URL Format:**
```
https://cdn.jsdelivr.net/gh/{user}/{repo}@{branch}/{path}
```

### **Your Config URLs:**

#### **1. nhentai Config**
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/nhentai-config.json
```

#### **2. Crotpedia Config**
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/crotpedia-config.json
```

#### **3. App Config**
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/app-config.json
```

#### **4. Tags Config**
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/tags-config.json
```

#### **5. Version Manifest**
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/version.json
```

## 🔄 **After Merge to Main:**

When you merge this branch to `main`, use:
```
https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@main/configs/nhentai-config.json
```

## ⚡ **CDN Benefits:**

1. **Auto-sync**: Push to GitHub → CDN updates automatically
2. **Global cache**: Faster downloads worldwide
3. **Free**: No cost, no limits
4. **HTTPS**: Secure by default
5. **Compression**: Automatic gzip support

## 🧪 **Test CDN Access:**

```bash
# Test nhentai config
curl https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/nhentai-config.json

# Test with compression
curl -H "Accept-Encoding: gzip" https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@feat/multi-source-migration-phase-4/configs/nhentai-config.json
```

## 📝 **Update Workflow:**

1. **Edit config locally**
   ```bash
   nano configs/nhentai-config.json
   ```

2. **Validate**
   ```bash
   ./configs/validate_configs.sh
   ```

3. **Commit & push**
   ```bash
   git add configs/
   git commit -m "Update nhentai API endpoints"
   git push
   ```

4. **CDN auto-updates** within seconds!

5. **App syncs** on next cache expiry (24h) or manual refresh

## 🎯 **Production Setup (After Merge):**

Update `version.json` URLs to use `@main`:
```json
{
  "configs": {
    "nhentai": {
      "url": "https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@main/configs/nhentai-config.json"
    }
  }
}
```

## 🔧 **Purge CDN Cache (if needed):**

jsdelivr caches for 7 days. To force refresh:
```
https://purge.jsdelivr.net/gh/shirokun20/nhasixapp@main/configs/nhentai-config.json
```

---

**Status**: ✅ Configs pushed to GitHub
**Branch**: feat/multi-source-migration-phase-4  
**CDN**: Ready to use!
