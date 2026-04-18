# Miss IDE - Mobile IDE for Android Decompilation

A powerful mobile IDE for Android decompilation, supporting APK/DEX/Smali analysis, code editing, and file comparison.

## Features

- **Project Management**: Create, open, and manage decompilation projects
- **Code Editor**: Syntax highlighting for Smali/Java/Dex
- **File Comparison**: Myers Diff algorithm with visual highlighting
- **Decompilation**: APK/DEX file analysis and viewing
- **Mobile-Optimized**: Designed for Android devices

## Getting Started

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
├── app/           # Application configuration
├── core/          # Core utilities and constants
├── features/      # Feature modules
│   ├── project/   # Project management
│   ├── editor/    # Code editor
│   ├── decompile/ # Decompilation
│   └── diff/      # File comparison
├── engine/        # Core engines (Diff, Decompile, Syntax)
├── platform/      # Platform channels
└── shared/       # Shared components
```

## License

Proprietary - Miss IDE Team
