class Estimate {
  final int? id;
  final String userId; // New field for Cloud Sync
  final String companyName;
  final String address;
  final String email;
  final String businessType;
  final String ownerName;
  final String phone;
  final double turnover;
  final String currency;
  final double estimatedFee;
  final double feePercentage;
  final String reportsData; // JSON string
  final String createdAt;

  Estimate({
    this.id,
    required this.userId,
    required this.companyName,
    required this.address,
    required this.email,
    required this.businessType,
    required this.ownerName,
    required this.phone,
    required this.turnover,
    required this.currency,
    required this.estimatedFee,
    required this.feePercentage,
    required this.reportsData,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'companyName': companyName,
      'address': address,
      'email': email,
      'businessType': businessType,
      'ownerName': ownerName,
      'phone': phone,
      'turnover': turnover,
      'currency': currency,
      'estimatedFee': estimatedFee,
      'feePercentage': feePercentage,
      'reportsData': reportsData,
      'createdAt': createdAt,
    };
  }

  // To match specific Firestore field names if different, but here we keep them same
  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id'); // ID is the document ID in Firestore
    return map;
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      userId: map['userId'] ?? '',
      companyName: map['companyName'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      businessType: map['businessType'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      turnover: (map['turnover'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'INR',
      estimatedFee: (map['estimatedFee'] as num?)?.toDouble() ?? 0.0,
      feePercentage: (map['feePercentage'] as num?)?.toDouble() ?? 1.0,
      reportsData: map['reportsData'] ?? '{}',
      createdAt: map['createdAt'] ?? '',
    );
  }
}
