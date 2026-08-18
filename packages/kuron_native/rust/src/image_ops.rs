// ── AI translate image ops: webtoon chunking, mosaic build, page compress ──
//
// Pure functions: bytes in → bytes out, zero state. Mirrors the Dart
// implementations in `_splitWebtoonIsolate`, `MosaicBuilder.buildMosaic`,
// `FallbackImageHandler.compressPage` — output semantics identical
// (dimensions, content, size limits), exact JPEG bytes may differ.

use std::io::Cursor;

use image::codecs::jpeg::JpegEncoder;
use image::imageops::FilterType;
use image::{DynamicImage, GenericImageView, ImageEncoder};

pub const MAX_DIMENSION_GUARD: u32 = 10_000;

const MOSAIC_GAP: u32 = 10;
const MOSAIC_LABEL_W: u32 = 56;
const MOSAIC_LABEL_H: u32 = 40;
const MOSAIC_MAX_BYTES: usize = 2 * 1024 * 1024;

fn decode(data: &[u8]) -> Result<DynamicImage, String> {
    let img = image::load_from_memory(data).map_err(|e| format!("decode failed: {e}"))?;
    if img.width() > MAX_DIMENSION_GUARD || img.height() > MAX_DIMENSION_GUARD {
        return Err(format!(
            "dimension guard: {}x{}",
            img.width(),
            img.height()
        ));
    }
    Ok(img)
}

fn encode_jpeg_rgb(img: &DynamicImage, quality: u8) -> Result<Vec<u8>, String> {
    let rgba = img.to_rgba8();
    let (w, h) = rgba.dimensions();
    let mut rgb = Vec::with_capacity((w * h * 3) as usize);
    let raw = rgba.as_raw();
    for px in raw.chunks_exact(4) {
        rgb.extend_from_slice(&px[..3]);
    }
    let mut buf = Cursor::new(Vec::new());
    JpegEncoder::new_with_quality(&mut buf, quality)
        .write_image(&rgb, w, h, image::ExtendedColorType::Rgb8)
        .map_err(|e| format!("encode failed: {e}"))?;
    Ok(buf.into_inner())
}

/// Build a bitmap for a decimal number rendered on a 5x7 grid.
/// `0..=9` in set — absent => empty (renders as blank).
fn digit_bitmap(d: u8) -> &'static [u8; 7] {
    match d {
        0 => &[0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110],
        1 => &[0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
        2 => &[0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111],
        3 => &[0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110],
        4 => &[0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010],
        5 => &[0b11111, 0b10000, 0b10000, 0b11110, 0b00001, 0b00001, 0b11110],
        6 => &[0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110],
        7 => &[0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000],
        8 => &[0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110],
        9 => &[0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110],
        _ => &[0; 7],
    }
}

/// Draw a decimal number on an RGB image at (x, y) in red.
fn draw_number(img: &mut image::RgbImage, x: u32, y: u32, n: u32) {
    let s = n.to_string();
    let mut dx = x;
    for c in s.bytes() {
        let bm = digit_bitmap(c - b'0');
        for (ry, row) in bm.iter().enumerate() {
            for bx in 0..5 {
                if row & (1 << (4 - bx)) != 0 {
                    let px = dx + bx;
                    let py = y + ry as u32;
                    if px < img.width() && py < img.height() {
                        img.put_pixel(px, py, image::Rgb([255, 0, 0]));
                    }
                }
            }
        }
        dx += 6;
    }
}

/// Webtoon chunking: slice image into ≤ `max_chunk_h`-tall JPEG chunks,
/// quality 90 (mirrors Dart `_splitWebtoonIsolate`).
pub fn chunk_webtoon(data: &[u8], max_chunk_h: u32) -> Result<Vec<Vec<u8>>, String> {
    let decoded = match decode(data) {
        Ok(img) => img,
        Err(_) => return Ok(vec![data.to_vec()]), // undecodable => single passthrough chunk
    };
    let h = decoded.height();
    let w = decoded.width();
    let max_h = max_chunk_h.max(1);
    let mut chunks = Vec::new();
    let mut y = 0;
    while y < h {
        let chunk_h = (h - y).min(max_h);
        let crop = decoded.crop_imm(0, y, w, chunk_h);
        chunks.push(encode_jpeg_rgb(&crop, 90)?);
        y += chunk_h;
    }
    if chunks.is_empty() {
        chunks.push(data.to_vec()); // zero-height image => single passthrough
    }
    Ok(chunks)
}

