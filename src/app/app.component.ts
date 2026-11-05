import { Component, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GalleryComponent } from './gallery/gallery.component';
import { AnalysisComponent } from './analysis/analysis.component';
import { CleaningComponent } from './cleaning/cleaning.component';
import { ThemeService } from './theme/theme.service';

type Tab = 'gallery' | 'analysis' | 'cleaning';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, GalleryComponent, AnalysisComponent, CleaningComponent],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  isDarkMode = signal(false);
  currentTab = signal<Tab>('gallery');

  constructor(private themeService: ThemeService) {}

  ngOnInit(): void {
    this.isDarkMode.set(this.themeService.isDarkMode());
  }

  setTab(tab: Tab): void {
    this.currentTab.set(tab);
  }

  get isDarkModeValue(): boolean {
    return this.isDarkMode();
  }

  onToggleTheme(): void {
    this.themeService.toggleTheme();
    this.isDarkMode.set(this.themeService.isDarkMode());
  }
}
