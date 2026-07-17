import 'package:uuid/uuid.dart';

class PurchaseItem {
  final String uid = const Uuid().v4();

  int? stockItemId;
  String itemName;
  int? unitId;
  String unitName;

  int? godownId;
  String? godownName;
  String batchNo;

  DateTime? mfgDate;
  DateTime? expiryDate;

  double availableQty;
  double billedQty;
  double rate;

  double cgstPercent;
  double sgstPercent;
  double igstPercent;

  double amount;
  double totalAmount;

  PurchaseItem({
    this.stockItemId,
    this.itemName = "",
    this.unitId,
    this.unitName = "",
    this.godownId,
    this.godownName,
    this.batchNo = "",
    this.mfgDate,
    this.expiryDate,
    this.availableQty = 0,
    this.billedQty = 0,
    this.rate = 0,
    this.cgstPercent = 0,
    this.sgstPercent = 0,
    this.igstPercent = 0,
    this.amount = 0,
    this.totalAmount = 0,
  });

  Map<String, dynamic> toJson() => {
        "stock_item_id": stockItemId,
        "item_name": itemName,
        "unit_id": unitId,
        "unit_name": unitName,
        "godown_id": godownId,
        "godown_name": godownName,
        "batch_no": batchNo,
        "mfg_date": mfgDate?.toIso8601String().split("T").first,
        "expiry_date": expiryDate?.toIso8601String().split("T").first,
        "available_qty": availableQty,
        "billed_qty": billedQty,
        "rate": rate,
        "cgst_percent": cgstPercent,
        "sgst_percent": sgstPercent,
        "igst_percent": igstPercent,
        "amount": amount,
        "total_amount": totalAmount,
      };
}