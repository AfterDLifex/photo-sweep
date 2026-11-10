import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FolderService, FileItem, FileCategory } from '../folder.service';
import { ThemeService } from '../theme/theme.service';

@Component({
  selector: 'app-gallery',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './gallery.component.html',
  styleUrls: ['./gallery.component.css']
})
export class GalleryComponent implements OnInit {
  files: FileItem[] = [];
  categories: { category: FileCategory; count: number; size: number }[] = [];
  isLoading = false;
  isDarkMode = signal(false);
  isGridView = signal(true);

  constructor(
    private folderService: FolderService,
    private themeService: ThemeService
  ) {}

  ngOnInit(): void {
    this.isDarkMode.set(this.themeService.isDarkMode());
    this.loadFiles();
  }

  loadFiles(): void {
    this.isLoading = true;
    const sampleFiles: FileItem[] = [
      { path: '/Photos/Vacation/IMG_001.jpg', name: 'IMG_001.jpg', extension: 'jpg', size: 2450000, modified: '2026-11-01', isDirectory: false, isDuplicate: false, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' },
      { path: '/Photos/Vacation/IMG_003.jpg', name: 'IMG_003.jpg', extension: 'jpg', size: 2980000, modified: '2026-10-31', isDirectory: false, isDuplicate: true, isTemp: false, category: FileCategory.Image, categoryLabel: 'Image' },
      { path: '/Photos/Vacation/Screenrec.mp4', name: 'Screenrec.mp4', extension: 'mp4', size: 15200000, modified: '2026-10-30', isDirectory: false, isDuplicate: false, isTemp: false, category: FileCategory.Video, categoryLabel: 'Video' },
      { path: '/Photos/Vacation/Temp.tmp', name: 'Temp.tmp', extension: 'tmp', size: 2048, modified: '2026-11-03', isDirectory: false, isDuplicate: false, isTemp: true, category: FileCategory.Temporary, categoryLabel: 'Temporary' }
    ];
    setTimeout(() => {
      this.files = sampleFiles;
      this.folderService.setFiles(sampleFiles);
      this.isLoading = false;
    }, 600);
  }

  get totalFiles(): number {
    return this.files.length;
  }

  get totalSize(): number {
    return this.files.reduce((sum, f) => sum + f.size, 0);
  }

  get tempFileCount(): number {
    return this.files.filter(f => f.isTemp).length;
  }

  onToggleTheme(): void {
    this.themeService.toggleTheme();
    this.isDarkMode.set(this.themeService.isDarkMode());
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

  formatSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }
}
