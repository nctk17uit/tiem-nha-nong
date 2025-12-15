class Province {
  final int code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(code: json['code'], name: json['name']);
  }
}

class Ward {
  final int code;
  final String name;
  final int provinceCode;

  Ward({required this.code, required this.name, required this.provinceCode});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'],
      name: json['name'],
      provinceCode: json['province_code'],
    );
  }
}
