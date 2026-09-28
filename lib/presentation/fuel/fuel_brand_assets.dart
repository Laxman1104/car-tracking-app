abstract final class FuelBrandAssets {
  static String? forBrand(String brand) {
    return switch (brand.trim().toLowerCase()) {
      'petronas' => 'assets/fuel_brands/Petronas.png',
      'shell' => 'assets/fuel_brands/Shell.png',
      'petron' => 'assets/fuel_brands/Petron.png',
      'caltex' => 'assets/fuel_brands/cultex.png',
      'bhpetrol' => 'assets/fuel_brands/bhp.png',
      _ => null,
    };
  }
}
