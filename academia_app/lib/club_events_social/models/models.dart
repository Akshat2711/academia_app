class Club {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String? bannerUrl;
  final List<String> coreMembers;
  final List<String> links;
  final String? clubPassword;
  final List<String> subscribers;
  final List<String> postIds;

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.bannerUrl,
    required this.coreMembers,
    required this.links,
    this.clubPassword,
    required this.subscribers,
    required this.postIds,
  });

  // Convert Object to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'club_id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'banner_url': bannerUrl,
      'core_members': coreMembers,
      'links': links,
      'club_password': clubPassword,
      'subscribers': subscribers,
      'posts': postIds,
    };
  }

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['club_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'],
      bannerUrl: json['banner_url'],
      coreMembers: List<String>.from(json['core_members'] ?? []),
      links: List<String>.from(json['links'] ?? []),
      clubPassword: json['club_password'],
      subscribers: List<String>.from(json['subscribers'] ?? []),
      postIds: List<String>.from(json['posts'] ?? []),
    );
  }
}

class Post {
  final String postId;
  final bool ownerIndividual;
  final String content;
  final String? idClub;
  final String? clubName; // Cached club name
  final String? clubIconUrl; // Cached club icon
  final String approved;
  final List<String> images;
  final List<String> likes;
  final int timestamp;
  final String? individualEmail;
  final int? expiry_time;

  Post({
    required this.postId,
    required this.ownerIndividual,
    required this.content,
    this.idClub,
    this.clubName,
    this.clubIconUrl,
    required this.approved,
    required this.images,
    required this.likes,
    required this.timestamp,
    this.individualEmail,
    this.expiry_time,
  });

  // Convert Object to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'owner_individual': ownerIndividual,
      'content': content,
      'id_club': idClub,
      'club_name': clubName,
      'club_icon_url': clubIconUrl,
      'approved': approved,
      'images': images,
      'likes': likes,
      'timestamp': timestamp,
      'individual_email': individualEmail,
      'expiry_time': expiry_time,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    // Helper function to convert to int if needed
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Post(
      postId: json['post_id'] ?? '',
      ownerIndividual: json['owner_individual'] ?? true,
      content: json['content'] ?? '',
      idClub: json['id_club'],
      clubName: json['club_name'],
      clubIconUrl: json['club_icon_url'],
      approved: json['approved'] ?? 'no',
      images: List<String>.from(json['images'] ?? []),
      likes: List<String>.from(json['likes'] ?? []),
      timestamp: toInt(json['timestamp']) ?? 0,
      individualEmail: json['individual_email'],
      expiry_time: toInt(json['expiry_time']),
    );
  }
}