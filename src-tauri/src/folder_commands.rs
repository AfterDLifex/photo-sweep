use crate::models::*;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[tauri::command]
pub fn check_path_exists(path: &str) -> bool {
    Path::new(path).exists()
}

#[tauri::command]
pub fn scan_directory(path: &str, recursion_depth: u32) -> Result<Vec<FileInfo>, String> {
    let base = PathBuf::from(path);
    if !base.exists() {
        return Err(format!("Path does not exist: {}", path));
    }

    let mut results = Vec::new();
    let depth = if recursion_depth == 0 {
        1
    } else {
        recursion_depth as usize + 1
    };

    for entry in WalkDir::new(path)
        .max_depth(depth)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let entry_path = entry.path();

        let metadata = match fs::metadata(entry_path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        if !metadata.is_file() && !metadata.is_dir() {
            continue;
        }

        let file_name: String = entry_path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default();

        let extension: String = entry_path
            .extension()
            .map(|e| e.to_string_lossy().to_lowercase())
            .unwrap_or_default();

        let is_directory = metadata.is_dir();

        let category = categorize_file(&extension, is_directory, &file_name);

        let hash = if is_directory {
            None
        } else {
            compute_hash(entry_path).ok()
        };

        let is_temp = is_temp_file(&extension, &file_name);

        let info = FileInfo {
            path: entry_path.display().to_string(),
            name: file_name,                 // already String (annotated above)
            extension: extension,            // already String
            size: metadata.len(),
            modified: metadata
                .modified()
                .map(|t| format!("{:?}", t)) // SystemTime has no Display
                .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string()),
            is_directory,
            is_duplicate: false,
            is_temp,
            category,
            hash,
        };

        results.push(info);
    }

    Ok(results)
}

pub(crate) fn categorize_file(extension: &str, is_directory: bool, name: &str) -> FileCategory {
    if is_directory {
        return FileCategory::Other;
    }

    let lower_ext = extension.to_lowercase();

    if [
        "jpg", "jpeg", "png", "gif", "bmp", "webp", "svg", "ico", "tiff", "tif", "heic", "heif",
        "raw", "cr2", "nef", "arw", "orf", "rw2",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::Image;
    }

    if [
        "mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "3gp", "mpg", "mpeg", "ts",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::Video;
    }

    if [
        "mp3", "wav", "aac", "flac", "ogg", "wma", "m4a", "opus", "aiff", "alac",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::Audio;
    }

    if [
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "odt", "ods", "odp",
        "csv", "epub", "mobi", "azw", "djvu", "fb2", "cbz", "md",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::Document;
    }

    if [
        "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "zst", "iso", "dmg", "deb", "apk", "jar",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::Archive;
    }

    if is_temp_file(extension, name) {
        return FileCategory::Temporary;
    }

    if [
        "db", "lock", "tmp", "log", "cache", "bak", "swp", "deny", "ini", "reg", "exe", "dll",
        "sys", "bin", "obj", "class", "war", "ear",
    ]
    .contains(&lower_ext.as_str())
    {
        return FileCategory::System;
    }

    FileCategory::Other
}

pub(crate) fn is_temp_file(extension: &str, name: &str) -> bool {
    let lower_name = name.to_lowercase();
    let lower_ext = extension.to_lowercase();

    if matches!(lower_ext.as_str(), "tmp" | "temp" | "bak" | "swp") {
        return true;
    }

    if lower_name.ends_with(".tmp") || lower_name.ends_with(".temp") {
        return true;
    }

    if lower_name.contains("temp") || lower_name.contains("tmp") || lower_name.contains("cache") {
        return true;
    }

    false
}

pub(crate) fn compute_hash(path: &Path) -> Result<String, String> {
    use md5::{Digest, Md5};
    use std::io::Read;

    let mut hasher = Md5::new();
    let mut file = fs::File::open(path).map_err(|e| e.to_string())?;
    let mut buffer = [0u8; 8192];

    loop {
        match file.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => hasher.update(&buffer[..n]),
            Err(e) => return Err(e.to_string()),
        }
    }

    Ok(format!("{:x}", hasher.finalize()))
}