/// Mosaic build: crop bubbles (20% padding, clamped), 2× scale, stack with
/// 10px gaps, red numeric label per chip, JPEG 85, downscale loop < 2MB.
pub fn build_mosaic(
    data: &[u8],
    boxes: &[(u32, u32, u32, u32)],
) -> Result<Vec<u8>, String> {
    let decoded = decode(data)?;
    let (page_w, page_h) = decoded.dimensions();
    let page = &decoded;

    let mut chips: Vec<DynamicImage> = Vec::with_capacity(boxes.len());
    let mut max_chip_w = 0u32;
    let mut total_h = 0u32;
    for &(x, y, w, h) in boxes {
        if w == 0 || h == 0 {
            continue;
        }
        let pad_x = (w as f64 * 0.2).round() as u32;
        let pad_y = (h as f64 * 0.2).round() as u32;
        let crop_x = x.saturating_sub(pad_x).min(page_w.saturating_sub(1));
        let crop_y = y.saturating_sub(pad_y).min(page_h.saturating_sub(1));
        let crop_w = (w + pad_x * 2).min(page_w - crop_x).max(1);
        let crop_h = (h + pad_y * 2).min(page_h - crop_y).max(1);
        let crop = page.crop_imm(crop_x, crop_y, crop_w, crop_h);
        let scaled = crop.resize_exact(crop_w * 2, crop_h * 2, FilterType::Triangle);
        max_chip_w = max_chip_w.max(scaled.width());
        total_h += scaled.height() + MOSAIC_GAP;
        chips.push(scaled);
    }
    if chips.is_empty() {
        return Err("no chips".into());
    }
    // Trim the trailing gap — same as Dart `fold(...) - gap`.
    total_h -= MOSAIC_GAP;
    total_h += MOSAIC_LABEL_H;

    let mw = max_chip_w + MOSAIC_LABEL_W;
    let mh = total_h.max(1);
    let mut mosaic = image::RgbImage::from_pixel(mw, mh, image::Rgb([255, 255, 255]));

    let mut y = 0u32;
    for (i, chip) in chips.iter().enumerate() {
        draw_number(&mut mosaic, 4, y + 4, (i + 1) as u32);
        let ch = chip.height();
        let dst_y = y + MOSAIC_LABEL_H / 2;
        image::imageops::overlay(&mut mosaic, &chip.to_rgb8(), MOSAIC_LABEL_W as i64, dst_y as i64);
        y += ch + MOSAIC_GAP;
    }

    let dyn_img = DynamicImage::ImageRgb8(mosaic);
    let mut jpeg = encode_jpeg_rgb(&dyn_img, 85)?;
    let mut width = mw;
    while jpeg.len() > MOSAIC_MAX_BYTES && width > 64 {
        width = ((width as f64 * 0.75).round() as u32).max(1);
        let ratio = width as f64 / dyn_img.width() as f64;
        let nh = ((dyn_img.height() as f64 * ratio).round() as u32).max(1);
        let scaled = dyn_img.resize_exact(width, nh, FilterType::Triangle);
        jpeg = encode_jpeg_rgb(&scaled, 85)?;
    }
    Ok(jpeg)
}

