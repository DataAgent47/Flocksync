import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<bool> uploadVerificationDocument({
     required String uid,
     required Uint8List fileBytes,
     required String fileName,
   }) async {
     try {

       final storage = Supabase.instance.client.storage.from('verification-documents');

       await storage.uploadBinary('$uid/$fileName', fileBytes);

       final url = storage.getPublicUrl('$uid/$fileName');

       await _firestore.collection('users').doc(uid).set({
         'owner_verification': {
           'status': 'pending',
           'file_url': url,
           'updated_at': FieldValue.serverTimestamp(),
         }
       }, SetOptions(merge: true));

       return true;
     } catch (e) {
       return false;
     }
   }
}