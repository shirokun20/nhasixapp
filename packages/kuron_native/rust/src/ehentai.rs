use regex::Regex;

// ── Public API ───────────────────────────────────────────

/// Extract reader links from EHentai HTML.
/// Matches /s/... URLs on e-hentai.org or exhentai.org.
pub fn extract_urls(html: &str) -> Vec<String> {
    let normalized = html.replace("\\/", "/");
    let re = Regex::new(
        r#"(?i)((?:https?:)?//(?:e-hentai|exhentai)\.org)?/s/[A-Za-z0-9_-]+/[0-9]+-[0-9]+"#,
    )
    .unwrap();
    let mut seen = std::collections::HashSet::new();
    let mut results = Vec::new();
    for cap in re.captures_iter(&normalized) {
        let link = cap.get(0).unwrap().as_str().to_string();
        if seen.insert(link.clone()) {
            results.push(link);
        }
    }
    results
}

/// Extract tags from EHentai detail HTML.
/// Parses `<div id="td_TYPE:VALUE">...` structure.
pub fn extract_tags(html: &str) -> Vec<String> {
    let re = Regex::new(
        r#"(?i)<div[^>]*id="td_([^"]+)"[^>]*>[\s\S]*?<a[^>]*href="[^"]*"[^>]*>([\s\S]*?)</a>"#,
    )
    .unwrap();
    let mut tags = Vec::new();
    for cap in re.captures_iter(html) {
        let tag_spec = cap.get(1).map(|m| m.as_str().trim()).unwrap_or("");
        if tag_spec.is_empty() || !tag_spec.contains(':') {
            continue;
        }
        let tag_text = cap.get(2).map(|m| clean_html_text(m.as_str())).unwrap_or_default();
        if tag_text.is_empty() {
            continue;
        }
        tags.push(format!("{}:{}", tag_spec, tag_text));
    }

    // Fallback: title="type:value" pattern for legacy pages
    if tags.is_empty() {
        let re2 = Regex::new(r#"<div[^>]*class="[^"]*\bgt\b[^"]*"[^>]*title="([^"]+)""#).unwrap();
        for cap in re2.captures_iter(html) {
            let name = clean_html_text(cap.get(1).map(|m| m.as_str()).unwrap_or(""));
            if !name.is_empty() {
                tags.push(name);
            }
        }
    }

    tags
}

fn clean_html_text(text: &str) -> String {
    text.replace('\\', "")
        .replace("<br>", "")
        .replace("<br/>", "")
        .replace("&amp;", "&")
        .replace("&#039;", "'")
        .replace("&quot;", "\"")
        .trim()
        .to_string()
}

// ── FFI exports ──────────────────────────────────────────

/// Extract reader URLs from EHentai HTML.
/// Returns newline-separated URLs UTF-8 string.
fn extract_urls_json(html: &str) -> String {
    extract_urls(html).join("\n")
}

#[no_mangle]
pub extern "C" fn ehentai_extract_urls(
    html: *const std::ffi::c_char,
    out_len: *mut u32,
) -> *mut u8 {
    let html = if html.is_null() {
        return std::ptr::null_mut();
    } else {
        unsafe { std::ffi::CStr::from_ptr(html) }
    };
    let html = match html.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let result = extract_urls_json(html);
    let mut bytes = result.into_bytes();
    unsafe {
        *out_len = bytes.len() as u32;
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

/// Extract tags from EHentai HTML.
/// Returns JSON array of tag strings.
fn extract_tags_json(html: &str) -> String {
    use std::fmt::Write;
    let tags = extract_tags(html);
    let mut json = String::from('[');
    for (i, tag) in tags.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        write!(json, "\"{}\"", tag.replace('\\', "\\\\").replace('"', "\\\"")).unwrap();
    }
    json.push(']');
    json
}

#[no_mangle]
pub extern "C" fn ehentai_extract_tags(
    html: *const std::ffi::c_char,
    out_len: *mut u32,
) -> *mut u8 {
    let html = if html.is_null() {
        return std::ptr::null_mut();
    } else {
        unsafe { std::ffi::CStr::from_ptr(html) }
    };
    let html = match html.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let result = extract_tags_json(html);
    let mut bytes = result.into_bytes();
    unsafe {
        *out_len = bytes.len() as u32;
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

// ── Tests ─────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_urls_empty() {
        assert!(extract_urls("no links here").is_empty());
    }

    #[test]
    fn test_extract_urls_basic() {
        let html = r#"<a href="/s/abc123/12345-1">link</a>"#;
        let urls = extract_urls(html);
        assert_eq!(urls.len(), 1);
        assert!(urls[0].contains("/s/abc123/12345-1"));
    }

    #[test]
    fn test_extract_urls_dedup() {
        let html = r#"<a href="/s/abc/1-1">a</a><a href="/s/abc/1-1">b</a>"#;
        let urls = extract_urls(html);
        assert_eq!(urls.len(), 1);
    }

    #[test]
    fn test_extract_urls_absolute() {
        let html = r#"<a href="https://e-hentai.org/s/abc/1-1">link</a>"#;
        let urls = extract_urls(html);
        assert_eq!(urls.len(), 1);
    }

    #[test]
    fn test_extract_tags_empty() {
        assert!(extract_tags("no tags here").is_empty());
    }

    #[test]
    fn test_extract_tags_basic() {
        let html = r#"<div id="td_language:korean" class="gt"><a href="/?f_doujinshi=1" class="">korean</a></div>"#;
        let tags = extract_tags(html);
        assert!(!tags.is_empty());
        assert!(tags[0].contains("language"));
    }

    #[test]
    fn test_extract_urls_backslash_normalized() {
        let html = r#"<a href="\/s\/abc123\/12345-1">link<\/a>"#;
        let urls = extract_urls(html);
        assert_eq!(urls.len(), 1);
        assert!(urls[0].contains("/s/abc123/12345-1"));
    }
}
