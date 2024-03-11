import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VgImagePicker extends StatefulWidget {
  void Function(File) onImagePick;

  VgImagePicker({
    super.key,
    required this.onImagePick,
  });

  @override
  State<VgImagePicker> createState() {
    return _VgImagePiackerState();
  }
}

class _VgImagePiackerState extends State<VgImagePicker> {
  File? _pickedImgFile;

  void _pickImage() async {
    final pickedImg = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 150,
    );

    if (pickedImg == null) {
      return;
    }

    setState(() {
      _pickedImgFile = File(pickedImg.path);
    });

    widget.onImagePick(_pickedImgFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          foregroundImage:
              _pickedImgFile != null ? FileImage(_pickedImgFile!) : null,
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: Text(
            'Add Image',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        )
      ],
    );
  }
}
