import 'package:flutter/painting.dart';

import '../../common/utils.dart';
import 'dimensions.dart';
import 'theme.dart';

BoardStyle getBoardStyle(BoardTheme theme) => switch (theme) {
  BoardTheme.classic => _getClassicBoardStyle(),
};

BoardStyle _getClassicBoardStyle() {
  const pieceForeColor = Color(0xFF000000);
  return BoardStyle(
    marginPaint: const Color(0xFF757575).toPaint(),
    marginTextStyle: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: Dimensions.marginFontSize,
      fontWeight: FontWeight.bold,
    ),
    lightCellPaint: const Color(0xFFFFFFFF).toPaint(),
    darkCellPaint: const Color(0xFFE0E0E0).toPaint(),
    drawLines: false,
    linePaint: Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke,
    mazePaint: const Color(0xFF000000).toPaint(),
    mazeForeColor: const Color(0xFFE0E0E0),
    pieceForeColor: pieceForeColor,
    pieceEdgePaint: Paint()
      ..color = pieceForeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = Dimensions.pieceStroke,
    pieceSymbolStyle: const TextStyle(
      color: pieceForeColor,
      fontSize: Dimensions.pieceFontSize,
      fontWeight: FontWeight.bold,
    ),
    deadPaint: const Color(0xFF757575).toPaint(),
    paralysedPaint: const Color(0xFFE4E4E4).toPaint(),
    selectableMarkPaint: const Color(0xFF757575).toPaint(),
    selectedMarkPaint: const Color(0xFFEA80FC).toPaint(),
    actionMarkPaint: const Color(0xFF757575).toPaint(),
    movedMarkPaint: const Color(0xFFBCAAA4).toPaint(),
    partyPaint: [
      const Color(0xFFF44336).toPaint(), // Ideology.red
      const Color(0xFF2196F3).toPaint(), // Ideology.blue
      const Color(0xFFFF9800).toPaint(), // Ideology.yellow
      const Color(0xFF4CAF50).toPaint(), // Ideology.green
    ],
  );
}
