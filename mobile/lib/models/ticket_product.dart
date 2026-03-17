class TicketProduct {
  final String productId;
  final String label;
  final int ticketCount;

  const TicketProduct({
    required this.productId,
    required this.label,
    required this.ticketCount,
  });
}

const ticketProducts = [
  TicketProduct(productId: 'saju_ticket_3', label: '3장', ticketCount: 3),
  TicketProduct(productId: 'saju_ticket_10', label: '10장', ticketCount: 10),
  TicketProduct(productId: 'saju_ticket_30', label: '30장', ticketCount: 30),
];
