// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Crop Analyzer',
//       theme: ThemeData(primarySwatch: Colors.green),
//       home: CropAnalyzer(),
//     );
//   }
// }

// class CropAnalyzer extends StatefulWidget {
//   @override
//   _CropAnalyzerState createState() => _CropAnalyzerState();
// }

// class _CropAnalyzerState extends State<CropAnalyzer> {
//   File? _image;
//   String? _result;
//   bool _isLoading = false;

//   final picker = ImagePicker();

//   Future<void> _getImage(ImageSource source) async {
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         _result = null;
//       });
//     }
//   }

//   Future<void> _analyzeImage() async {
//     if (_image == null) {
//       setState(() => _result = 'Please select an image first');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _result = 'Analyzing image...';
//     });

//     try {
//       // Step 1: Crop vs Not Crop
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('https://crop-vs-not-crop-1.onrender.com/predict/'),
//       );
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'file',
//           _image!.path,
//         ), // <-- change 'image' to 'file'
//       );
//       final response = await request.send().timeout(
//         Duration(seconds: 30),
//         onTimeout: () {
//           throw TimeoutException('Server took too long to respond');
//         },
//       );
//       final cropCheckResponseBody = await response.stream.bytesToString();
//       log('Crop API response: $cropCheckResponseBody');
//       final cropCheckResult = jsonDecode(cropCheckResponseBody);
//       final cropLabel = cropCheckResult['prediction']?.toString().toLowerCase();

//       if (cropLabel == null) {
//         throw Exception('Crop API did not return a label');
//       }

//       if (cropLabel == 'not_crop') {
//         setState(() {
//           _result = 'Image does not contain a crop';
//           _isLoading = false;
//         });
//         return;
//       }

//       // Step 2: Disease Prediction
//       final diseaseRequest = http.MultipartRequest(
//         'POST',
//         Uri.parse('https://crop-disease-npbt.onrender.com/predict/'),
//       );
//       diseaseRequest.files.add(
//         await http.MultipartFile.fromPath(
//           'file',
//           _image!.path,
//         ), // <-- change 'image' to 'file'
//       );
//       final diseaseResponse = await diseaseRequest.send();
//       final diseaseResponseBody = await diseaseResponse.stream.bytesToString();

//       log('Disease API response: $diseaseResponseBody');
//       final diseaseResult = jsonDecode(diseaseResponseBody);
//       final diseaseLabel = diseaseResult['prediction']; // <-- fix here

//       setState(() {
//         _result = 'Crop: $cropLabel\nDisease: $diseaseLabel';
//         _isLoading = false;
//       });
//     } on SocketException catch (e) {
//       setState(() {
//         _result = 'Network error: Unable to reach server\n${e.message}';
//       });
//     } on TimeoutException catch (e) {
//       setState(() {
//         _result = 'Request timed out: Server took too long to respond';
//       });
//     } catch (e) {
//       setState(() {
//         _result = 'Error: ${e.toString()}';
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Crop Analyzer')),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _image != null
//                   ? Image.file(_image!, height: 200)
//                   : Text('No image selected.'),
//               SizedBox(height: 20),
//               if (_isLoading) CircularProgressIndicator(),
//               if (_result != null)
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Text(_result!, style: TextStyle(fontSize: 16)),
//                 ),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.photo),
//                 label: Text('Gallery'),
//                 onPressed: () => _getImage(ImageSource.gallery),
//               ),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.camera_alt),
//                 label: Text('Camera'),
//                 onPressed: () => _getImage(ImageSource.camera),
//               ),
//               ElevatedButton(child: Text('Analyze'), onPressed: _analyzeImage),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: CropAnalyzer(),
    );
  }
}

class CropAnalyzer extends StatefulWidget {
  const CropAnalyzer({super.key});

  @override
  _CropAnalyzerState createState() => _CropAnalyzerState();
}

class _CropAnalyzerState extends State<CropAnalyzer> {
  File? _image;
  String? _result;
  bool _isLoading = false;

  final picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      setState(() => _result = 'Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Analyzing image...';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://crop-vs-not-crop-1.onrender.com/predict/'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );
      final response = await request.send().timeout(Duration(seconds: 30));
      final cropCheckResponseBody = await response.stream.bytesToString();
      log('Crop API response: $cropCheckResponseBody');
      final cropCheckResult = jsonDecode(cropCheckResponseBody);
      final cropLabel = cropCheckResult['prediction']?.toString().toLowerCase();

      if (cropLabel == null) throw Exception('Crop API did not return a label');

      if (cropLabel == 'not_crop') {
        setState(() {
          _result = 'Image does not contain a crop';
          _isLoading = false;
        });
        return;
      }

      final diseaseRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://crop-disease-npbt.onrender.com/predict/'),
      );
      diseaseRequest.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );
      final diseaseResponse = await diseaseRequest.send();
      final diseaseResponseBody = await diseaseResponse.stream.bytesToString();

      log('Disease API response: $diseaseResponseBody');
      final diseaseResult = jsonDecode(diseaseResponseBody);
      final diseaseLabel = diseaseResult['prediction'];

      setState(() {
        _result = 'Crop: $cropLabel\nDisease: $diseaseLabel';
        _isLoading = false;
      });
    } on SocketException catch (e) {
      setState(() {
        _result = 'Network error: Unable to reach server\n${e.message}';
      });
    } on TimeoutException {
      setState(() {
        _result = 'Request timed out: Server took too long to respond';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Analyzer'),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 200),
                )
              else
                Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No image selected.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              SizedBox(height: 30),
              if (_isLoading)
                CircularProgressIndicator()
              else if (_result != null)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text('Gallery'),
                    onPressed: () => _getImage(ImageSource.gallery),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    onPressed: () => _getImage(ImageSource.camera),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.search),
                label: Text('Analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: _analyzeImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
