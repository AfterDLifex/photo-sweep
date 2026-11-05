import { Injectable, signal, computed } from '@angular/core';

export enum FileCategory {
  Image = 'image',
  Video = 'video',
  Audio = 'audio',
  Document = 'document',
  Archive = 'archive',
  Temporary = 'temporary',
  System = 'system',
  Other = 'other'
}

export interface FileItem {
  path: string;
  name: string;
  extension: string;
  size: number;
  modified: string;
  isDirectory: boolean;
  isDuplicate: boolean;
  isTemp: boolean;
  category: FileCategory;
  categoryLabel: string;
}

export interface DuplicateGroup {
  hash: string;
  files: string[];
  size: number;
}

export interface AnalysisResult {
  directory: string;
  scanned: number;
  duplicates: DuplicateGroup[];
  tempFiles: FileItem[];
  categories: { category: FileCategory; count: number; size: number }[];
  totalSize: number;
  analysisTimeMs: number;
}

@Injectable({
  providedIn: 'root'
})
export class FolderService {
  private files = signal<FileItem[]>([]);
  private duplicates = signal<DuplicateGroup[]>([]);
  private tempFiles = signal<FileItem[]>([]);
  private analysisResult = signal<AnalysisResult | null>(null);

  readonly fileTypes = Object.values(FileCategory);
  readonly categoryLabels: Record<FileCategory, string> = {
    [FileCategory.Image]: 'Image',
    [FileCategory.Video]: 'Video',
    [FileCategory.Audio]: 'Audio',
    [FileCategory.Document]: 'Document',
    [FileCategory.Archive]: 'Archive',
    [FileCategory.Temporary]: 'Temporary',
    [FileCategory.System]: 'System',
    [FileCategory.Other]: 'Other'
  };

  getFiles() { return this.files(); }
  getDuplicates() { return this.duplicates(); }
  getTempFiles() { return this.tempFiles(); }
  getAnalysisResult() { return this.analysisResult(); }

  getTotalFileCount() { return computed(() => this.files().length); }
  getTotalSize() { return computed(() => this.files().reduce((sum, f) => sum + f.size, 0)); }
  getDuplicateCount() { return computed(() => this.duplicates().reduce((sum, d) => sum + d.files.length, 0)); }
  getTempFileCount() { return computed(() => this.tempFiles().length); }

  setFiles(files: FileItem[]): void {
    this.files.set(files);
  }

  setAnalysisResult(result: AnalysisResult): void {
    this.analysisResult.set(result);
    this.duplicates.set(result.duplicates);
    this.tempFiles.set(result.tempFiles);
  }

  addFile(file: FileItem): void {
    this.files.update(files => [...files, file]);
  }

  removeFile(path: string): void {
    this.files.update(files => files.filter(f => f.path !== path));
  }

  updateFileSize(path: string, size: number): void {
    this.files.update(files =>
      files.map(f => f.path === path ? { ...f, size } : f)
    );
  }

  clearFiles(): void {
    this.files.set([]);
  }
}
