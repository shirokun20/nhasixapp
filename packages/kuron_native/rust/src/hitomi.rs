use sha2::{Digest, Sha256};

// ── Internal node parsing ─────────────────────────────────

struct NodeKey {
    bytes: Vec<u8>,
}

struct DataRef {
    offset: u64,
    length: u32,
}

struct HitomiNode {
    keys: Vec<NodeKey>,
    datas: Vec<DataRef>,
    sub_node_addresses: Vec<u64>,
}

fn parse_node(data: &[u8]) -> Result<HitomiNode, String> {
    let mut pos = 0;

    if data.len() < 4 {
        return Err("truncated node: missing key count".into());
    }
    let num_keys = u32::from_be_bytes(data[pos..pos + 4].try_into().unwrap()) as usize;
    pos += 4;

    let mut keys = Vec::with_capacity(num_keys);
    for _ in 0..num_keys {
        if pos + 4 > data.len() {
            return Err("truncated node: missing key size".into());
        }
        let key_size = u32::from_be_bytes(data[pos..pos + 4].try_into().unwrap()) as usize;
        pos += 4;
        if key_size == 0 || key_size > 32 || pos + key_size > data.len() {
            return Err("invalid key size".into());
        }
        keys.push(NodeKey {
            bytes: data[pos..pos + key_size].to_vec(),
        });
        pos += key_size;
    }

    if pos + 4 > data.len() {
        return Err("truncated node: missing data count".into());
    }
    let num_datas = u32::from_be_bytes(data[pos..pos + 4].try_into().unwrap()) as usize;
    pos += 4;

    let mut datas = Vec::with_capacity(num_datas);
    for _ in 0..num_datas {
        if pos + 12 > data.len() {
            return Err("truncated node: data entry".into());
        }
        let offset = u64::from_be_bytes(data[pos..pos + 8].try_into().unwrap());
        pos += 8;
        let length = u32::from_be_bytes(data[pos..pos + 4].try_into().unwrap());
        pos += 4;
        datas.push(DataRef { offset, length });
    }

    let mut sub_node_addresses = Vec::with_capacity(17);
    for _ in 0..17 {
        if pos + 8 > data.len() {
            return Err("truncated node: sub-node address".into());
        }
        sub_node_addresses.push(u64::from_be_bytes(data[pos..pos + 8].try_into().unwrap()));
        pos += 8;
    }

    Ok(HitomiNode {
        keys,
        datas,
        sub_node_addresses,
    })
}

fn compare_bytes(a: &[u8], b: &[u8]) -> i32 {
    let limit = a.len().min(b.len());
    for i in 0..limit {
        if a[i] < b[i] {
            return -1;
        }
        if a[i] > b[i] {
            return 1;
        }
    }
    0
}

fn is_leaf(node: &HitomiNode) -> bool {
    node.sub_node_addresses.iter().all(|&a| a == 0)
}

fn locate_key(key: &[u8], node: &HitomiNode) -> (bool, usize) {
    for (i, k) in node.keys.iter().enumerate() {
        let cmp = compare_bytes(key, &k.bytes);
        if cmp <= 0 {
            return (cmp == 0, i);
        }
    }
    (false, node.keys.len())
}

// ── Public API ───────────────────────────────────────────

/// SHA256 hash of a key string, returns first 4 bytes.
#[allow(dead_code)]
pub fn hash_key(key: &str) -> [u8; 4] {
    let result = Sha256::digest(key.as_bytes());
    let mut key_bytes = [0u8; 4];
    key_bytes.copy_from_slice(&result[..4]);
    key_bytes
}

/// Decode gallery IDs from Hitomi data binary format.
/// Format: [count:u32 BE][id0:u32 BE][id1:u32 BE]...
pub fn decode_gallery_ids(data: &[u8]) -> Vec<i32> {
    if data.len() < 4 {
        return vec![];
    }
    let count = u32::from_be_bytes(data[..4].try_into().unwrap()) as usize;
    if count == 0 || data.len() < 4 + count * 4 {
        return vec![];
    }

    let mut ids = Vec::with_capacity(count);
    let mut pos = 4;
    for _ in 0..count {
        ids.push(i32::from_be_bytes(data[pos..pos + 4].try_into().unwrap()));
        pos += 4;
    }
    ids
}

