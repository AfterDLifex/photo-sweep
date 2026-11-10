import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FolderService, FileCategory, FileItem } from '../folder.service';
import { ThemeService } from '../theme/theme.service';

@Component({
  selector: 'app-cleaning',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './cleaning.component.html',
  styleUrls: ['./cleaning.component.css']
})
export class CleaningComponent implements OnInit {
  scanType: 'duplicates' | 'temp' = 'duplicates';
  files: FileItem[] = [];
  tempFiles: FileItem[] = [];
  isLoading = false;
  selectedFiles: Set<string> = new Set();
  canSelectAll = false;
  cleared = false;
  clearedMessage = '';
  isDarkMode = signal(false);
  isGridView = signal(true);

  constructor(
    private folderService: FolderService,
    private themeService: ThemeService
  ) { }

  ngOnInit(): void {
    this.isDarkMode.set(this.themeService.isDarkMode());
    this.loadFiles();
  }

  loadFiles(): void {
    this.isLoading = true;
    setTimeout(() => {
      const sample: FileItem[] = [
        { path: '/Photos/Dup1.jpg', name: 'Dup1.jpg', extension: 'jpg', size: 10240000, modified: '2026-10-30', isDirectory: false, isDuplicate: true, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' },
        { path: '/Photos/Dup2.jpg', name: 'Dup2.jpg', extension: 'jpg', size: 10240000, modified: '2026-10-30', isDirectory: false, isDuplicate: true, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' },
        { path: '/Photos/IMG_001.jpg', name: 'IMG_001.jpg', extension: 'jpg', size: 2450000, modified: '2026-11-01', isDirectory: false, isDuplicate: false, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' },
        { path: '/tmp/temp1.tmp', name: 'temp1.tmp', extension: 'tmp', size: 2048, modified: '2026-11-03', isDirectory: false, isDuplicate: false, isTemp: true, category: FileCategory.Temporary, categoryLabel: 'Temporary' },
        { path: '/tmp/temp2.tmp', name: 'temp2.tmp', extension: 'tmp', size: 4096, modified: '2026-11-03', isDirectory: false, isDuplicate: false, isTemp: true, category: FileCategory.Temporary, categoryLabel: 'Temporary' },
        { path: '/Photos/IMG_002.jpg', name: 'IMG_002.jpg', extension: 'jpg', size: 2630000, modified: '2026-11-01', isDirectory: false, isDuplicate: false, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' }
      ];

      if (this.scanType === 'duplicates') {
        this.files = sample.filter(f => f.isDuplicate);
      } else {
        this.files = sample.filter(f => f.isTemp);
      }
      this.tempFiles = sample.filter(f => f.isTemp || f.isDuplicate);
      this.selectedFiles = new Set();
      this.canSelectAll = this.files.length > 0;
      this.isLoading = false;
    }, 600);
  }
  get duplicateCount(): number {
    return this.tempFiles.filter(f => f.isDuplicate).length;
  }

  get tempFileCount(): number {
    return this.tempFiles.filter(f => f.isTemp).length;
  }

  toggleSelectAll(): void {
    if (this.selectedFiles.size === this.files.length) {
      this.selectedFiles.clear();
    } else {
      this.files.forEach(f => this.selectedFiles.add(f.path));
    }
    this.canSelectAll = this.selectedFiles.size !== this.files.length;
  }

  toggleSelect(path: string): void {
    if (this.selectedFiles.has(path)) {
      this.selectedFiles.delete(path);
    } else {
      this.selectedFiles.add(path);
    }
    this.canSelectAll = this.selectedFiles.size !== this.files.length;
  }

  getSelectedCount(): number {
    return this.selectedFiles.size;
  }

  formatSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }

  onToggleTheme(): void {
    this.themeService.toggleTheme();
    this.isDarkMode.set(this.themeService.isDarkMode());
  }

  getCategoryIcon(category: FileCategory): string {
    const icons: Record<FileCategory, string> = {
      [FileCategory.Image]: 'photo_library',
      [FileCategory.Video]: 'movie',
      [FileCategory.Audio]: 'music_note',
      [FileCategory.Document]: 'description',
      [FileCategory.Archive]: 'folder_zip',
      [FileCategory.Temporary]: 'delete',
      [FileCategory.System]: 'settings_backup',
      [FileCategory.Other]: 'folder'
    };
    return icons[category];
  }

  getIcon(category: FileCategory): string {
    const icons: Record<FileCategory, string> = {
      [FileCategory.Image]: 'photo_library',
      [FileCategory.Video]: 'movie',
      [FileCategory.Audio]: 'music_note',
      [FileCategory.Document]: 'description',
      [FileCategory.Archive]: 'folder_zip',
      [FileCategory.Temporary]: 'delete',
      [FileCategory.System]: 'settings_backup',
      [FileCategory.Other]: 'folder'
    };
    return icons[category];
  }

  getCategoryColor(category: FileCategory): string {
    const colors: Record<FileCategory, string> = {
      [FileCategory.Image]: 'primary',
      [FileCategory.Video]: 'info',
      [FileCategory.Audio]: 'info',
      [FileCategory.Document]: 'info',
      [FileCategory.Archive]: 'secondary',
      [FileCategory.Temporary]: 'warning',
      [FileCategory.System]: 'danger',
      [FileCategory.Other]: ''
    };
    return colors[category];
  }

  getFileIcon(category: FileCategory): string {
    const icons: Record<FileCategory, string> = {
      [FileCategory.Image]: 'photo_library',
      [FileCategory.Video]: 'movie',
      [FileCategory.Audio]: 'music_note',
      [FileCategory.Document]: 'description',
      [FileCategory.Archive]: 'folder_zip',
      [FileCategory.Temporary]: 'delete',
      [FileCategory.System]: 'settings_backup',
      [FileCategory.Other]: 'folder'
    };
    return icons[category];
  }

  clearSelection(): void {
    this.selectedFiles.clear();
    this.canSelectAll = false;
  }

  confirmClean(): void {
    this.isLoading = true;
    setTimeout(() => {
      const deleted = this.selectedFiles.size;
      const freedSize = this.selectedFiles.size * 1024;
      this.cleared = true;
      this.clearedMessage = `Cleaned ${deleted} file(s) and freed ${this.formatSize(freedSize)} of space.`;
      this.loadFiles();
      this.isLoading = false;
    }, 1500);
  }

  cancelClean(): void {
    this.selectedFiles.clear();
    this.canSelectAll = false;
  }
}