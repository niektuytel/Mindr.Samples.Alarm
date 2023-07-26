class FCMToken {
  final String token;
  final String userId;
  final String alarmId;
  final String? connectionId;

  FCMToken({
    required this.token,
    required this.userId,
    required this.alarmId,
    this.connectionId,
  });

  FCMToken.fromJson(Map<String, dynamic> json)
      : token = json['token'],
        userId = json['userId'],
        alarmId = json['alarmId'],
        connectionId = json['connectionId'];

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'alarmId': alarmId,
        'connectionId': connectionId,
      };
}
