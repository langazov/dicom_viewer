enum ImageFilterMode {
  none,
  bilateral,
  sharpen,
  bilateralSharpen,
  anisotropicDiffusion,
  edgeAwareUpscale,
}

extension ImageFilterModeLabel on ImageFilterMode {
  String get label {
    return switch (this) {
      ImageFilterMode.none => 'Off',
      ImageFilterMode.bilateral => 'Bilateral',
      ImageFilterMode.sharpen => 'Sharpen',
      ImageFilterMode.bilateralSharpen => 'Bilateral + sharpen',
      ImageFilterMode.anisotropicDiffusion => 'Anisotropic diffusion',
      ImageFilterMode.edgeAwareUpscale => 'Edge-aware upscale',
    };
  }
}
