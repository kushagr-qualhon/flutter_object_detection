import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLOv8 Object Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<dynamic>? _recognitions;

  @override
  void initState() {
    super.initState();

    // Initialize camera controller
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();

    // Load the YOLOv8 model
    loadModel();
  }

  Future<void> loadModel() async {
  String? res = await Tflite.loadModel(
    model: "assets/yolov8n.tflite",
    labels: "assets/labels.txt"
  );
  if (res != null) {
    print("Model loaded successfully: $res");
  } else {
    print("Failed to load model");
  }
}

  Future<void> runModelOnFrame(CameraImage img) async {
  print("Running model on frame...");
  var recognitions = await Tflite.runModelOnFrame(
    bytesList: img.planes.map((plane) {
      return plane.bytes;
    }).toList(),
    imageHeight: img.height,
    imageWidth: img.width,
    numResults: 8400, // Adjust if necessary
    threshold: 0.5,
  );

  print("Raw recognitions: $recognitions");

  List<dynamic> results = [];
  if (recognitions != null) {
    for (var i = 0; i < recognitions.length; i += 6) {
      double confidence = recognitions[i + 4];
      if (confidence > 0.5) {
        double x = recognitions[i];
        double y = recognitions[i + 1];
        double w = recognitions[i + 2];
        double h = recognitions[i + 3];
        int detectedClass = recognitions[i + 5].toInt();

        print("Detection: Class=$detectedClass, x=$x, y=$y, w=$w, h=$h, confidence=$confidence");

        results.add({
          'rect': {
            'x': x,
            'y': y,
            'w': w,
            'h': h,
          },
          'confidenceInClass': confidence,
          'detectedClass': detectedClass,
        });
      }
    }
  } else {
    print("No recognitions found");
  }

  setState(() {
    _recognitions = results;
    print("Updated _recognitions: $_recognitions");
  });
}

  @override
  void dispose() {
    _controller.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YOLOv8 Object Detection'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            print("Camera preview ready. Rendering bounding boxes...");

            return CameraPreview(
              _controller,
              child: Stack(
                children: _recognitions != null
                    ? _recognitions!.map((recog) {
                        print("Rendering box: ${recog['rect']}");

                        return Positioned(
                          left: recog['rect']['x'] *
                              MediaQuery.of(context).size.width,
                          top: recog['rect']['y'] *
                              MediaQuery.of(context).size.height,
                          width: recog['rect']['w'] *
                              MediaQuery.of(context).size.width,
                          height: recog['rect']['h'] *
                              MediaQuery.of(context).size.height,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 3,
                              ),
                            ),
                            child: Text(
                              "${recog['detectedClass']} ${(recog['confidenceInClass'] * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    : [],
              ),
            );
          } else {
            print("Camera preview not ready.");
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
