part of fsextensions;

extension RetrieveColor on String {
  Color getColorFromHex() {
    return HexColor(this);
  }

  Color getFontColorFromHexBackground() {
    return HexColor.textColorForBackground(HexColor(this));
  }
}
