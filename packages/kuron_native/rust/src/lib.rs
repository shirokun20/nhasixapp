mod decrypt;
mod ehentai;
mod header;
mod hitomi;
mod imageproc;
mod unpack;

use std::ffi::{c_char, CStr};

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
