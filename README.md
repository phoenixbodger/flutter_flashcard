# Flutter Flashcard App 🎴

A powerful, multi-language flashcard application with enhanced text-to-speech capabilities, multiple game modes, and an intuitive interface for effective learning.

## ✨ Features

### 🎴 Core Flashcard Functionality
- **Multi-sided cards** with custom headers
- **CSV Import/Export** for easy data management
- **Local storage** for offline use
- **Deck management** with create, edit, delete operations
- **Category system** to organize your decks
- **Default decks** included (Chinese Radicals, Hiragana, Expressions)
- **Click-to-edit** interface for quick deck editing

### 🎮 Interactive Learning Games
- **Study Mode**: Traditional flashcard review with audio
- **Typing Game**: Type answers from visual prompts
- **Audio Typing Game**: Type what you hear
- **Multiple Choice Game**: Select correct answers
- **Match Game**: Card matching exercises with zoom controls

### 🔊 Enhanced Audio Features
- **High-quality TTS** with optimized speech rate (0.90)
- **Multi-language support** with automatic detection
- **Premium voice selection** for natural sound
- **Sound effects** for game feedback
- **Language switching** for:
  - English (en-US)
  - Chinese (zh-CN)
  - Japanese (ja-JP)
  - Korean (ko-KR)
  - Arabic (ar-SA)
  - Russian (ru-RU)
  - Thai (th-TH)
  - Hindi (hi-IN)
  - Hebrew (he-IL)

### 🎯 Advanced Study Features
- **Comprehensive Help Section** with detailed guides
- **Spaced Retention** mode for optimized learning
- **Shuffle mode** for random review
- **Progress tracking** with scores and accuracy
- **Hint system** for difficult cards
- **Timer functionality** for speed practice
- **Responsive design** for all screen sizes
- **Zoom controls** in Match Game for better readability

