class CartItem {
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  bool isSelected;

  CartItem({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.isSelected = false,
  });
}
