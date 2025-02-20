import 'package:taleem_app/common_imports.dart';
class SessionCircleContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const SessionCircleContainer({
    Key? key,
    required this.child,
    this.onTap,
    this.size = 200,
    this.color = Colors.blueAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Center(child: child),
      ),
    );
  }
}
