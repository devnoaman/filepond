// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:filepond/src/utils/dashed_border_painter.dart';
import 'package:flutter/material.dart';

class DashedContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  const DashedContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
  });
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Theme.of(context).primaryColor,
        strokeWidth: 2,
        dashLength: 6,
        gapLength: 3,
      ),
      child: Container(
        height:height?? 100,
        width: width,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
