/// A location plants live in ("Living room", "Balcony"). Outdoor rooms feed
/// the weather nudges in M7.
class Room {
  const Room({
    required this.id,
    required this.name,
    this.isOutdoor = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final bool isOutdoor;
  final int sortOrder;

  Room copyWith({
    String? id,
    String? name,
    bool? isOutdoor,
    int? sortOrder,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
