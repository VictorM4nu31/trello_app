// lib/models/user_profile.dart

class UserProfile {
  final String uid;
  final String name;
  final String surname;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.surname,
    this.photoUrl,
  });

  // Método para convertir un documento Firestore a UserProfile
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  // Método para convertir UserProfile a un mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'photoUrl': photoUrl,
    };
  }
}
