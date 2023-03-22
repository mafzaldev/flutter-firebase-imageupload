import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Image Upload',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isUploading = false;
  String imageUrl = '';

  pickImage(ImageSource imageSource) async {
    XFile? image = await ImagePicker().pickImage(source: imageSource);

    if (image == null) return;
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: image.path,
    );

    if (croppedImage == null) return;
    uploadImage(XFile(croppedImage.path));
  }

  uploadImage(XFile? image) async {
    String uniqueImageName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirectoryImage = referenceRoot.child('images');
    Reference referenceFileImage =
        referenceDirectoryImage.child(uniqueImageName);
    try {
      setState(() {
        isUploading = true;
      });
      await referenceFileImage.putFile(File(image!.path));
      var img = await referenceFileImage.getDownloadURL();
      setState(() {
        imageUrl = img;
        isUploading = false;
      });
      log(imageUrl);
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 50,
            ),
            imageUrl != ''
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      width: 400,
                      height: 400,
                      fit: BoxFit.contain,
                      imageUrl,
                    ),
                  )
                : Container(
                    height: 400,
                    width: 400,
                    margin: const EdgeInsets.all(5),
                    color: const Color.fromARGB(255, 226, 226, 226),
                    child: Center(
                        child: isUploading == false
                            ? const Text(
                                "Image will be displayed here",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            // ignore: dead_code
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    "Uploading Image...",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )),
                  ),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SourceButton(
                                    Icons.camera_alt, ImageSource.camera),
                                const SizedBox(
                                  width: 40,
                                ),
                                SourceButton(Icons.image, ImageSource.gallery)
                              ],
                            ),
                          );
                        });
                  },
                  child: const Text(
                    "Upload Image",
                    style: TextStyle(fontSize: 15),
                  )),
            )
          ],
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  InkWell SourceButton(
    IconData icon,
    ImageSource imageSource,
  ) {
    return InkWell(
      onTap: () {
        pickImage(imageSource);
        setState(() {
          imageUrl = '';
        });
        Navigator.pop(context);
      },
      child: Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)
            ]),
        child: Center(
          child: Icon(
            icon,
            size: 30,
          ),
        ),
      ),
    );
  }
}