/// Full-page compress: resize longest side to `max_dim`, JPEG 85.
/// Undecodable or already-small input => original bytes unchanged.
pub fn compress_page(data: &[u8], max_dim: u32) -> Result<Vec<u8>, String> {
    let decoded = match decode(data) {
        Ok(img) => img,
        Err(_) => return Ok(data.to_vec()),
    };
    let longest = decoded.width().max(decoded.height());
    let max_d = max_dim.max(1);
    if longest <= max_d {
        return Ok(data.to_vec());
    }
    let ratio = max_d as f64 / longest as f64;
    let nw = ((decoded.width() as f64 * ratio).round() as u32).max(1);
    let nh = ((decoded.height() as f64 * ratio).round() as u32).max(1);
    let scaled = decoded.resize_exact(nw, nh, FilterType::Triangle);
    encode_jpeg_rgb(&scaled, 85)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_image(w: u32, h: u32) -> Vec<u8> {
        let img = DynamicImage::ImageRgb8(image::RgbImage::from_pixel(
            w,
            h,
            image::Rgb([200, 150, 100]),
        ));
        encode_jpeg_rgb(&img, 90).unwrap()
    }

    #[test]
    fn chunking_non_multiple_boundary() {
        let data = test_image(400, 2000);
        let chunks = chunk_webtoon(&data, 1280).unwrap();
        assert_eq!(chunks.len(), 2);
        let d1 = image::load_from_memory(&chunks[0]).unwrap();
        let d2 = image::load_from_memory(&chunks[1]).unwrap();
        assert_eq!(d1.height(), 1280);
        assert_eq!(d2.height(), 720);
        assert_eq!(d1.height() + d2.height(), 2000);
        assert_eq!(d1.width(), 400);
        assert_eq!(d2.width(), 400);
    }

    #[test]
    fn undecodable_input_passthrough() {
        let garbage = vec![1u8, 2, 3, 4, 5, 6, 7, 8, 9];
        let chunks = chunk_webtoon(&garbage, 1280).unwrap();
        assert_eq!(chunks.len(), 1);
        assert_eq!(chunks[0], garbage);
        let compressed = compress_page(&garbage, 1280).unwrap();
        assert_eq!(compressed, garbage);
    }

    #[test]
    fn compress_already_small_unchanged() {
        let data = test_image(800, 600);
        assert_eq!(compress_page(&data, 1280).unwrap(), data);
    }

    #[test]
    fn dimension_guard_rejects() {
        // Build a header-only JPEG with bogus huge dimensions.
        let mut bogus = vec![0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, b'J', b'F', b'I', b'F', 0x00];
        bogus.extend_from_slice(&[0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x64, 0x00, 0x64, 0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x00, 0x03, 0x11, 0x00]);
        bogus.extend_from_slice(&[0xFF, 0xD9]);
        let res = chunk_webtoon(&bogus, 1280);
        // Either rejected (guard) or falls back to passthrough chunk — never panic.
        match res {
            Ok(chunks) => assert_eq!(chunks.len(), 1),
            Err(_) => {}
        }
    }

    #[test]
    fn mosaic_single_chip_under_2mb() {
        let data = test_image(1000, 1500);
        let boxes = vec![(100, 200, 300, 120), (600, 800, 250, 90)];
        let jpeg = build_mosaic(&data, &boxes).unwrap();
        assert!(jpeg.len() < MOSAIC_MAX_BYTES);
        let img = image::load_from_memory(&jpeg).unwrap();
        // 2 chips: label area + max chip width
        assert!(img.width() >= 56);
        // scaled chip heights ((120+48)*2, (90+36)*2) + one gap + label area
        assert_eq!(img.height(), 336 + 10 + 252 + 40);
    }

    #[test]
    fn mosaic_bubble_clamped_to_page() {
        let data = test_image(500, 500);
        let boxes = vec![(480, 480, 100, 100)];
        let jpeg = build_mosaic(&data, &boxes).unwrap();
        let img = image::load_from_memory(&jpeg).unwrap();
        assert!(img.width() > 0 && img.height() > 0);
    }

    #[test]
    fn mosaic_empty_bubbles_errors() {
        let data = test_image(100, 100);
        assert!(build_mosaic(&data, &[]).is_err());
    }

    // ── Real webtoon strip fixture (test/fixtures/image-webtoon.jpeg) ──

    const REAL_STRIP: &[u8] =
        include_bytes!("../../../../test/fixtures/image-webtoon.jpeg");

    #[test]
    fn chunk_real_strip_boundary() {
        let chunks = chunk_webtoon(REAL_STRIP, 1280).unwrap();
        // 800x4710 → 4 chunks, last 4710 - 3*1280 = 870.
        assert_eq!(chunks.len(), 4);
        for (i, c) in chunks.iter().enumerate() {
            let img = image::load_from_memory(c).unwrap();
            assert_eq!(img.width(), 800);
            let expect_h = if i == 3 { 870 } else { 1280 };
            assert_eq!(img.height(), expect_h);
        }
    }

    #[test]
    fn mosaic_real_strip_under_2mb() {
        let boxes = vec![
            (50, 100, 300, 120),
            (400, 900, 250, 100),
            (100, 2000, 320, 140),
            (350, 3200, 200, 90),
            (60, 4500, 280, 110),
        ];
        let jpeg = build_mosaic(REAL_STRIP, &boxes).unwrap();
        assert!(jpeg.len() < MOSAIC_MAX_BYTES);
        let img = image::load_from_memory(&jpeg).unwrap();
        assert!(img.width() > 56);
    }

    #[test]
    fn compress_real_strip_to_1280() {
        let jpeg = compress_page(REAL_STRIP, 1280).unwrap();
        let img = image::load_from_memory(&jpeg).unwrap();
        assert_eq!(img.height(), 1280);
        // Aspect preserved: 800 * (1280/4710) = 217.
        assert_eq!(img.width(), (800.0_f64 * 1280.0 / 4710.0).round() as u32);
    }
}
