import 'package:flutter/material.dart';

class DraggableBottomPanel extends StatefulWidget {
  final Widget child;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final double maxWidth;
  final EdgeInsets margin;

  const DraggableBottomPanel({
    super.key,
    required this.child,
    this.initialFraction = 0.34,
    this.minFraction = 0.24,
    this.maxFraction = 0.72,
    this.maxWidth = 620,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  @override
  State<DraggableBottomPanel> createState() => _DraggableBottomPanelState();
}

class _DraggableBottomPanelState extends State<DraggableBottomPanel> {
  late double _fraction;

  @override
  void initState() {
    super.initState();
    _fraction = widget.initialFraction;
  }

  void _resize(DragUpdateDetails details, double availableHeight) {
    setState(() {
      _fraction = (_fraction - details.delta.dy / availableHeight)
          .clamp(widget.minFraction, widget.maxFraction)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight * _fraction;

        return Positioned(
          left: widget.margin.left,
          right: widget.margin.right,
          bottom: widget.margin.bottom,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                height: height,
                child: Stack(
                  children: [
                    _PanelShadow(child: widget.child),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 120,
                        height: 38,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) =>
                              _resize(details, constraints.maxHeight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ResizableSideDrawer extends StatefulWidget {
  final Widget child;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final double maxWidth;
  final EdgeInsets margin;

  const ResizableSideDrawer({
    super.key,
    required this.child,
    this.initialFraction = 0.38,
    this.minFraction = 0.30,
    this.maxFraction = 0.58,
    this.maxWidth = 560,
    this.margin = const EdgeInsets.all(12),
  });

  @override
  State<ResizableSideDrawer> createState() => _ResizableSideDrawerState();
}

class _ResizableSideDrawerState extends State<ResizableSideDrawer> {
  late double _fraction;

  @override
  void initState() {
    super.initState();
    _fraction = widget.initialFraction;
  }

  void _resize(DragUpdateDetails details, double availableWidth) {
    setState(() {
      _fraction = (_fraction - details.delta.dx / availableWidth)
          .clamp(widget.minFraction, widget.maxFraction)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * _fraction)
            .clamp(280.0, widget.maxWidth)
            .toDouble();

        return Positioned(
          top: widget.margin.top,
          right: widget.margin.right,
          bottom: widget.margin.bottom,
          width: width,
          child: Stack(
            children: [
              _PanelShadow(child: widget.child),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) =>
                      _resize(details, constraints.maxWidth),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FloatingWorkspacePanel extends StatefulWidget {
  final Widget child;
  final Alignment alignment;
  final double initialHeightFraction;
  final double minHeightFraction;
  final double maxHeightFraction;
  final double maxWidth;
  final EdgeInsets margin;

  const FloatingWorkspacePanel({
    super.key,
    required this.child,
    this.alignment = Alignment.topRight,
    this.initialHeightFraction = 0.34,
    this.minHeightFraction = 0.24,
    this.maxHeightFraction = 0.62,
    this.maxWidth = 420,
    this.margin = const EdgeInsets.fromLTRB(12, 88, 12, 12),
  });

  @override
  State<FloatingWorkspacePanel> createState() => _FloatingWorkspacePanelState();
}

class _FloatingWorkspacePanelState extends State<FloatingWorkspacePanel> {
  late double _heightFraction;

  @override
  void initState() {
    super.initState();
    _heightFraction = widget.initialHeightFraction;
  }

  void _resize(DragUpdateDetails details, double availableHeight) {
    setState(() {
      _heightFraction = (_heightFraction + details.delta.dy / availableHeight)
          .clamp(widget.minHeightFraction, widget.maxHeightFraction)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final centered = widget.alignment.x == 0;
        final alignRight = widget.alignment.x > 0;
        final height = constraints.maxHeight * _heightFraction;
        final panel = SizedBox(
          height: height,
          width: compact ? double.infinity : widget.maxWidth,
          child: Stack(
            children: [
              _PanelShadow(child: widget.child),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 120,
                  height: 38,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) =>
                        _resize(details, constraints.maxHeight),
                  ),
                ),
              ),
            ],
          ),
        );

        return Positioned(
          left: compact || centered || !alignRight ? widget.margin.left : null,
          right: compact || centered || alignRight ? widget.margin.right : null,
          top: widget.margin.top,
          child: Align(
            alignment: widget.alignment,
            child: panel,
          ),
        );
      },
    );
  }
}

class _PanelShadow extends StatelessWidget {
  final Widget child;

  const _PanelShadow({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}
