use image::GenericImageView;
use image::ImageEncoder;
use image::imageops::FilterType;
use image::codecs::jpeg::JpegEncoder;

const WEBTOON_AR_THRESHOLD: f64 = 2.5;

/// Process a single image: decode → resize (if wider than max_width) → encode JPEG.
pub fn process_single(path: &str, max_width: u32, quality: u8) -> Result<Vec<u8>, String> {
    let img = image::open(path).map_err(|e| format!("Open failed: {}", e))?;

    let img = if img.width() > max_width {
        let scale = max_width as f64 / img.width() as f64;
        let new_h = (img.height() as f64 * scale).round() as u32;
        img.resize_exact(max_width, new_h, FilterType::Lanczos3)
    } else {
        img
    };

    let rgba = img.to_rgba8();
    encode_jpeg_buf(&rgba, rgba.width(), rgba.height(), quality)
}

/// Split a webtoon image into JPEG chunks.
/// Returns flat buffer: [count:u32][len0:u32][data0]...[lenN:u32][dataN].
pub fn split_image(
    path: &str,
    max_width: u32,
    max_height_per_chunk: u32,
    quality: u8,
) -> Result<Vec<u8>, String> {
    let img = image::open(path).map_err(|e| format!("Open failed: {}", e))?;

    let img = if img.width() > max_width {
        let scale = max_width as f64 / img.width() as f64;
        let new_h = (img.height() as f64 * scale).round() as u32;
        img.resize_exact(max_width, new_h, FilterType::Lanczos3)
    } else {
        img
    };

    let ar = img.height() as f64 / img.width() as f64;
    if ar <= WEBTOON_AR_THRESHOLD {
        // Not a webtoon — single chunk
        let rgba = img.to_rgba8();
        let (w, h) = rgba.dimensions();
        let jpg = encode_jpeg_buf(&rgba, w, h, quality)?;
        let mut result = Vec::with_capacity(8 + jpg.len());
        result.extend_from_slice(&1u32.to_le_bytes());
        result.extend_from_slice(&(jpg.len() as u32).to_le_bytes());
        result.extend_from_slice(&jpg);
        return Ok(result);
    }

    // Webtoon — split into chunks
    let total_chunks = (img.height() as f64 / max_height_per_chunk as f64).ceil() as u32;
    let mut chunks: Vec<Vec<u8>> = Vec::with_capacity(total_chunks as usize);

    for i in 0..total_chunks {
        let y = i * max_height_per_chunk;
        let h = max_height_per_chunk.min(img.height() - y);
        let cropped = img.view(0, y, img.width(), h).to_image();
        let (cw, _) = cropped.dimensions();
        let jpg = encode_jpeg_buf(&cropped, cw, h, quality)?;
        chunks.push(jpg);
    }

    let total_len: usize = 4 + chunks.iter().map(|c| 4 + c.len()).sum::<usize>();
    let mut result = Vec::with_capacity(total_len);
    result.extend_from_slice(&(chunks.len() as u32).to_le_bytes());
    for chunk in &chunks {
        result.extend_from_slice(&(chunk.len() as u32).to_le_bytes());
        result.extend_from_slice(chunk);
    }
    Ok(result)
}

fn encode_jpeg_buf(rgba: &image::RgbaImage, _width: u32, _height: u32, quality: u8) -> Result<Vec<u8>, String> {
    // ponytail: _width, _height unused; kept for API symmetry with callers that may use them

    // Convert RGBA → RGB (JPEG doesn't support alpha)
    let mut rgb_buf = vec![0u8; (rgba.width() * rgba.height() * 3) as usize];
    let rgba_raw = rgba.as_raw();
    for i in 0..rgba.width() as usize * rgba.height() as usize {
        rgb_buf[i * 3] = rgba_raw[i * 4];
        rgb_buf[i * 3 + 1] = rgba_raw[i * 4 + 1];
        rgb_buf[i * 3 + 2] = rgba_raw[i * 4 + 2];
    }
    let mut buf = std::io::Cursor::new(Vec::new());
    let encoder = JpegEncoder::new_with_quality(&mut buf, quality);
    encoder
        .write_image(&rgb_buf, rgba.width(), rgba.height(), image::ExtendedColorType::Rgb8)
        .map_err(|e| format!("Encode failed: {}", e))?;
    Ok(buf.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn process_single_invalid_path() {
        let result = process_single("/nonexistent/image.jpg", 1200, 90);
        assert!(result.is_err());
    }

    #[test]
    fn split_image_invalid_path() {
        let result = split_image("/nonexistent/image.jpg", 1200, 3000, 90);
        assert!(result.is_err());
    }

    #[test]
    fn encode_jpeg_roundtrip() {
        use image::RgbaImage;
        let rgba = RgbaImage::from_raw(100, 100, vec![128u8; 100 * 100 * 4]).unwrap();
        let result = encode_jpeg_buf(&rgba, 100, 100, 90);
        assert!(result.is_ok());
        let bytes = result.unwrap();
        assert!(!bytes.is_empty());
        // Should have JPEG magic bytes
        assert_eq!(bytes[0], 0xFF);
        assert_eq!(bytes[1], 0xD8);
    }
}
