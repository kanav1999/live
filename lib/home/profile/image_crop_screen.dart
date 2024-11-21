import 'dart:io';
import 'dart:ui' as ui;

import 'package:crop/crop.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../helpers/quick_help.dart';

// ignore: must_be_immutable
class ImageCropScreen extends StatefulWidget {
  static const String route = '/image/crop';

  static const double aspectRatioSquare = 1;
  static const double aspectRatioProfile = 4/6;

  double? aspectRatio;
  dynamic pathOrBytes;

  ImageCropScreen({Key? key, this.pathOrBytes, this.aspectRatio}) : super(key: key);

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {

  double _rotation = 0;
  BoxShape shape = BoxShape.rectangle;
  late CropController controller;

  @override
  void initState() {
    controller = CropController(aspectRatio: widget.aspectRatio != null ? widget.aspectRatio! : 4/6);
    super.initState();
  }
  void _cropImage() async {
    QuickHelp.showLoadingDialog(context);

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await controller.crop(pixelRatio: pixelRatio);

    final result = await _saveCroppedImage(cropped);
    if (result != null) {
      QuickHelp.hideLoadingDialog(context);

      if (QuickHelp.isWebPlatform()) {

        QuickHelp.goBackToPreviousPage(context, result: result);
      } else {
        final tempDir = await getTemporaryDirectory();
        File file = await File('${tempDir.path}/image.png').create();
        file.writeAsBytesSync(result);

        QuickHelp.goBackToPreviousPage(context, result: file.path);

        print("Cropped: ${file.path}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolBar(
      title: 'page_title.crop_photo_title'.tr(),
      centerTitle: true,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                child: Crop(
                  onChanged: (decomposition) {
                    if (_rotation != decomposition.rotation) {
                      setState(() {
                        _rotation =
                            ((decomposition.rotation + 180) % 360) - 180;
                      });
                    }
                  },
                  controller: controller,
                  shape: shape,
                  child: QuickHelp.isWebPlatform()
                      ? Image.network(
                          widget.pathOrBytes!,
                          fit: BoxFit.cover,
                        )
                      : QuickHelp.isIOSPlatform()
                          ? Image.asset(
                              widget.pathOrBytes,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.pathOrBytes),
                              fit: BoxFit.cover,
                            ),
                  // Uncomment if you want to put something in the photo
                  foreground: Visibility(
                    visible: Setup.useWatermarkInPhotos,
                    child: IgnorePointer(
                    child: Container(
                      margin: EdgeInsets.all(5),
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        'assets/images/ic_logo.png',
                        width: 120,
                        height: 120,),
                    ),
                ),
                  ),
                  helper: shape == BoxShape.rectangle
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.rotate_right),
                  //tooltip: 'Undo',
                  onPressed: () {
                    controller.rotation =
                        _rotation >= -180 ? _rotation + 45 : 0;
                    controller.scale = 1;
                    controller.offset = Offset.zero;
                    setState(() {
                      _rotation = _rotation >= -180 ? _rotation + 45 : 0;
                    });
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: theme.sliderTheme.copyWith(
                        //trackShape: CenteredRectangularSliderTrackShape(),
                        ),
                    child: Slider(
                      divisions: 360,
                      value: _rotation,
                      min: -180,
                      max: 180,
                      label: '$_rotation°',
                      onChanged: (n) {
                        setState(() {
                          _rotation = n.roundToDouble();
                          controller.rotation = _rotation;
                        });
                      },
                    ),
                  ),
                ),
                /*IconButton(
                icon: const Icon(Icons.rotate_right),
                //tooltip: 'Undo',
                onPressed: () {
                  controller.rotation = _rotation < 180? _rotation + 90 : 180;
                  controller.scale = 1;
                  controller.offset = Offset.zero;
                  setState(() {
                    _rotation = _rotation < 180? _rotation + 90 : 180;
                  });
                },
              ),*/
                Visibility(
                  visible: widget.aspectRatio == null,
                  child: PopupMenuButton<double>(
                    icon: const Icon(Icons.aspect_ratio),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text("Recom_").tr(),
                        value: 4 / 6,
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: Text("square_").tr(),
                        value: 1,
                      ),
                      /*const PopupMenuItem(
                      child: Text("4:3"),
                      value: 4.0 / 3.0,
                    ),
                    const PopupMenuItem(
                      child: Text("1:1"),
                      value: 1,
                    ),
                    const PopupMenuItem(
                      child: Text("3:4"),
                      value: 3.0 / 4.0,
                    ),
                    const PopupMenuItem(
                      child: Text("9:16"),
                      value: 9.0 / 16.0,
                    ),*/
                    ],
                    //tooltip: 'Aspect Ratio',
                    onSelected: (x) {
                      controller.aspectRatio = x;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      leftButtonIcon: Icons.close,
      rightButtonIcon: Icons.check,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      rightButtonPress: _cropImage,
    );
  }

  Future<dynamic> _saveCroppedImage(ui.Image img) async {
    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    var buffer = byteData!.buffer.asUint8List();

    return buffer;
  }
}
