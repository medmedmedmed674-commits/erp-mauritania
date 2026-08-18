import 'package:flutter/material.dart';

/// A [Text] widget that forces LTR layout, used to display digits,
/// prices, phone numbers, and invoice IDs that would otherwise be
/// visually reversed inside an RTL Arabic parent context.
///
/// This is the simplest, most reliable fix for the "18000 → 000181"
/// rendering bug reported on Flutter web + RTL locales.
///
/// Implementation note: we wrap the [Text] in [Directionality] so
/// the BiDi algorithm forces the digits to render left-to-right even
/// when the surrounding text is Arabic RTL.
class LtrText extends StatelessWidget {
  const LtrText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = false,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    // Use Text.textDirection directly — it's a parameter on Text
    // and avoids the Directionality wrapper layout complications
    // that arise when Text is placed inside a Row.
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}
