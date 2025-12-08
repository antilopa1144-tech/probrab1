import 'package:flutter/material.dart';
import '../../../core/services/haptic_feedback_service.dart';

/// Карточка с поддержкой swipe actions (удалить, поделиться, дублировать).
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onDuplicate;
  final Color? backgroundColor;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onDelete,
    this.onShare,
    this.onDuplicate,
    this.backgroundColor,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  double _dragOffset = 0.0;
  bool _isSwiped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!_isSwiped) {
          setState(() {
            _dragOffset += details.delta.dx;
            _dragOffset = _dragOffset.clamp(-200.0, 200.0);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset.abs() > 100) {
          HapticFeedbackService.medium();
          setState(() {
            _isSwiped = true;
          });
        } else {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      },
      child: Stack(
        children: [
          // Фоновые действия
          if (_dragOffset < -50)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.errorContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onDelete != null)
                      _SwipeAction(
                        icon: Icons.delete_outline,
                        color: theme.colorScheme.error,
                        onTap: () {
                          HapticFeedbackService.error();
                          widget.onDelete?.call();
                          setState(() {
                            _dragOffset = 0.0;
                            _isSwiped = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
            )
          else if (_dragOffset > 50)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.onShare != null)
                      _SwipeAction(
                        icon: Icons.share_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () {
                          HapticFeedbackService.success();
                          widget.onShare?.call();
                          setState(() {
                            _dragOffset = 0.0;
                            _isSwiped = false;
                          });
                        },
                      ),
                    if (widget.onDuplicate != null)
                      _SwipeAction(
                        icon: Icons.copy_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () {
                          HapticFeedbackService.success();
                          widget.onDuplicate?.call();
                          setState(() {
                            _dragOffset = 0.0;
                            _isSwiped = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Карточка
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: _dragOffset,
            right: -_dragOffset,
            child: Card(
              key: _cardKey,
              color: widget.backgroundColor,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Действие при свайпе.
class _SwipeAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SwipeAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(16),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
