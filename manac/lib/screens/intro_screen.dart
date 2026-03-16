import 'package:flutter/material.dart';
import '../services/app_language_service.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const IntroScreen({super.key, required this.onComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  void _initPages() {
    final lang = AppLanguageService.instance;
    _pages.addAll([
      IntroPage(
        title: lang.getText('Stock Management'),
        description: lang.getText('Easily manage your equipment inventory with real-time tracking.'),
        icon: Icons.inventory_2,
        color: Colors.blue,
        illustration: '📦',
      ),
      IntroPage(
        title: lang.getText('Borrow & Return'),
        description: lang.getText('Quickly record equipment borrow and returns with Flash mode.'),
        icon: Icons.swap_horiz,
        color: Colors.green,
        illustration: '🔄',
      ),
      IntroPage(
        title: lang.getText('Synchronization'),
        description: lang.getText('Work online or offline with automatic synchronization.'),
        icon: Icons.sync,
        color: Colors.orange,
        illustration: '☁️',
      ),
      IntroPage(
        title: lang.getText('Alerts & Notifications'),
        description: lang.getText('Receive alerts for pending returns and low stock.'),
        icon: Icons.notifications_active,
        color: Colors.red,
        illustration: '🔔',
      ),
      IntroPage(
        title: lang.getText('Reports & Exports'),
        description: lang.getText('Generate PDF reports and export your data easily.'),
        icon: Icons.description,
        color: Colors.purple,
        illustration: '📊',
      ),
    ]);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService.instance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    _currentPage == _pages.length - 1 ? '' : lang.getText('Skip'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(lang.getText('Previous')),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? lang.getText('Get Started')
                            : lang.getText('Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(IntroPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container - BIG
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                page.illustration,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class IntroPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String illustration;

  IntroPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustration,
  });
}
