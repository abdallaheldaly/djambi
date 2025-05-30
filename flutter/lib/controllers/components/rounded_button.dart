import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../common/utils.dart';
import '../configs.dart';
import 'rounded_rect.dart';
import 'utils.dart';

class RoundedButton extends AdvancedButtonComponent {
  final String? text;
  final IconData? icon;
  final ButtonColorSchema colorSchema;
  final double fontSize;

  RoundedButton({
    this.text,
    this.icon,
    required super.size,
    super.position,
    required super.onReleased,
    this.colorSchema = Configs.primaryBtnColors,
    this.fontSize = Configs.defaultFontSize,
    super.anchor = Anchor.topLeft,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    defaultLabel = TextComponent(
      text: icon?.codePoint.convert(String.fromCharCode) ?? text,
      textRenderer: getTextRenderer(
          fontSize: fontSize,
          color: colorSchema.text,
          fontFamily: icon?.fontFamily,
      ),
    );
    defaultSkin = RoundedRectComponent(paint: colorSchema.natural.toPaint());
    hoverSkin = RoundedRectComponent(paint: colorSchema.hover.toPaint());
    downSkin = RoundedRectComponent(paint: colorSchema.down.toPaint());
    disabledSkin = RoundedRectComponent(paint: colorSchema.disabled.toPaint());
  }
}
