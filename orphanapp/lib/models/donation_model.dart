import '../core/date_utils.dart';

class DonationModel {
  final int? donationId;
  final String donorName;
  final String donationType;
  final double donationAmount;
  final String paymentMethod;
  final DateTime donationDate;
  final String? remarks;
  final String syncStatus;

  DonationModel({
    this.donationId,
    required this.donorName,
    required this.donationType,
    required this.donationAmount,
    required this.paymentMethod,
    required this.donationDate,
    this.remarks,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        if (donationId != null) 'donation_id': donationId,
        'donor_name': donorName,
        'donation_type': donationType,
        'donation_amount': donationAmount,
        'payment_method': paymentMethod,
        'donation_date': toIsoDate(donationDate),
        'remarks': remarks,
      };

  factory DonationModel.fromJson(Map<String, dynamic> json) => DonationModel(
        donationId: (json['donation_id'] as num?)?.toInt(),
        donorName: json['donor_name'] as String,
        donationType: json['donation_type'] as String,
        donationAmount: (json['donation_amount'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        donationDate: fromIsoDate(json['donation_date'] as String),
        remarks: json['remarks'] as String?,
        syncStatus: (json['sync_status'] as String?) ?? 'synced',
      );
}
