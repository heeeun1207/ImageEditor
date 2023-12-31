import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_editor1/component/main_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // 파일 관련 기능을 사용하기 위해 추가
import 'package:image_editor1/component/footer.dart';
import 'package:image_editor1/model/sitcker_model.dart';
import 'package:image_editor1/component/emotion_sticker.dart';
import 'package:uuid/uuid.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';

// 이미지 저장 임포트 기능
import 'package:image_gallery_saver/image_gallery_saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  XFile? image; // 선택한 이미지를 저장할 변수
  Set<StickerModel> stickers = {}; // 화면에 추가된 스티커를 저장할 변수
  String? selectedId; // 현재 선택된 스티커의 ID
  GlobalKey imgKey = GlobalKey(); // 이미지로 전환할 위젯에 입력해줄 키값

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // 스크린에 Body, AppBar, Footer 순서로 쌓을 준비
        fit: StackFit.expand, // 자식 위젯들을 최대 크기로 펼치기
        children: [
          renderBody(),
          // MainAppBar 좌,우,위 끝에 정렬
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MainAppBar(
              onPickImage: onPickImage,
              onSaveImage: onSaveImage,
              onDeleteItem: onDeleteItem,
            ),
          ),
          // image가 선택되면 Footer 위치하기
          if(image != null)
            Positioned( // 맨 아래에 Footer 위젯 위치하기
              bottom: 0,
              // left 와 right 를 모두 0을 주면 좌우로 최대 크기 차지함
              left: 0,
              right: 0,
              child: Footer(
                onEmoticonTap: onEmoticonTap,
              ),
            ),
        ],
      ),
    );
  }

  Widget renderBody() {
    if (image != null) {
      return RepaintBoundary(
        // 위젯을 이미지로 저장하는 데 사용
        key: imgKey,
      // Stack 크기의 최대 크기만큼 차지
        child: Positioned.fill(
        // 위젯 확대 및 좌우 이동을 가능하게 하는 위젯
        child: InteractiveViewer(
          child: Stack(
            fit: StackFit.expand, // 크기 최대로 늘려주기
            children: [
              Image.file(
                File(image!.path),
                // 이미지가 부모 위젯 크기의 최대를 차지하도록 하기
                fit: BoxFit.cover,
              ),
              ...stickers.map(
                    (sticker) => Center( // 최초 스티커 선택시 중앙에 배치
                  child: EmoticonStictker(
                    key: ObjectKey(sticker.id),
                    onTransform: (){
                      onTransform(sticker.id);
                      // 스티커의 ID값 함수의 매개변수로 전달
                    },
                    imgPath : sticker.imgPath,
                    isSelected : selectedId == sticker.id,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    } else {
      // 이미지 선택이 안 된 경우 이미지 선택 버튼 표시
      return Center(
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          onPressed: onPickImage,
          child: Text('이미지 선택하기'),
        ),
      );
    }
  }


  void onPickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    // 갤러리에서 이미지 선택하기
    setState(() {
      this.image = image; // 선택한 이미지 저장하기
    });
  }

  void onSaveImage() async { // 이미지 저장 기능 구현 함수
    RenderRepaintBoundary boundary = imgKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(); // 바운더리를 이미지로 변경
    ByteData? byteDate = await image.toByteData(format: ui.ImageByteFormat.png);
    // byte data 형태로 변경
    Uint8List pngBytes = byteDate!.buffer.asUint8List();
    // Uint8List 형태로 변경
    // ImageGallerySaver 플러그인은 바이터 데이터가 8비트 정수형으로 변환되는걸 요구하므로 필수 과정이다.

    // 이미지 저장하기
    await ImageGallerySaver.saveImage(pngBytes, quality: 100);

    ScaffoldMessenger.of(context).showSnackBar( // 저장후 SnackBar 보여주기
      SnackBar(
          content:Text('저장되었습니다!'),
      ),
    );
  }


  void onDeleteItem() async{
    setState(() {
      stickers = stickers.where((sticker) => sticker.id != selectedId).toSet();
      // 현재 선택되 있는 스티커 삭제 후 Set으로 변환
    });
  }

  void onEmoticonTap(int index) async{
    setState(() {
      stickers = {
        ...stickers,
        StickerModel(
          id: Uuid().v4(), // 스티커의 고유 ID
          imgPath: 'asset/img/emoticon_$index.png',
        ),
      };
    });
  }

  void onTransform(String id) {
    // 스티커가 변형될 때마다 변형 중인 스티커를 현재 선택한 스티커로 지정
    setState(() {
      selectedId = id;
    });
  }
}