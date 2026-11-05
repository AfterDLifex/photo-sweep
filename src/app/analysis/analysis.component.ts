import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FolderService, FileCategory, AnalysisResult, DuplicateGroup } from '../folder.service';
import { ThemeService } from '../theme/theme.service';

@Component({
  selector: 'app-analysis',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './analysis.component.html',
  styleUrls: ['./analysis.component.css']
})
export class AnalysisComponent implements OnInit {
  analysisResult: AnalysisResult | null = null;
  isLoading = false;
  categories: { category: FileCategory; count: number; size: number }[] = [];
  totalSize = 0;
  duplicateCount = 0;
  isDarkMode = signal(false);

  constructor(
    private folderService: FolderService,
    private themeService: ThemeService
  ) {}

  ngOnInit(): void {
    this.isDarkMode.set(this.themeService.isDarkMode());
    this.loadAnalysis();
  }

  loadAnalysis(): void {
    this.isLoading = true;
    setTimeout(() => {
      const sample: AnalysisResult = {
        directory: '/Storage',
        scanned: 1247,
        duplicates: [
          { hash: 'abc123', files: ['/Photos/Dup1.jpg', '/Photos/Dup2.jpg', '/Photos/Dup3.jpg'], size: 51200000 },
          { hash: 'def456', files: ['/Documents/copy.docx', '/Documents/copy2.docx'], size: 10240000 }
        ],
        tempFiles: [
          { path: '/tmp/temp1.tmp', name: 'temp1.tmp', extension: 'tmp', size: 2048, modified: '2026-11-03', isDirectory: false, isDuplicate: false, isTemp: true, category: FileCategory.Temporary, categoryLabel: 'Temporary' },
          { path: '/tmp/temp2.tmp', name: 'temp2.tmp', extension: 'tmp', size: 4096, modified: '2026-11-03', isDirectory: false, isDuplicate: false, isTemp: true, category: FileCategory.Temporary, categoryLabel: 'Temporary' }
        ],
        categories: [
          { category: FileCategory.Image, count: 450, size: 2350000000 },
          { category: FileCategory.Video, count: 120, size: 850000000 },
          { category: FileCategory.Audio, count: 80, size: 105000000 },
          { category: FileCategory.Document, count: 200, size: 65000000 },
          { category: FileCategory.Archive, count: 50, size: 35000000 },
          { category: FileCategory.Temporary, count: 50, size: 1234567 }
        ],
        totalSize: 3500000000,
        analysisTimeMs: 1234
      };

      this.analysisResult = sample;
      this.categories = sample.categories;
      this.totalSize = sample.totalSize;
      this.duplicateCount = sample.duplicates.reduce((sum, d) => sum + d.files.length, 0);
      this.isLoading = false;
    }, 800);
  }

  onToggleTheme(): void {
    this.themeService.toggleTheme();
    this.isDarkMode.set(this.themeService.isDarkMode());
  }

  onClean(): void {
    // Navigate to cleaning tab via parent
    console.log('Clean requested');
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

  formatSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
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

  formatCount(count: number): string {
    if (count >= 1000000) return (count / 1000000).toFixed(1) + 'M';
    if (count >= 1000) return (count / 1000).toFixed(1) + 'K';
    return count.toString();
  }
}
