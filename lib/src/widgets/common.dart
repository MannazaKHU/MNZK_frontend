import 'package:flutter/material.dart';
import '../theme.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

class JakuButton extends StatefulWidget {
  const JakuButton(
    this.label, {
    super.key,
    this.onPressed,
    this.secondary = false,
    this.small = false,
    this.arrow = false,
    this.icon,
    this.accent = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool small;
  final bool arrow;
  final IconData? icon;
  final bool accent;

  @override
  State<JakuButton> createState() => _JakuButtonState();
}

class _JakuButtonState extends State<JakuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _setHovered(bool value) {
    if (!_enabled || _hovered == value) return;
    setState(() => _hovered = value);
    if (value &&
        !widget.secondary &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shine.forward(from: 0);
    }
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final style = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: widget.small ? 18 : 26,
          vertical: widget.small ? 15 : 20,
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Noto Sans KR',
          fontSize: widget.small ? 14 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? c.ink.withValues(alpha: .2)
            : widget.accent
            ? JakuColors.green
            : widget.secondary
            ? c.card
            : c.ink,
      ),
      foregroundColor: WidgetStatePropertyAll(
        widget.accent
            ? JakuColors.stickerInk
            : widget.secondary
            ? c.ink
            : c.background,
      ),
      side: WidgetStatePropertyAll(
        widget.accent
            ? const BorderSide(color: JakuColors.stickerInk, width: 2.5)
            : widget.secondary
            ? BorderSide(color: _hovered ? c.ink : c.line, width: 1.5)
            : BorderSide.none,
      ),
      elevation: WidgetStateProperty.resolveWith(
        (states) => widget.secondary || states.contains(WidgetState.disabled)
            ? 0
            : _pressed
            ? widget.accent
                  ? 1
                  : 1
            : _hovered
            ? widget.accent
                  ? 7
                  : 5
            : widget.accent
            ? 4
            : 2,
      ),
      shadowColor: WidgetStatePropertyAll(c.ink.withValues(alpha: .2)),
    );
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedSlide(
          duration: duration,
          curve: Curves.easeOutCubic,
          offset: _pressed || !_hovered ? Offset.zero : const Offset(0, -.04),
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: _pressed ? .97 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  ElevatedButton(
                    onPressed: widget.onPressed,
                    style: style,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 17),
                          const SizedBox(width: 8),
                        ],
                        Text(widget.label),
                        if (widget.arrow) ...[
                          const SizedBox(width: 10),
                          AnimatedSlide(
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            offset: _hovered
                                ? const Offset(.17, 0)
                                : Offset.zero,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!widget.secondary && !widget.accent && _enabled)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) => FractionalTranslation(
                            translation: Offset(-1.4 + _shine.value * 3.6, 0),
                            child: Transform(
                              transform: Matrix4.skewX(-.3),
                              alignment: Alignment.center,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 42,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: .34),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: c.soft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.strong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JakuTag extends StatelessWidget {
  const JakuTag(this.text, {super.key, this.negative = false});
  final String text;
  final bool negative;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: negative ? c.sun.withValues(alpha: .13) : c.soft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: negative ? c.sun : c.strong,
        ),
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: -2,
        right: -2,
        bottom: 2,
        height: (style.fontSize ?? 40) * .36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: JakuColors.green.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
      Text(text, style: style),
    ],
  );
}

class PanelHeading extends StatelessWidget {
  const PanelHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.highlight = '',
    this.after = '',
    this.description,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String highlight;
  final String after;
  final String? description;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final size = MediaQuery.sizeOf(context).width < 640 ? 27.0 : 38.0;
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: -.9,
      color: c.ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trailing == null)
          Eyebrow(eyebrow)
        else
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [Eyebrow(eyebrow), trailing!],
          ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: title),
              if (highlight.isNotEmpty)
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: HighlightedText(highlight, style: style),
                ),
              TextSpan(text: after),
            ],
          ),
          style: style,
        ),
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(
            description!,
            style: TextStyle(fontSize: 16, height: 1.7, color: c.body),
          ),
        ],
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.private = false,
  });
  final String text;
  final IconData icon;
  final bool private;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: private ? c.soft : c.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: JakuColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: JakuColors.stickerInk, width: 2),
            ),
            child: Icon(icon, size: 17, color: JakuColors.stickerInk),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.65,
                color: private ? c.ink : c.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelFooter extends StatelessWidget {
  const PanelFooter({super.key, this.hint = '', required this.button});
  final String hint;
  final Widget button;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final text = Text(
          hint,
          style: TextStyle(fontSize: 13, color: JakuColors.of(context).body),
        );
        if (constraints.maxWidth < 450) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hint.isNotEmpty) ...[text, const SizedBox(height: 16)],
              Align(alignment: Alignment.centerRight, child: button),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    ),
  );
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return IconButton.outlined(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        backgroundColor: c.card,
        foregroundColor: c.ink,
        side: BorderSide(color: c.line, width: 1.5),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 32,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .12 : .04),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
