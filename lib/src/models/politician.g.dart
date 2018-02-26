// GENERATED CODE - DO NOT MODIFY BY HAND

part of blood_money.src.models.politician;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Politician extends _Politician {
  @override
  String id;

  @override
  String name;

  @override
  String imageUrl;

  @override
  String position;

  @override
  String state;

  @override
  String bio;

  @override
  String tweetId;

  @override
  String party;

  @override
  String phone;

  @override
  String email;

  @override
  String website;

  @override
  String twitter;

  @override
  num moneyFromNra;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Politician(
      {this.id,
      this.name,
      this.imageUrl,
      this.position,
      this.state,
      this.bio,
      this.tweetId,
      this.party,
      this.phone,
      this.email,
      this.website,
      this.twitter,
      this.moneyFromNra,
      this.createdAt,
      this.updatedAt});

  factory Politician.fromJson(Map data) {
    return new Politician(
        id: data['id'],
        name: data['name'],
        imageUrl: data['image_url'],
        position: data['position'],
        state: data['state'],
        bio: data['bio'],
        tweetId: data['tweet_id'],
        party: data['party'],
        phone: data['phone'],
        email: data['email'],
        website: data['website'],
        twitter: data['twitter'],
        moneyFromNra: data['money_from_nra'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'position': position,
        'state': state,
        'bio': bio,
        'tweet_id': tweetId,
        'party': party,
        'phone': phone,
        'email': email,
        'website': website,
        'twitter': twitter,
        'money_from_nra': moneyFromNra,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Politician parse(Map map) => new Politician.fromJson(map);

  Politician clone() {
    return new Politician.fromJson(toJson());
  }
}
