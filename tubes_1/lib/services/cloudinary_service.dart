// services/cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = 'dr7m61fk6'; // Your cloud name
  static const String _apiKey = '121279244657396'; // Your API key
  static const String _apiSecret =
      'FEyx_VJPyt3BL-h5UAX95hUz0PU'; // Your API secret
  static const String _uploadPreset = 'dapoerkita_preset'; // Upload preset name

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Pick image error: $e');
      return null;
    }
  }

  // Upload image to Cloudinary
  Future<CloudinaryResponse?> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      var request = http.MultipartRequest('POST', url);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add parameters
      request.fields['upload_preset'] = _uploadPreset;
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      // Add timestamp for security
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      request.fields['timestamp'] = timestamp;

      // Generate signature
      final signature = _generateSignature(timestamp, folder, publicId);
      request.fields['signature'] = signature;
      request.fields['api_key'] = _apiKey;

      print('Uploading to Cloudinary...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Cloudinary response status: ${response.statusCode}');
      print('Cloudinary response body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return CloudinaryResponse.fromJson(data);
      } else {
        print(
          'Cloudinary upload error: ${response.statusCode} - $responseBody',
        );
        return null;
      }
    } catch (e) {
      print('Upload image error: $e');
      return null;
    }
  }

  // Alternative upload method without signature (using unsigned upload)
  Future<String?> uploadImageSimple({
    required File imageFile,
    String? folder,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      var request = http.MultipartRequest('POST', url);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add basic parameters
      request.fields['upload_preset'] = _uploadPreset;
      if (folder != null) request.fields['folder'] = folder;

      print('Uploading image to Cloudinary...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['secure_url'] as String?;
      } else {
        print('Upload failed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // Generate signature for security
  String _generateSignature(
    String timestamp,
    String? folder,
    String? publicId,
  ) {
    var params = <String, String>{
      'timestamp': timestamp,
      'upload_preset': _uploadPreset,
    };

    if (folder != null) params['folder'] = folder;
    if (publicId != null) params['public_id'] = publicId;

    // Sort parameters
    final sortedParams =
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Create string to sign
    final stringToSign =
        sortedParams.map((e) => '${e.key}=${e.value}').join('&') + _apiSecret;

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  // Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Generate signature for delete
      final stringToSign =
          'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final bytes = utf8.encode(stringToSign);
      final signature = sha1.convert(bytes).toString();

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Delete image error: $e');
      return false;
    }
  }

  // Generate optimized URL for different sizes
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    var transformation = 'q_$quality,f_$format';

    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';
    transformation += ',c_fill'; // Crop to fill

    return 'https://res.cloudinary.com/$_cloudName/image/upload/$transformation/$publicId';
  }

  // Get thumbnail URL
  String getThumbnailUrl(String imageUrl, {int size = 150}) {
    if (imageUrl.contains('cloudinary.com')) {
      // Extract public_id from Cloudinary URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        final publicId = pathSegments.sublist(uploadIndex + 1).join('/');
        return getOptimizedUrl(publicId, width: size, height: size);
      }
    }
    return imageUrl; // Return original if not a Cloudinary URL
  }
}

// Model for Cloudinary response
class CloudinaryResponse {
  final String publicId;
  final String url;
  final String secureUrl;
  final int width;
  final int height;
  final String format;
  final int bytes;

  CloudinaryResponse({
    required this.publicId,
    required this.url,
    required this.secureUrl,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });

  factory CloudinaryResponse.fromJson(Map<String, dynamic> json) {
    return CloudinaryResponse(
      publicId: json['public_id'] ?? '',
      url: json['url'] ?? '',
      secureUrl: json['secure_url'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      format: json['format'] ?? '',
      bytes: json['bytes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'url': url,
      'secure_url': secureUrl,
      'width': width,
      'height': height,
      'format': format,
      'bytes': bytes,
    };
  }
}

// Helper class for error handling
class CloudinaryException implements Exception {
  final String message;
  final int? statusCode;

  CloudinaryException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'CloudinaryException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
