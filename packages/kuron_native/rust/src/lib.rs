mod decrypt;
mod ehentai;
mod header;
mod hitomi;
mod image_ops;
mod imageproc;
mod unpack;

use std::ffi::{c_char, CStr};
use std::sync::OnceLock;
use std::sync::Mutex;
use std::panic::{catch_unwind, AssertUnwindSafe};

// ── Image ops panics ────────────────────────────────────────
// Image ops are called from arbitrary worker isolates; a panic must never
// unwind across the FFI boundary (would abort the process). Serialize with
// a Mutex: the image crate is not safe to call concurrently from multiple
// isolates while a panic may leave its global state inconsistent.
static IMAGE_OPS_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn with_image_ops_lock<T>(f: impl FnOnce() -> T) -> Option<T> {
    let lock = IMAGE_OPS_LOCK.get_or_init(|| Mutex::new(()));
    let _guard = lock.lock().ok()?;
    catch_unwind(AssertUnwindSafe(f)).ok()
}

// ── Universal memory helpers ──────────────────────────────

#[no_mangle]
pub extern "C" fn free_rust_buffer(ptr: *mut u8, len: u32) {
    if ptr.is_null() || len == 0 {
        return;
    }
    unsafe {
        drop(Vec::from_raw_parts(ptr, len as usize, len as usize));
    }
}

// ── HentaiNexus decrypt ───────────────────────────────────

/// Decrypt HentaiNexus content.
/// Receives already-base64-decoded bytes + hostname.
/// Returns heap-allocated UTF-8 string bytes, writes length to out_len.
/// Returns null on error.
#[no_mangle]
pub extern "C" fn nexus_decrypt(
    data: *const u8,
    data_len: u32,
    hostname: *const c_char,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let hostname = if hostname.is_null() {
        ""
    } else {
        unsafe { CStr::from_ptr(hostname) }.to_str().unwrap_or("")
    };

    match decrypt::decrypt(data, hostname) {
        Ok(result) => {
            let mut bytes = result.into_bytes();
            unsafe { *out_len = bytes.len() as u32 }
            let ptr = bytes.as_mut_ptr();
            std::mem::forget(bytes);
            ptr
        }
        Err(_) => std::ptr::null_mut(),
    }
}

// ── ViHentai packed JS unpack ──────────────────────────────

/// Unpack a ViHentai packed-JavaScript script.
/// Returns heap-allocated UTF-8 string bytes, writes length to out_len.
/// Returns null on error.
#[no_mangle]
pub extern "C" fn vihentai_unpack(
    script: *const c_char,
    out_len: *mut u32,
) -> *mut u8 {
    let script = if script.is_null() {
        return std::ptr::null_mut();
    } else {
        unsafe { CStr::from_ptr(script) }
    };
    let script = match script.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match unpack::unpack(script) {
        Ok(result) => {
            let mut bytes = result.into_bytes();
            unsafe { *out_len = bytes.len() as u32 }
            let ptr = bytes.as_mut_ptr();
            std::mem::forget(bytes);
            ptr
        }
        Err(_) => std::ptr::null_mut(),
    }
}

// ── Image processing ──────────────────────────────────────

/// Process a single image: decode → resize (if wider than max_width) → encode JPEG.
/// Returns heap-allocated JPEG bytes.
/// Returns null on error.
#[no_mangle]
pub extern "C" fn image_process_single(
    path: *const c_char,
    max_width: u32,
    quality: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let path = if path.is_null() {
        return std::ptr::null_mut();
    } else {
        unsafe { CStr::from_ptr(path) }
    };
    let path = match path.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match imageproc::process_single(path, max_width, quality as u8) {
        Ok(bytes) => {
            let mut v = bytes;
            unsafe { *out_len = v.len() as u32 }
            let ptr = v.as_mut_ptr();
            std::mem::forget(v);
            ptr
        }
        Err(_) => std::ptr::null_mut(),
    }
}

