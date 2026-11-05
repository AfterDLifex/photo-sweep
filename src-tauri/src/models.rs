use serde::Serialize;
use std::path::PathBuf;

#[derive(Serialize, Clone, Debug)]
pub struct FileInfo {
    pub path: String,
    pub name: String,
    pub extension: String,
    pub size: u64,
    pub modified: String,
    pub is_directory: bool,
    pub is_duplicate: bool,
    pub is_temp: bool,
    pub category: FileCategory,
    pub hash: Option<String>,
}

#[derive(Serialize, Clone, Debug, PartialEq)]
pub enum FileCategory {
    Image,
    Video,
    Audio,
    Document,
    Archive,
    Temporary,
    System,
    Other,
}

#[derive(Serialize, Clone, Debug)]
pub struct AnalysisResult {
    pub directory: String,
    pub scanned: u64,
    pub duplicates: Vec<DuplicateGroup>,
    pub temp_files: Vec<FileInfo>,
    pub categories: Vec<CategoryCount>,
    pub total_size: u64,
    pub analysis_time_ms: u64,
}

#[derive(Serialize, Clone, Debug)]
pub struct DuplicateGroup {
    pub hash: String,
    pub files: Vec<String>,
    pub size: u64,
}

#[derive(Serialize, Clone, Debug)]
pub struct CategoryCount {
    pub category: FileCategory,
    pub count: u64,
    pub size: u64,
}

#[derive(Serialize, Clone, Debug)]
pub struct StorageStats {
    pub total_files: u64,
    pub total_size: u64,
    pub duplicate_count: u64,
    pub temp_file_count: u64,
    pub categories: Vec<CategoryCount>,
    pub available_space_bytes: u64,
}

#[derive(Serialize, Clone, Debug)]
pub struct ScanProgress {
    pub current: u64,
    pub total: u64,
    pub current_file: String,
    pub scanned_bytes: u64,
    pub is_complete: bool,
}

#[derive(Serialize, Clone, Debug)]
pub struct CleanupResult {
    pub target_type: String,
    pub files_deleted: u64,
    pub bytes_freed: u64,
    pub path: String,
    pub message: String,
}

#[derive(Serialize, Clone, Debug)]
pub struct FileHash {
    pub path: String,
    pub hash: String,
    pub size: u64,
}