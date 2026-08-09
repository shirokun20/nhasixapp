// ── HeaderInfo result ────────────────────────────────────

pub struct HeaderInfo {
    pub format: Option<String>,
    pub width: Option<i32>,
    pub height: Option<i32>,
}

// ── Public API ───────────────────────────────────────────

/// Inspect raw bytes for image format and dimensions (WebP/AVIF).
pub fn inspect(data: &[u8]) -> HeaderInfo {
    if data.len() < 12 {
        return HeaderInfo {
            format: None,
            width: None,
            height: None,
        };
    }

    // Check WebP: RIFF + WEBP
    if &data[0..4] == b"RIFF" && &data[8..12] == b"WEBP" {
        return inspect_webp(data);
    }

    // Check AVIF: ftyp with an avif/avis/mif1 major brand. Animated AVIFs
    // (AVIS "motion" files) often use `avif`/`mif1` as the MAJOR brand with
    // `avis` as a MINOR brand, so we must not gate on `avis` being the major
    // brand only — that previously left many animated AVIFs undetected.
    if &data[4..8] == b"ftyp" {
        let major = &data[8..12];
        if major == b"avif" || major == b"avis" || major == b"mif1" {
            return inspect_avif(data);
        }
    }

    HeaderInfo {
        format: None,
        width: None,
        height: None,
    }
}

/// Inspect multiple files for batch operation.
/// Each path is read from disk (first 4KB).
pub fn inspect_batch(paths: &[&str]) -> Vec<HeaderInfo> {
    paths.iter().map(|p| inspect_file(p)).collect()
}

fn inspect_file(path: &str) -> HeaderInfo {
    match std::fs::read(path) {
        Ok(data) => {
            let sample_len = data.len().min(4096);
            inspect(&data[..sample_len])
        }
        Err(_) => HeaderInfo {
            format: None,
            width: None,
            height: None,
        },
    }
}

fn inspect_webp(data: &[u8]) -> HeaderInfo {
    // Look for VP8X chunk (animated WebP indicator + dimensions)
    let mut offset: usize = 12;
    while offset + 8 <= data.len() {
        let chunk_type = &data[offset..offset + 4];
        let chunk_size = u32::from_le_bytes([
            data[offset + 4],
            data[offset + 5],
            data[offset + 6],
            data[offset + 7],
        ]) as usize;

        if chunk_type == b"VP8X" && chunk_size >= 10 && offset + 18 <= data.len() {
            // VP8X: flags byte at offset+8, then dimensions (24-bit LE)
            // Check animation flag (bit 1)
            if (data[offset + 8] & 0x02) != 0 {
                let width = 1
                    + (data[offset + 12] as u32
                        | (data[offset + 13] as u32) << 8
                        | (data[offset + 14] as u32) << 16);

                let height = 1
                    + (data[offset + 15] as u32
                        | (data[offset + 16] as u32) << 8
                        | (data[offset + 17] as u32) << 16);

                return HeaderInfo {
                    format: Some("webp".to_string()),
                    width: if width > 0 { Some(width as i32) } else { None },
                    height: if height > 0 { Some(height as i32) } else { None },
                };
            }
        }

        offset += 8 + chunk_size;
        // RIFF chunks pad to even bytes
        if chunk_size % 2 != 0 {
            offset += 1;
        }
    }

    HeaderInfo {
        format: None,
        width: None,
        height: None,
    }
}

fn inspect_avif(data: &[u8]) -> HeaderInfo {
    const KISPE: &[u8; 4] = b"ispe";
    for i in 0..=data.len().saturating_sub(16) {
        if &data[i..i + 4] == KISPE {
            let w = ((data[i + 8] as u32) << 24)
                | ((data[i + 9] as u32) << 16)
                | ((data[i + 10] as u32) << 8)
                | (data[i + 11] as u32);

            let h = ((data[i + 12] as u32) << 24)
                | ((data[i + 13] as u32) << 16)
                | ((data[i + 14] as u32) << 8)
                | (data[i + 15] as u32);

            if h <= 4096 {
                return HeaderInfo {
                    format: Some("avif".to_string()),
                    width: if w > 0 { Some(w as i32) } else { None },
                    height: if h > 0 { Some(h as i32) } else { None },
                };
            }
        }
    }

    HeaderInfo {
        format: Some("avif".to_string()),
        width: None,
        height: None,
    }
}

// ── FFI exports ──────────────────────────────────────────

