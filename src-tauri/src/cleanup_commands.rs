use crate::folder_commands::{categorize_file, compute_hash, is_temp_file};
use crate::models::*;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[tauri::command]
pub fn scan_for_duplicates(path: &str, skip_hidden: bool) -> Result<AnalysisResult, String> {
    let start = std::time::Instant::now();

    let base = PathBuf::from(path);
    if !base.exists() {
        return Err(format!("Path does not exist: {}", path));
    }

    let mut file_map: HashMap<String, Vec<String>> = HashMap::new();
    let mut total_files = 0u64;
    let mut total_size = 0u64;
    let mut categories: HashMap<String, (u64, u64)> = HashMap::new();

    for entry in WalkDir::new(path)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let entry_path = entry.path();
        if !entry_path.exists() {
            continue;
        }

        let metadata = match fs::metadata(entry_path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        if metadata.is_dir() {
            continue;
        }

        total_files += 1;
        total_size += metadata.len();

        let ext = entry_path
            .extension()
            .map(|e| e.to_string_lossy().to_lowercase())
            .unwrap_or_default();

        let category = categorize_file(
            &ext,
            false,
            &entry_path
                .file_name()
                .map(|n| n.to_string_lossy())
                .unwrap_or_default(),
        );

        let cat_key = format!("{:?}", category);
        let cat_entry = categories.entry(cat_key).or_insert((0u64, 0u64));
        cat_entry.0 += 1;
        cat_entry.1 += metadata.len();

        if skip_hidden && is_hidden_file(entry_path) {
            continue;
        }

        if let Ok(hash) = compute_hash(entry_path) {
            file_map
                .entry(hash)
                .or_insert_with(Vec::new)
                .push(entry_path.display().to_string());
        }
    }

    let mut accurate_dups = Vec::new();
    for (hash, paths) in file_map {
        if paths.len() > 1 {
            let group_size: u64 = paths
                .iter()
                .map(|p| fs::metadata(p).map(|m| m.len()).unwrap_or(0))
                .sum();
            accurate_dups.push(DuplicateGroup {
                hash,
                files: paths,
                size: group_size,
            });
        }
    }

    let temp_files = scan_for_temp_files(path, skip_hidden);

    let categories_vec: Vec<CategoryCount> = categories
        .into_iter()
        .map(|(k, (count, size))| CategoryCount {
            category: categorize_by_name(&k),
            count,
            size,
        })
        .collect();

    Ok(AnalysisResult {
        directory: path.to_string(),
        scanned: total_files,
        duplicates: accurate_dups,
        temp_files,
        categories: categories_vec,
        total_size,
        analysis_time_ms: start.elapsed().as_millis() as u64,
    })
}

#[tauri::command]
pub fn scan_for_temp_files(path: &str, skip_hidden: bool) -> Vec<FileInfo> {
    let base = PathBuf::from(path);
    if !base.exists() {
        return Vec::new();
    }

    let mut results = Vec::new();

    for entry in WalkDir::new(path)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let entry_path = entry.path();
        if !entry_path.exists() {
            continue;
        }

        let metadata = match fs::metadata(entry_path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        if metadata.is_dir() {
            continue;
        }

        if skip_hidden && is_hidden_file(entry_path) {
            continue;
        }

        let file_name = entry_path
            .file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_default();

        let extension = entry_path
            .extension()
            .map(|e| e.to_string_lossy().to_lowercase())
            .unwrap_or_default();

        let is_temp = is_temp_file(&extension, &file_name);
        let category = if is_temp {
            FileCategory::Temporary
        } else {
            FileCategory::Other
        };

        let info = FileInfo {
            path: entry_path.display().to_string(),
            name: file_name,
            extension,
            size: metadata.len(),
            modified: metadata
                .modified()
                .map(|t| format!("{:?}", t))
                .unwrap_or_else(|_| "1970-01-01T00:00:00Z".to_string()),
            is_directory: false,
            is_duplicate: false,
            is_temp,
            category,
            hash: None,
        };

        if is_temp {
            results.push(info);
        }
    }

    results
}

fn is_hidden_file(path: &Path) -> bool {
    if let Some(name) = path.file_name() {
        let name_str = name.to_string_lossy().to_lowercase();
        if name_str.starts_with('.') {
            return true;
        }
    }
    false
}

fn categorize_by_name(key: &str) -> FileCategory {
    match key {
        "Image" => FileCategory::Image,
        "Video" => FileCategory::Video,
        "Audio" => FileCategory::Audio,
        "Document" => FileCategory::Document,
        "Archive" => FileCategory::Archive,
        "Temporary" => FileCategory::Temporary,
        "System" => FileCategory::System,
        _ => FileCategory::Other,
    }
}

#[tauri::command]
pub fn delete_files(files: Vec<String>, target_type: &str) -> Result<CleanupResult, String> {
    if files.is_empty() {
        return Err("No files specified".to_string());
    }

    let mut deleted_count = 0u64;
    let mut total_freed = 0u64;

    for file_path in &files {
        let path = PathBuf::from(file_path);
        if path.exists() {
            // Read size BEFORE removing the file.
            let file_size = path.metadata().map(|m| m.len()).unwrap_or(0);

            match fs::remove_file(&path) {
                Ok(_) => {
                    total_freed += file_size;
                    deleted_count += 1;
                }
                Err(e) => {
                    return Err(format!("Failed to delete {}: {}", file_path, e));
                }
            }
        }
    }

    Ok(CleanupResult {
        target_type: target_type.to_string(),
        files_deleted: deleted_count,
        bytes_freed: total_freed,
        path: PathBuf::from(files[0].clone())
            .parent()
            .map(|p| p.display().to_string())
            .unwrap_or_default(),
        message: format!(
            "Deleted {} file(s), freed {} bytes",
            deleted_count, total_freed
        ),
    })
}

/// Kept for reference; `compute_hash` from `folder_commands` already does this.
#[allow(dead_code)]
fn compute_hash_local(path: &Path) -> Result<String, String> {
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

#[tauri::command]
pub fn get_storage_stats(path: &str) -> Result<StorageStats, String> {
    let analysis = scan_for_duplicates(path, false)?;
    Ok(StorageStats {
        total_files: analysis.scanned,
        total_size: analysis.total_size,
        duplicate_count: analysis.duplicates.len() as u64,
        temp_file_count: analysis.temp_files.len() as u64,
        categories: analysis.categories,
        available_space_bytes: 0,
    })
}
