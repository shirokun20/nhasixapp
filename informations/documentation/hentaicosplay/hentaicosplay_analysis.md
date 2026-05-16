# Hentai Cosplay - HTML-Verified Analysis (Updated)

## Source Files Used
- `html-halaman-utama.html`
- `html-halaman-search.html`
- `html-halaman-reader-dan-detail.html`

## URL from HTML Top Line
- Home sample: `https://hentai-cosplay-xxx.com/search/`
- Search sample: `https://hentai-cosplay-xxx.com/search/keyword/machi/`
- Detail/reader sample: `https://hentai-cosplay-xxx.com/image/meenfox-elegg-1/`

---

## 1) List/Home/Search Structure (VERIFIED)

### Real container pattern
```html
<ul id="image-list" class="clearfix">
  <li>
    <div class="image-list-item">
      <div class="image-list-item-image">
        <a href="/image/.../"><img src="..." alt="..." /></a>
      </div>
      <p class="image-list-item-title"><a href="/image/.../">TITLE</a></p>
      <p class="image-list-item-regist-date"><span>YYYY/MM/DD</span></p>
    </div>
  </li>
</ul>
```

### Correct extraction
- `container`: `#image-list > li .image-list-item`
- `id` (slug): `.image-list-item-title a[href*='/image/']` attribute `href`
- `title`: `.image-list-item-title a` textContent
- `coverUrl`: `.image-list-item-image img` attribute `src`
- `date` (optional): `.image-list-item-regist-date span` textContent

### Pagination (VERIFIED)
```html
<div class="wp-pagenavi">
  <a class="nextpostslink" rel="next" href="...">Next ></a>
</div>
```
- `next`: `.wp-pagenavi a.nextpostslink[rel='next']`

---

## 2) Search URL Patterns (VERIFIED)

- Base list page: `/search/`
- Paged base list: `/search/page/{page}/`
- Keyword search: `/search/keyword/{query}/`
- Keyword search page: `/search/keyword/{query}/page/{page}/`
- Tag page (from detail tags): `/search/tag/{tag}/`

---

## 3) Detail Structure (VERIFIED)

### Real title/tags
```html
<span id="title"><h2>Meenfox – Elegg 1</h2></span>
<p id="detail_tag">
  <span>Tag List:</span>
  <span><a href="/search/tag/meenfox/">Meenfox</a></span>
</p>
```

### Correct extraction
- `title`: `#title h2`
- `tags`: `#detail_tag a[href*='/search/tag/']` (multi)

---

## 4) Reader Images Structure (VERIFIED)

### Real image block
```html
<div id="display_image_detail">
  <div class="icon-overlay">
    <a href="https://static17.../upload/.../1.jpg" data-modal-gallery-image-item>
      <img src="https://static17.../upload/.../p=700/1.jpg" ...>
    </a>
  </div>
</div>
```

### Important
- Full/original image URL ada di anchor `href`.
- Preview/downscaled image ada di inner `img src` (`/p=700/`).

### Correct extraction
- `container`: `#display_image_detail`
- `images` selector (original): `#display_image_detail a[data-modal-gallery-image-item]`
- `images` attribute: `href`

Fallback if attribute absent:
- selector: `#display_image_detail .icon-overlay > a[href*='/upload/']`
- attribute: `href`

---

## 5) What Was Wrong in Previous Analysis

- Salah claim `container .item` ada. Tidak ada.
- Salah claim list item direct `a[href*='/image/']` sebagai root item. Struktur nyata pakai `.image-list-item`.
- Salah/kurang akurat di reader selector. Paling stabil ambil `a[data-modal-gallery-image-item][href]`, bukan `amp-img`.

---

## 6) Recommended Config Snippet (HTML-aligned)

```json
{
  "scraper": {
    "enabled": true,
    "urlPatterns": {
      "home": {
        "url": "/search/",
        "list": {
          "container": "#image-list > li .image-list-item",
          "fields": {
            "id": {
              "selector": ".image-list-item-title a[href*='/image/']",
              "attribute": "href",
              "transform": "slug"
            },
            "title": {
              "selector": ".image-list-item-title a"
            },
            "coverUrl": {
              "selector": ".image-list-item-image img",
              "attribute": "src"
            }
          },
          "pagination": {
            "next": ".wp-pagenavi a.nextpostslink[rel='next']"
          }
        }
      },
      "homePage": {
        "url": "/search/page/{page}/",
        "inherits": "home"
      },
      "search": {
        "url": "/search/keyword/{query}/",
        "inherits": "home"
      },
      "searchPage": {
        "url": "/search/keyword/{query}/page/{page}/",
        "inherits": "home"
      },
      "tag": {
        "url": "/search/tag/{tag}/",
        "inherits": "home"
      },
      "tagPage": {
        "url": "/search/tag/{tag}/page/{page}/",
        "inherits": "home"
      },
      "detail": "/image/{id}",
      "chapter": "/image/{id}"
    },
    "selectors": {
      "detail": {
        "fields": {
          "title": {
            "selector": "#title h2"
          },
          "tags": {
            "selector": "#detail_tag a[href*='/search/tag/']",
            "multi": true
          }
        }
      },
      "reader": {
        "container": "#display_image_detail",
        "images": {
          "selector": "#display_image_detail a[data-modal-gallery-image-item]",
          "attribute": "href"
        }
      }
    }
  }
}
```

---

## Confidence
- List/Home/Search: High
- Detail title/tags: High
- Reader image URL extraction: High
- Cover source uses direct `img src`: High
