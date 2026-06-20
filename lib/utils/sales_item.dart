class SalesItem {
  static int _uidCounter = 0;

  /// Stable local id - NOT sent to the server. Used only as a Flutter
  /// widget key so each item row keeps its own state correctly, even
  /// when other rows are added/removed.
  final int uid;

  int? stockItemId;
  String itemName;
  int? godownId;
  String? godownName;
  String batchNo;
  double availableQty;
  double billedQty;
  double rate;
  double supercashRate;
  int? unitId;
  String unitName;
  double cgstPercent;
  double sgstPercent;
  double igstPercent;
  double amount;
  double totalAmount;

  SalesItem({
    this.stockItemId,
    this.itemName = "",
    this.godownId,
    this.godownName,
    this.batchNo = "",
    this.availableQty = 0,
    this.billedQty = 0,
    this.rate = 0,
    this.supercashRate = 0,
    this.unitId,
    this.unitName = "",
    this.cgstPercent = 0,
    this.sgstPercent = 0,
    this.igstPercent = 0,
    this.amount = 0,
    this.totalAmount = 0,
  }) : uid = _uidCounter++;

  double get totalGstPercent => cgstPercent + sgstPercent + igstPercent;

  Map<String, dynamic> toJson() {
    return {
      "stock_item_id": stockItemId,
      "item_name": itemName,
      "godown_id": godownId,
      "batch_no": batchNo,
      "available_qty": availableQty,
      "billed_qty": billedQty,
      "rate": rate,
      "supercash_rate": supercashRate,
      "unit_id": unitId,
      "unit_name": unitName,
      "cgst_percent": cgstPercent,
      "sgst_percent": sgstPercent,
      "igst_percent": igstPercent,
      "amount": amount,
      "total_amount": totalAmount,
    };
  }
}