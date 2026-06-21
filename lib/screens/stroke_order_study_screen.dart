import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

/// Study mode screen that displays Chinese characters with animated
/// stroke order visualization using Hanzi Writer (loaded from CDN for web).
class StrokeOrderStudyScreen extends StatefulWidget {
  final List<Flashcard<String>> cards;
  
  const StrokeOrderStudyScreen({
    super.key,
    required this.cards,
  });

  @override
  State<StrokeOrderStudyScreen> createState() => _StrokeOrderStudyScreenState();
}

class _StrokeOrderStudyScreenState extends State<StrokeOrderStudyScreen> {
  int _currentIndex = 0;
  int _currentCharIndex = 0;
  bool _isLoading = true;
  String? _hanziWriterError;
  dynamic _hanziWriterInstance;
  bool _isRegistered = false;

  /// Container for Hanzi Writer canvas (used with HtmlElementView) - initialized in initState() below
  late html.Element _container;
  
  /// Dynamic viewType string based on widget instance to prevent registration conflicts.
  /// Using widget hashCode ensures each deck/screen gets a unique identifier.
  String get _viewType => '${widget.hashCode}_hanzi';

  String get _currentWord => 
    _currentIndex < widget.cards.length && widget.cards[_currentIndex].sides.isNotEmpty
        ? widget.cards[_currentIndex].sides[0]
        : '';