/// Parse a binary node and locate a matching key. Returns 21-byte search result.
///
/// Binary format (21 bytes):
///   tag: u8 (0=not_found_leaf, 1=found, 2=not_found_recurse)
///   If tag == 1: offset: u64 LE, length: u32 LE
///   If tag == 2: next_address: u64 LE
///   If tag == 0: all zeros
///
/// Returns None on parse error.
pub fn decode_node_binary(data: &[u8], key: &[u8]) -> Option<[u8; 21]> {
    let node = parse_node(data).ok()?;
    let (found, index) = locate_key(key, &node);

    let mut buf = [0u8; 21];

    if found {
        let d = &node.datas[index];
        buf[0] = 1;
        buf[1..9].copy_from_slice(&d.offset.to_le_bytes());
        buf[9..13].copy_from_slice(&d.length.to_le_bytes());
    } else if is_leaf(&node) {
        buf[0] = 0;
    } else {
        buf[0] = 2;
        buf[1..9].copy_from_slice(&node.sub_node_addresses[index].to_le_bytes());
    }

    Some(buf)
}

/// Parse a binary node and locate a matching key. Returns JSON result.
/// JSON: {"found":true,"offset":N,"length":N} or {"found":false} or {"found":false,"next_address":N}
#[allow(dead_code)]
pub fn decode_node_json(data: &[u8], key: &[u8]) -> String {
    let node = match parse_node(data) {
        Ok(n) => n,
        Err(e) => return format!(r#"{{"error":"{}"}}"#, e),
    };

    let (found, index) = locate_key(key, &node);

    if found {
        let d = &node.datas[index];
        format!(
            r#"{{"found":true,"offset":{},"length":{}}}"#,
            d.offset, d.length
        )
    } else if is_leaf(&node) {
        r#"{"found":false}"#.to_string()
    } else {
        let addr = node.sub_node_addresses[index];
        format!(r#"{{"found":false,"next_address":{}}}"#, addr)
    }
}

/// Decode nozomi index IDs from binary data.
/// Format: [id0:u32 BE][id1:u32 BE]... (length % 4 == 0)
pub fn decode_nozomi_ids(data: &[u8]) -> Vec<i32> {
    if data.len() < 4 {
        return vec![];
    }
    let usable = data.len() - (data.len() % 4);
    let mut ids = Vec::with_capacity(usable / 4);
    for i in (0..usable).step_by(4) {
        ids.push(i32::from_be_bytes(data[i..i + 4].try_into().unwrap()));
    }
    ids
}

// ── FFI exports ──────────────────────────────────────────

#[no_mangle]
pub extern "C" fn hitomi_decode_gallery_ids(
    data: *const u8,
    data_len: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let ids = decode_gallery_ids(data);

    // Return: [count:u32 LE][id0:i32 LE][id1:i32 LE]...
    let count = ids.len() as u32;
    let buf_size = 4 + ids.len() * 4;
    let mut buf = vec![0u8; buf_size];
    let count_bytes = count.to_le_bytes();
    buf[..4].copy_from_slice(&count_bytes);

    for (i, id) in ids.iter().enumerate() {
        let id_bytes = id.to_le_bytes();
        let offset = 4 + i * 4;
        buf[offset..offset + 4].copy_from_slice(&id_bytes);
    }

    unsafe {
        *out_len = buf.len() as u32;
    }
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf);
    ptr
}

#[no_mangle]
pub extern "C" fn hitomi_decode_node(
    data: *const u8,
    data_len: u32,
    key: *const u8,
    key_len: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let key = unsafe { std::slice::from_raw_parts(key, key_len as usize) };

    match decode_node_binary(data, key) {
        Some(result) => {
            let mut buf = result.to_vec();
            unsafe {
                *out_len = buf.len() as u32;
            }
            let ptr = buf.as_mut_ptr();
            std::mem::forget(buf);
            ptr
        }
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn hitomi_bset_search(
    data: *const u8,
    data_len: u32,
    target: i32,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let target_bytes = target.to_be_bytes();

    match decode_node_binary(data, &target_bytes) {
        Some(result) => {
            let mut buf = result.to_vec();
            unsafe {
                *out_len = buf.len() as u32;
            }
            let ptr = buf.as_mut_ptr();
            std::mem::forget(buf);
            ptr
        }
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn hitomi_decode_nozomi_ids(
    data: *const u8,
    data_len: u32,
    out_len: *mut u32,
) -> *mut u8 {
    let data = unsafe { std::slice::from_raw_parts(data, data_len as usize) };
    let ids = decode_nozomi_ids(data);

    let count = ids.len() as u32;
    let buf_size = 4 + ids.len() * 4;
    let mut buf = vec![0u8; buf_size];
    let count_bytes = count.to_le_bytes();
    buf[..4].copy_from_slice(&count_bytes);

    for (i, id) in ids.iter().enumerate() {
        let id_bytes = id.to_le_bytes();
        let offset = 4 + i * 4;
        buf[offset..offset + 4].copy_from_slice(&id_bytes);
    }

    unsafe {
        *out_len = buf.len() as u32;
    }
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf);
    ptr
}

// ── Tests ─────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decode_gallery_ids_empty() {
        assert!(decode_gallery_ids(&[]).is_empty());
        assert!(decode_gallery_ids(&[0, 0, 0, 0]).is_empty());
    }

    #[test]
    fn test_decode_gallery_ids_basic() {
        let mut data = vec![0u8; 8];
        data[..4].copy_from_slice(&1u32.to_be_bytes());
        data[4..8].copy_from_slice(&42i32.to_be_bytes());
        let ids = decode_gallery_ids(&data);
        assert_eq!(ids, vec![42]);
    }

    #[test]
    fn test_decode_nozomi_ids() {
        let data = vec![0u8, 0, 0, 1, 0, 0, 0, 2];
        let ids = decode_nozomi_ids(&data);
        assert_eq!(ids, vec![1, 2]);
    }

    #[test]
    fn test_hash_key() {
        let hash = hash_key("female:anal");
        assert_eq!(hash.len(), 4);
    }

    #[test]
    fn test_decode_node_json_invalid_data() {
        let result = decode_node_json(&[0u8; 2], &[1, 2, 3, 4]);
        assert!(result.contains("error"));
    }

    #[test]
    fn test_parse_node_basic() {
        let mut data = vec![0u8; 4 + 4 + 17 * 8];
        data[..4].copy_from_slice(&0u32.to_be_bytes());
        data[4..8].copy_from_slice(&0u32.to_be_bytes());
        let node = parse_node(&data).unwrap();
        assert!(node.keys.is_empty());
        assert!(node.datas.is_empty());
        assert!(is_leaf(&node));
    }

    #[test]
    fn test_parse_node_with_key() {
        // 1 key, 1 data, 17 zero addresses
        let key_bytes = [0xAB, 0xCD, 0xEF, 0x01];
        let mut data = vec![];
        // num_keys = 1
        data.extend_from_slice(&1u32.to_be_bytes());
        // key_size = 4
        data.extend_from_slice(&4u32.to_be_bytes());
        // key data
        data.extend_from_slice(&key_bytes);
        // num_datas = 1
        data.extend_from_slice(&1u32.to_be_bytes());
        // data ref: offset=100, length=50
        data.extend_from_slice(&100u64.to_be_bytes());
        data.extend_from_slice(&50u32.to_be_bytes());
        // 17 zero sub-node addresses
        for _ in 0..17 {
            data.extend_from_slice(&0u64.to_be_bytes());
        }

        let node = parse_node(&data).unwrap();
        assert_eq!(node.keys.len(), 1);
        assert_eq!(node.datas.len(), 1);
        assert_eq!(node.datas[0].offset, 100);
        assert_eq!(node.datas[0].length, 50);
    }

    #[test]
    fn test_locate_key_found() {
        let mut data = vec![];
        data.extend_from_slice(&1u32.to_be_bytes());
        data.extend_from_slice(&4u32.to_be_bytes());
        data.extend_from_slice(&[0x00, 0x00, 0x00, 0x05]);
        data.extend_from_slice(&1u32.to_be_bytes());
        data.extend_from_slice(&0u64.to_be_bytes());
        data.extend_from_slice(&0u32.to_be_bytes());
        for _ in 0..17 {
            data.extend_from_slice(&0u64.to_be_bytes());
        }

        let node = parse_node(&data).unwrap();
        let key = [0x00, 0x00, 0x00, 0x05];
        let (found, idx) = locate_key(&key, &node);
        assert!(found);
        assert_eq!(idx, 0);
    }
}