/// Split a webtoon image into JPEG chunks.
/// Returns flat buffer: [count:u32][len0:u32][data0]...[lenN:u32][dataN].
/// Returns null on error.
#[no_mangle]
pub extern "C" fn image_split(
    path: *const c_char,
    max_width: u32,
    max_height_per_chunk: u32,
    quality: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let path = if path.is_null() {
        return std::ptr::null_mut();
    } else {
        unsafe { CStr::from_ptr(path) }
    };
    let path = match path.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match imageproc::split_image(path, max_width, max_height_per_chunk, quality as u8) {
        Ok(bytes) => {
            let mut v = bytes;
            unsafe { *out_len = v.len() as u32 }
            let ptr = v.as_mut_ptr();
            std::mem::forget(v);
            ptr
        }
        Err(_) => std::ptr::null_mut(),
    }
}

// ── AI translate image ops ──────────────────────────────────
//
// All three return a flat buffer:
//   [count:u32][len0:u32][data0]...[lenN:u32][dataN]
// (chunk_webtoon: one entry per chunk; build_mosaic/compress_page: one
// entry total). Writes total flat-buffer length to out_len, returns null on
// error or panic. Memory freed by `free_rust_buffer`.

fn image_ops_result(chunks: Vec<Vec<u8>>, out_len: *mut u32) -> *mut u8 {
    let total_len: usize = 4 + chunks.iter().map(|c| 4 + c.len()).sum::<usize>();
    let mut buf = Vec::with_capacity(total_len);
    buf.extend_from_slice(&(chunks.len() as u32).to_le_bytes());
    for c in &chunks {
        buf.extend_from_slice(&(c.len() as u32).to_le_bytes());
        buf.extend_from_slice(c);
    }
    unsafe { *out_len = buf.len() as u32 }
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf);
    ptr
}

/// Webtoon chunking: slice into ≤ max_chunk_h-tall JPEG chunks (quality 90).
#[no_mangle]
pub extern "C" fn image_ops_chunk_webtoon(
    data: *const u8,
    data_len: u32,
    max_chunk_h: u32,
    out_len: *mut u32,
) -> *mut u8 {
    if data.is_null() || out_len.is_null() || data_len == 0 {
        return std::ptr::null_mut();
    }
    let bytes = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let result = with_image_ops_lock(|| image_ops::chunk_webtoon(bytes, max_chunk_h));
    match result {
        Some(Ok(chunks)) => image_ops_result(chunks, out_len),
        _ => std::ptr::null_mut(),
    }
}

/// Mosaic build: crop+pad+2x scale+stack+label+JPEG85, <2MB.
/// `boxes` = flat [x,y,w,h] u32 pairs, `boxes_len` = number of pairs.
#[no_mangle]
pub extern "C" fn image_ops_build_mosaic(
    data: *const u8,
    data_len: u32,
    boxes: *const u32,
    boxes_len: u32,
    out_len: *mut u32,
) -> *mut u8 {
    if data.is_null() || out_len.is_null() || data_len == 0 || boxes.is_null() || boxes_len == 0 {
        return std::ptr::null_mut();
    }
    let bytes = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let flat = unsafe { std::slice::from_raw_parts(boxes, boxes_len as usize * 4) };
    let mut rects = Vec::with_capacity(boxes_len as usize);
    for r in flat.chunks_exact(4) {
        rects.push((r[0], r[1], r[2], r[3]));
    }
    let result = with_image_ops_lock(|| image_ops::build_mosaic(bytes, &rects));
    match result {
        Some(Ok(jpeg)) => image_ops_result(vec![jpeg], out_len),
        _ => std::ptr::null_mut(),
    }
}

/// Full-page compress: longest side ≤ max_dim, JPEG 85.
/// Undecodable/already-small => returns original bytes.
#[no_mangle]
pub extern "C" fn image_ops_compress_page(
    data: *const u8,
    data_len: u32,
    max_dim: u32,
    out_len: *mut u32,
) -> *mut u8 {
    if data.is_null() || out_len.is_null() || data_len == 0 {
        return std::ptr::null_mut();
    }
    let bytes = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let result = with_image_ops_lock(|| image_ops::compress_page(bytes, max_dim));
    match result {
        Some(Ok(out)) => image_ops_result(vec![out], out_len),
        _ => std::ptr::null_mut(),
    }
}