  /// Extract the character to display based on current indices
  String get _currentCharacter {
    final word = _currentWord;
    if (word.isEmpty) return '';
    if (word.length > 1 && hasChineseCharsInWord(word)) {
      return word.substring(_currentCharIndex, _currentCharIndex + 1);
    }
    return word;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize container with explicit dimensions required by HtmlElementView platform view factory
    if (kIsWeb) {
      _container = html.Element.tag('div');
      _container.style.display = 'block';
      _container.style.width = '280px';
      _container.style.height = '350px';
      
      // Clear any residual content before registration
      _container.innerHtml = '';
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb && hasChineseCharsInWord(_currentWord)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _registerHanziWriterViewAndAnimate();
      });
    }
  }

  /// Register platform view factory with dynamic viewType and animate
  Future<void> _registerHanziWriterViewAndAnimate() async {
    final currentViewType = _viewType;
    
    if (!_isRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(
        currentViewType,
        (int viewId) => _container,
      );
      _isRegistered = true;
    }
    
    await _loadHanziWriterAndAnimate();
  }

  /// Check if Hanzi Writer is loaded and then animate
  Future<void> _loadHanziWriterAndAnimate() async {
    int attempts = 0;
    final maxAttempts = 30; // 3 seconds total
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      try {
        dynamic hanziWriter = _getGlobalHanziWriter();
        if (hanziWriter != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = false);
    });
          // Defer to next frame so canvas renders first
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _animateCharacter();
          });
          return;
        }
      } catch (_) {}
      attempts++;
    }
    
    debugPrint('Failed to load Hanzi Writer after $maxAttempts attempts');
    setState(() => _isLoading = false);
  }

  /// Get global HanziWriter from window object on web
  dynamic _getGlobalHanziWriter() {
    if (!kIsWeb) return null;
    try {
      final win = js.context['HanziWriter'];
      return win;
    } catch (_) {}
    return null;
  }

  /// Check if a string contains any CJK Unicode characters
  bool hasChineseCharsInWord(String word) {
    if (word.isEmpty) return false;
    for (int i = 0; i < word.length; i++) {
      final codeUnit = word.codeUnitAt(i);
      // Check for CJK Unified Ideographs and related ranges
      if ((codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) ||
          (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
          (codeUnit >= 0x3400 && codeUnit <= 0x4DBF)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a single character contains CJK Unicode characters
  bool _hasChineseChar(String char) {
    if (char.isEmpty) return false;
    // Check for CJK Unified Ideographs (U+4E00 - U+9FFF), 
    // CJK Extension A (U+3400 - U+4DBF), 
    // CJK Extension B (U+20000 - U+2A6DF), 
    // and related ranges
    for (int i = 0; i < char.length; i++) {
      final codeUnit = char.codeUnitAt(i);
      // Check supplementary planes for characters outside BMP
      if (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) {
        return true;
      }
      if ((codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
          (codeUnit >= 0x3400 && codeUnit <= 0x4DBF)) {
        return true;
      }
    }
    return false;
  }

  /// Animate the current character with Hanzi Writer
  Future<void> _animateCharacter() async {
    final charToShow = _currentCharacter;
    
    // Validate that we have a Chinese character before attempting to animate
    if (charToShow.isEmpty) {
      debugPrint('Hanzi Writer: No character provided for animation.');
      return;
    }
    
    if (!_hasChineseChar(charToShow)) {
      debugPrint('Hanzi Writer: Character "$charToShow" contains no CJK Unicode characters. Skipping animation.');
      if (mounted) {
        setState(() {
          _hanziWriterError = null; // Clear any previous error for clean message
        });
      }
      return;
    }
    
    setState(() {
      _hanziWriterError = null;
    });
    
    dynamic hanziWriter;
    try {
      hanziWriter = _getGlobalHanziWriter();
    } catch (_) {}
    
    if (hanziWriter == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hanziWriterError = 'Hanzi Writer library failed to load from CDN. Stroke animation will not be available.';
        });
      }
      return;
    }
    
    // Dispose previous instance if it exists
    if (_hanziWriterInstance != null) {
      try {
        _hanziWriterInstance.callMethod('dispose', []);
      } catch (_) {}
      _hanziWriterInstance = null;
    }
    
    // Clear any previous children from the container
    _container.innerHtml = '';
    
    try {
      // Create Hanzi Writer instance using JS interop with the canvas element directly
      final config = js.JsObject(js.context['Object']);
      config['width'] = 280;
      config['height'] = 280;
      config['padding'] = 5;
      config['showOutline'] = true;
      config['strokeAnimationDuration'] = 800;
      config['strokeWidth'] = 3;
      config['backgroundColor'] = '#ffffff';
      config['radicalColor'] = '#198038';
      
      // Pass the container div directly to HanziWriter.create — it creates its own SVG inside
      final writer = hanziWriter.callMethod('create', [_container, charToShow, config]);
      
      if (writer != null && mounted) {
        _hanziWriterInstance = writer;
        
        // Show character first, then animate after a short delay
        writer.callMethod('showCharacter', []);
        
        if (mounted) {
          setState(() { _isLoading = false; });
        }
        
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          writer.callMethod('animateCharacter', []);
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hanziWriterError = 'Failed to create Hanzi Writer instance for: $charToShow';
        });
      }
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Hanzi Writer error: $errorMessage');
      
      // Differentiate between error types
      if (mounted) {
        if (errorMessage.contains('Failed to load character data') || 
            errorMessage.contains('Call setCharacter and try again')) {
          // Character data loading failure - likely no valid CJK characters
          setState(() {
            _isLoading = false;
            _hanziWriterError = 'No Chinese character available for stroke order animation. The text may not contain valid Chinese characters.';
          });
        } else if (errorMessage.contains('canvas') || 
                   errorMessage.contains('rendering') ||
                   errorMessage.contains('width') || 
                   errorMessage.contains('height')) {
          // Canvas rendering issues - provide debug info and attempt recovery
          setState(() {
            _isLoading = false;
            _hanziWriterError = 'Canvas rendering error. Please ensure the display area has proper dimensions.';
          });
          // Attempt recovery by reinitializing container
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              debugPrint('Hanzi Writer: Attempting recovery by re-initializing container...');
              _container.style.width = '280px';
              _container.style.height = '350px';
              _container.style.display = 'block';
              _container.innerHtml = '';
              // Retry animation after recovery
              _animateCharacter();
            }
          });
        } else {
          // Other errors - show generic message with debug info
          setState(() {
            _isLoading = false;
            _hanziWriterError = 'Hanzi Writer error. Animation may not display correctly.';
          });
        }
      }
    }
  }

  /// Navigate to next card and update character display
  Future<void> _nextCard() async {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _currentCharIndex = 0;
        _hanziWriterError = null;
        _isLoading = true;
      });
      if (kIsWeb && hasChineseCharsInWord(_currentWord)) {
        // Clean up previous Hanzi Writer instance before creating a new one
        await _cleanupHanziWriter();
        await Future.delayed(const Duration(milliseconds: 200));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateCharacter();
        });
      }
    }
  }

  /// Navigate to previous card and update character display
  Future<void> _previousCard() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentCharIndex = 0;
        _hanziWriterError = null;
        _isLoading = true;
      });
      if (kIsWeb && hasChineseCharsInWord(_currentWord)) {
        // Clean up previous Hanzi Writer instance before creating a new one
        await _cleanupHanziWriter();
        await Future.delayed(const Duration(milliseconds: 200));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateCharacter();
        });
      }
    }
  }

  /// Move to next character within current word
  Future<void> _nextChar() async {
    final word = _currentWord;
    if (word.length > 1 && hasChineseCharsInWord(word) && _currentCharIndex < word.length - 1) {
      setState(() {
        _currentCharIndex++;
        _hanziWriterError = null;
        _isLoading = true;
      });
      if (kIsWeb) {
        await _cleanupHanziWriter();
        await Future.delayed(const Duration(milliseconds: 200));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateCharacter();
        });
      }
    }
  }

  /// Move to previous character within current word
  Future<void> _previousChar() async {
    final word = _currentWord;
    if (word.length > 1 && hasChineseCharsInWord(word) && _currentCharIndex > 0) {
      setState(() {
        _currentCharIndex--;
        _hanziWriterError = null;
        _isLoading = true;
      });
      if (kIsWeb) {
        await _cleanupHanziWriter();
        await Future.delayed(const Duration(milliseconds: 200));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateCharacter();
        });
      }
    }
  }

  /// Clean up Hanzi Writer instance and reset container styles to prevent stale references
  Future<void> _cleanupHanziWriter() async {
    if (_hanziWriterInstance != null) {
      try {
        _hanziWriterInstance.callMethod('dispose', []);
      } catch (_) {}
      _hanziWriterInstance = null;
    }
    // Reset container styles before removing canvas to prevent stale references
    _container.style.width = '';
    _container.style.height = '';
    _container.style.display = '';
    // Clear all children from the container (removes the canvas)
    _container.innerHtml = '';
  }

  @override
  void dispose() {
    // Ensure container styles are reset on final disposal
    if (kIsWeb) {
      _container.style.removeProperty('width');
      _container.style.removeProperty('height');
      _container.style.removeProperty('display');
    }
    _cleanupHanziWriter();
    super.dispose();
  }

  /// Build Hanzi Writer area using HtmlElementView with dynamic viewType
  Widget _buildHanziWriterArea() {
    if (!kIsWeb) {
      return const Text('Hanzi Writer is only available on web');
    }
    
    return SizedBox(
      width: 280,
      height: 350,
      child: HtmlElementView(
        viewType: _viewType,
      ),
    );
  }

  /// Build mobile fallback when Hanzi Writer is not available
  Widget _buildMobileFallback(String word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.animation,
          size: 120,
          color: Colors.teal,
        ),
        const SizedBox(height: 24),
        Text(
          'Stroke order animation is only available on web.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          word,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = _currentWord;
    final hasChineseCharsInWordValue = hasChineseCharsInWord(word);
    final currentChar = _currentCharacter;
    
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stroke Order Study'),
          backgroundColor: Colors.teal,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // Card navigation progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.cards.length,
              backgroundColor: Colors.teal.shade50,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            
            // Hanzi Writer rendering area (for web) or fallback for mobile
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: Center(
                  child: kIsWeb && hasChineseCharsInWordValue
                      ? _isLoading
                          ? const CircularProgressIndicator()
                          : _hanziWriterError != null
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Colors.red.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _hanziWriterError!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _hanziWriterError = null;
                                            _isLoading = true;
                                          });
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (mounted) _animateCharacter();
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildHanziWriterArea()
                      : hasChineseCharsInWordValue && !kIsWeb
                          ? _buildMobileFallback(word)
                          : const Text(
                              'No Chinese characters found in this deck.\nStroke order is only available for Chinese text.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                ),
              ),
            ),
            
            // Info panel below the stroke animation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Character indicator for multi-character words with Chinese chars
                    if (word.length > 1 && hasChineseCharsInWordValue) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentCharIndex > 0 ? _previousChar : null,
                            icon: const Icon(Icons.chevron_left),
                            color: Colors.teal,
                          ),
                          Text(
                            'Char ${_currentCharIndex + 1} of ${word.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_currentCharIndex < word.length - 1)
                            IconButton(
                              onPressed: _nextChar,
                              icon: const Icon(Icons.chevron_right),
                              color: Colors.teal,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Current character prominently displayed
                    Text(
                      currentChar.isNotEmpty ? currentChar : '',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Full word below for multi-character words
                    if (word.length > 1 && hasChineseCharsInWordValue) ...[
                      const SizedBox(height: 4),
                      Text(
                        word,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Definition/answer side
                    if (_currentIndex < widget.cards.length)
                      Text(
                        widget.cards[_currentIndex].sides.length > 1
                            ? widget.cards[_currentIndex].sides.skip(1).join(' | ')
                            : '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentIndex > 0 ? _previousCard : null,
                icon: const Icon(Icons.chevron_left),
                color: Colors.teal,
              ),
              Text(
                '${_currentIndex + 1}/${widget.cards.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: _currentIndex < widget.cards.length - 1 ? _nextCard : null,
                icon: const Icon(Icons.chevron_right),
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}