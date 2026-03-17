class TicketProduct {
  final String productId;
  final String name;
  final int ticketCount;
  final int priceKrw;

  const TicketProduct({
    required this.productId,
    required this.name,
    required this.ticketCount,
    this.priceKrw = 0,
  });

  String get label => '$ticketCount장';

  factory TicketProduct.fromJson(Map<String, dynamic> json) {
    return TicketProduct(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      ticketCount: json['ticket_count'] as int,
      priceKrw: json['price_krw'] as int? ?? 0,
    );
  }
}
