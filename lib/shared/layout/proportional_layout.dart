const appLayoutBaselineWidth = 393.0;
const appLayoutMinScale = 0.92;
const appLayoutMaxScale = 1.18;

double proportionalLayoutScaleFor(double screenWidth) {
  return (screenWidth / appLayoutBaselineWidth)
      .clamp(appLayoutMinScale, appLayoutMaxScale)
      .toDouble();
}