fn inspect_to_json(info: &HeaderInfo) -> String {
    let fmt = info
        .format
        .as_deref()
        .map(|s| format!("\"{}\"", s))
        .unwrap_or_else(|| "null".to_string());
    let w = info
        .width
        .map(|v| v.to_string())
        .unwrap_or_else(|| "null".to_string());
    let h = info
        .height
        .map(|v| v.to_string())
        .unwrap_or_else(|| "null".to_string());
    format!(r#"{{"format":{},"width":{},"height":{}}}"#, fmt, w, h)
}

#[no_mangle]
pub extern "C" fn header_inspect(
    data: *const u8,
    data_len: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let info = inspect(data);
    let json = inspect_to_json(&info);
    let mut bytes = json.into_bytes();
    unsafe {
        *out_len = bytes.len() as u32;
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[no_mangle]
pub extern "C" fn header_inspect_batch(
    paths: *const *const std::ffi::c_char,
    count: u32,
    out_len: *mut u32,
) -> *mut u8 {
    if paths.is_null() || count == 0 {
        unsafe {
            *out_len = 2;
        }
        let mut bytes = b"[]".to_vec();
        let ptr = bytes.as_mut_ptr();
        std::mem::forget(bytes);
        return ptr;
    }

    let mut path_strs = Vec::with_capacity(count as usize);
    for i in 0..count as usize {
        let cstr = unsafe { std::ffi::CStr::from_ptr(*paths.add(i)) };
        match cstr.to_str() {
            Ok(s) => path_strs.push(s),
            Err(_) => path_strs.push(""),
        }
    }

    let results = inspect_batch(&path_strs);
    let mut json = String::from('[');
    for (i, info) in results.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        json.push_str(&inspect_to_json(info));
    }
    json.push(']');
    let mut bytes = json.into_bytes();
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
    fn test_inspect_empty() {
        let info = inspect(&[]);
        assert!(info.format.is_none());
    }

    #[test]
    fn test_inspect_too_short() {
        let info = inspect(&[0u8; 10]);
        assert!(info.format.is_none());
    }

    #[test]
    fn test_inspect_webp_vp8x() {
        let mut data = Vec::new();
        data.extend_from_slice(b"RIFF");
        data.extend_from_slice(&0u32.to_le_bytes());
        data.extend_from_slice(b"WEBP");
        // VP8X chunk: header(8) + data(10)
        data.extend_from_slice(b"VP8X");
        data.extend_from_slice(&10u32.to_le_bytes()); // chunk data size
        // VP8X data: flags(1) + reserved(3) + width(3) + height(3)
        data.extend_from_slice(&[0x02, 0, 0, 0]); // flags=0x02 (animated) + 3 reserved
        data.push(0x7F); data.push(0x02); data.push(0x00); // width 24-bit LE = 639 → 639+1=640
        data.push(0xDF); data.push(0x01); data.push(0x00); // height 24-bit LE = 479 → 479+1=480

        let info = inspect(&data);
        assert_eq!(info.format.as_deref(), Some("webp"));
        assert_eq!(info.width, Some(640));
        assert_eq!(info.height, Some(480));
    }

    #[test]
    fn test_inspect_avif() {
        let mut data = Vec::new();
        data.extend_from_slice(&0u32.to_be_bytes());
        data.extend_from_slice(b"ftyp");
        data.extend_from_slice(b"avis");
        data.extend_from_slice(b"isis");
        data.extend_from_slice(b"ispe");
        data.extend_from_slice(&[0u8; 4]);
        data.extend_from_slice(&1920u32.to_be_bytes());
        data.extend_from_slice(&1080u32.to_be_bytes());

        let info = inspect(&data);
        assert_eq!(info.format.as_deref(), Some("avif"));
    }

    #[test]
    fn test_inspect_avif_major_brand_avif() {
        // Animated AVIF(G) with MAJOR brand `avif` (not `avis`) — must still
        // be detected as AVIF so the app can route it to WebP conversion.
        let mut data = Vec::new();
        data.extend_from_slice(&0u32.to_be_bytes());
        data.extend_from_slice(b"ftyp");
        data.extend_from_slice(b"avif");
        data.extend_from_slice(b"mif1");
        data.extend_from_slice(b"isis");
        data.extend_from_slice(b"ispe");
        data.extend_from_slice(&[0u8; 4]);
        data.extend_from_slice(&800u32.to_be_bytes());
        data.extend_from_slice(&600u32.to_be_bytes());

        let info = inspect(&data);
        assert_eq!(info.format.as_deref(), Some("avif"));
        assert_eq!(info.width, Some(800));
        assert_eq!(info.height, Some(600));
    }

    #[test]
    fn test_inspect_unknown() {
        let data = b"hello world, this is not an image";
        let info = inspect(data);
        assert!(info.format.is_none());
    }

    #[test]
    fn test_inspect_webp_no_dimensions() {
        let mut data = Vec::new();
        data.extend_from_slice(b"RIFF");
        data.extend_from_slice(&0u32.to_le_bytes());
        data.extend_from_slice(b"WEBP");
        // No VP8X, just VP8
        data.extend_from_slice(b"VP8 ");
        data.extend_from_slice(&10u32.to_le_bytes());
        data.extend_from_slice(&[0u8; 10]);

        let info = inspect(&data);
        assert_eq!(info.format.as_deref(), None);
        assert!(info.width.is_none());
    }

    #[test]
    fn test_inspect_to_json() {
        let info = HeaderInfo {
            format: Some("webp".to_string()),
            width: Some(100),
            height: Some(200),
        };
        let json = inspect_to_json(&info);
        assert!(json.contains("\"webp\""));
        assert!(json.contains("\"width\":100"));
        assert!(json.contains("\"height\":200"));
    }

    #[test]
    fn test_inspect_to_json_null() {
        let info = HeaderInfo {
            format: None,
            width: None,
            height: None,
        };
        let json = inspect_to_json(&info);
        assert!(!json.contains("webp"));
    }
}
