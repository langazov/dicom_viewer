enum ImageFilterMode { none, bilateral, sharpen, bilateralSharpen }

extension ImageFilterModeLabel on ImageFilterMode {
  String get label {
    return switch (this) {
      ImageFilterMode.none => 'Off',
      ImageFilterMode.bilateral => 'Bilateral',
      ImageFilterMode.sharpen => 'Sharpen',
      ImageFilterMode.bilateralSharpen => 'Bilateral + sharpen',
    };
  }
}
