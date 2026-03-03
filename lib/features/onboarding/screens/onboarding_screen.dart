import 'package:bible_decision_simulator/core/i18n.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.text,
    required this.onFinish,
  });

  final UiText text;
  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPageOrFinish(int totalPages) {
    if (_currentPage >= totalPages - 1) {
      widget.onFinish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _GuideSlide(
        icon: Icons.menu_book_rounded,
        title: widget.text.onboardingTitle1,
        body: widget.text.onboardingBody1,
      ),
      _GuideSlide(
        icon: Icons.auto_graph_rounded,
        title: widget.text.onboardingTitle2,
        body: widget.text.onboardingBody2,
      ),
      _GuideSlide(
        icon: Icons.local_fire_department_rounded,
        title: widget.text.onboardingTitle3,
        body: widget.text.onboardingBody3,
      ),
    ];
    final colorScheme = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.55),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onFinish,
                    child: Text(widget.text.onboardingSkip),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return _SlideView(slide: slide);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 26 : 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _currentPage == index
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _nextPageOrFinish(slides.length),
                    icon: Icon(isLastPage ? Icons.check : Icons.arrow_forward),
                    label: Text(
                      isLastPage
                          ? widget.text.onboardingStart
                          : widget.text.onboardingNext,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _GuideSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          color: colorScheme.surface.withValues(alpha: 0.88),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    slide.icon,
                    size: 34,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideSlide {
  const _GuideSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