### 🏠 Enhanced User Interface
- **Intuitive home screen** with category filtering
- **Clickable deck titles** for quick editing
- **Simplified action icons** (Delete, Move, Copy)
- **Refresh button** to reload decks from storage
- **Reset button** to update default decks from assets
- **Sound toggle** for audio preferences
- **Compact mode** for smaller screens

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Web browser (for web deployment)
- Android Studio/Xcode (for mobile deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_flashcard.git
   cd flutter_flashcard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Web version
   flutter run -d chrome
   
   # Mobile version
   flutter run
   ```

## 📱 Usage

### Home Screen Navigation
- **Click deck titles** to edit them (blue, underlined text)
- **Use action icons** below each deck:
  - 🗑️ Delete deck
  - 📁 Move deck to another category
  - 📋 Copy deck to another category
- **Top bar controls**:
  - 🔄 Refresh: Reload decks from storage
  - ↺ Reset: Reload default decks from assets
  - ❓ Help: Open comprehensive guide
  - 🔊/🔇 Toggle sounds on/off
- **Category dropdown**: Filter decks by category

### Creating Decks
1. Click "Create New Deck" (green + button) on the home screen
2. Enter deck title and headers (e.g., "Front", "Back")
3. Add cards with content for each side
4. Save your deck (automatically added to default category)

### Importing Decks
1. Click "Import Deck" (green + button) on home screen
2. Upload a CSV file with deck data
3. **CSV Format**: First row contains headers, subsequent rows contain data
   ```csv
   Question,Answer
   What is 2+2?,4
   Capital of France?,Paris
   Hello in Chinese,你好
   ```
4. Deck will be automatically added to the default category

### Exporting Decks
1. Click the export icon on any deck
2. Choose from multiple export options:
   - 📥 Download CSV file for spreadsheet editing
   - 📤 Share CSV file via email/messaging
   - 📋 Copy CSV content to clipboard

### Default Decks
The app includes built-in decks:
- **Chinese Radicals**: Essential Chinese characters
- **Chinese Expressions**: Common phrases for TV and movies
- **Hiragana**: Japanese syllabary

To update default decks after modifying CSV files:
1. Click the ↺ Reset button in the top bar
2. Confirm reset to reload from asset files
3. Your custom decks will be preserved

### Study Modes

#### 📚 Study Mode
- Click "Study" on any deck
- Navigate cards with arrow buttons
- Use speaker icon for audio pronunciation
- Switch between card sides
- Enable shuffle or spaced retention

#### 🎮 Game Modes
- **Typing Game**: Type answers from visual prompts
- **Audio Typing Game**: Listen and type what you hear
- **Multiple Choice**: Select correct answers from options
- **Match Game**: Match corresponding cards
  - 🔍 **Zoom controls**: Adjust text size for better readability
  - 📱 **Responsive layout**: More cards on larger screens
  - 🎯 **Memory training**: Find matching pairs efficiently

### Audio Settings
- Click the **Help button** (❓) in the top-right for comprehensive guides
- Click language button (EN, ES, FR, etc.) to change TTS language
- Audio automatically detects content language
- Enhanced TTS provides natural pronunciation
- Sound effects for game feedback:
  - 🎵 Game start sound
  - 🎯 Correct answer sound
  - ❌ Error sound
  - 🏁 Game over sound
- Adjustable speech rate in `lib/services/enhanced_tts_service.dart`

## 🔧 Customization

### Changing Speech Rate
Edit `lib/services/enhanced_tts_service.dart`:
```dart
await _flutterTts!.setSpeechRate(0.90); // Adjust this value
```

### Voice Selection
Edit the voice list in `_setOptimalVoices()`:
```dart
final voices = [
  {"name": "Alex", "locale": "en-US"},        // Male voice
  {"name": "Samantha", "locale": "en-US"},     // Female voice
  {"name": "Microsoft David", "locale": "en-US"}, // Windows voice
];
```

### Adding New Languages
Add language detection in `_detectLanguage()`:
```dart
if (text.contains(RegExp(r'[CHARACTER_RANGE]'))) {
  return 'language-code';
}
```

## 🌐 Deployment

### Web Deployment
1. **Build for web**
   ```bash
   flutter build web --base-href="/your-repo-name/"
   ```

2. **Deploy to GitHub Pages**
   ```bash
   # Install gh-pages (if not already installed)
   npm install -g gh-pages
   
   # Deploy to gh-pages branch
   gh-pages -d build/web
   ```

3. **Enable GitHub Pages**
   - Go to repository settings
   - Enable GitHub Pages from `gh-pages` branch
   - Set source to "Deploy from a branch"
   - Select `gh-pages` branch and `/ (root)` folder

4. **Access your app**
   ```
   https://yourusername.github.io/your-repo-name/
   ```

### Important Notes for GitHub Pages
- **Base href**: Always include `--base-href="/your-repo-name/"` when building
- **Asset paths**: Ensure all assets are properly uploaded to `gh-pages` branch
- **Browser cache**: Clear cache after deployment to see latest changes
- **Default decks**: Use the reset button (↺) to reload default decks after updating CSV files

### Mobile Deployment

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── models/
│   ├── flashcard_model.dart      # Flashcard data models
│   └── category_model.dart       # Category management models
├── services/
│   ├── enhanced_tts_service.dart # Enhanced TTS functionality
│   ├── import_service.dart       # CSV import/export functionality
│   ├── settings_service.dart     # App settings and preferences
│   ├── default_deck_service.dart # Default deck management
│   ├── sound_service.dart        # Game sound effects
│   └── category_service.dart     # Category management
├── screens/
│   ├── home_screen.dart          # Main screen with deck management
│   ├── deck_management_screen.dart # Deck CRUD operations
│   ├── deck_viewer_screen.dart   # Study mode
│   ├── typing_game_screen.dart   # Typing game
│   ├── audio_typing_game_screen.dart # Audio typing
│   ├── multiple_choice_game_screen.dart # Multiple choice
│   ├── match_game_screen.dart     # Match game with zoom controls
│   └── help_screen.dart          # Comprehensive help guide
└── main.dart                     # App entry point
```

## 🎯 Key Features Explained

### Enhanced User Interface
- **Click-to-edit**: Simply click deck titles to edit them
- **Simplified actions**: Reduced icon clutter with intuitive layout
- **Category system**: Organize decks by subject or difficulty
- **Responsive design**: Works perfectly on all screen sizes
- **Refresh functionality**: Keep your data synchronized

### CSV Import/Export System
- **Easy data management**: Use spreadsheet software to edit decks
- **Multiple export options**: Download, share, or copy to clipboard
- **Format validation**: Automatic error checking for CSV files
- **Bulk operations**: Import large decks efficiently

### Enhanced TTS Service
- **Automatic language detection** based on character content
- **High-quality voice selection** with platform optimization
- **Optimal speech rate** (0.90) for intermediate learners
- **Multi-language support** with seamless switching

### Game Mechanics
- **Scoring system** with accuracy tracking
- **Hint system** with point deduction
- **Timer functionality** for speed practice
- **Progress tracking** across sessions
- **Zoom controls** for better readability
- **Responsive layouts** for different screen sizes
- **Sound effects** for enhanced engagement

## 🔧 Troubleshooting

### Common Issues & Solutions

**🎵 Audio not working?**
- Check browser permissions for audio
- Try refreshing the page
- Ensure speakers/headphones are connected
- Click 🔊/🔇 icon to toggle sounds on/off

**🔄 New decks not appearing?**
- Click 🔄 Refresh button to reload from storage
- Check if deck is in the correct category
- Try switching to "All" category to see all decks

**📦 Default decks outdated?**
- Click ↺ Reset button to reload from asset files
- This updates default decks if you modified CSV files
- Your custom decks will be preserved

**🎮 Match Game text too small?**
- Use 🔍 Zoom In button to increase text size
- Use 🔍 Zoom Out button to decrease text size
- Use 🔍 Reset Zoom to return to normal size

**📥 Import not working?**
- Verify CSV format is correct (headers in first row)
- Check file size (should be < 5MB)
- Ensure required fields are present
- Try exporting a deck to see correct format

**🌐 Web deployment issues?**
- Ensure `--base-href="/your-repo-name/"` is set when building
- Upload all files from `build/web/` to `gh-pages` branch
- Clear browser cache after deployment
- Check GitHub Pages settings in repository

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Flutter TTS community for audio functionality
- Enhanced TTS integration for improved learning experience
- GitHub Pages for hosting the web application

## 📞 Support

For issues, questions, or feature requests:
- Create an issue on GitHub
- Check existing documentation
- Review code comments for implementation details
- Use the in-app Help section (❓ button) for detailed guides

## 📖 Stroke Order Feature

**Chinese Character Stroke Order Visualization**
- For Chinese characters in decks, stroke order animations are displayed when available
- Each character's stroke order data is automatically detected and shown during study sessions
- When multiple characters are present in a word, only the first character's stroke order is displayed
- Users can navigate through words using previous/next buttons

---

**Happy Learning! 🎓**
