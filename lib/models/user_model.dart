import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePictureUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      // Note: 'uid' is typically the document ID, so it's not stored as a field within the document itself.
    };
  }
}
