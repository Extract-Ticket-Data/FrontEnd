import 'dart:async';

import 'package:bottomnav/classes/language.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:toast/toast.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageInput();
  }
}

class _ImageInput extends State<ImageInput> {
  // To store the file provided by the image_picker
  File _imageFile;
  //Text To speech
  final FlutterTts flutterTts = FlutterTts();
  //Translator
  final translator = GoogleTranslator();
  String languagecode = 'en';

  // To track the file uploading state
  bool _isUploading = false;
  bool _isUploaded = false;
  bool _inProcess = false;

  String baseUrl = 'https://textextractorbackend.herokuapp.com/api/';
  TextEditingController fromToController;
  TextEditingController dateController;
  TextEditingController timeController;
  TextEditingController perHeadPriceController;
  TextEditingController numofTravellerController;
  TextEditingController netPriceController;
  String fromTo = '';
  String date = '';
  var dateList = new List();
  var dateFormat = new List();
  String dateToSpeak = '';
  String time = '';
  String perHeadPrice = '';
  String numOfTraveller = '';
  String netPrice = '';

  @override
  void initState() {
    super.initState();
    //initTts();
  }

  void setController() {
    setState(() {
      fromToController = new TextEditingController(text: fromTo);
      dateController = new TextEditingController(text: date);
      timeController = new TextEditingController(text: time);
      perHeadPriceController = new TextEditingController(text: perHeadPrice);
      numofTravellerController =
          new TextEditingController(text: numOfTraveller);
      netPriceController = new TextEditingController(text: netPrice);
    });
  }

  void _getImage(BuildContext context, ImageSource source) async {
    this.setState((){
      _inProcess = true;
    });
    File image = await ImagePicker.pickImage(source: source);
    setState(() {
      _imageFile = image;
    });
    if (image != null) {
      File cropped = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 0.8, ratioY: 1),
        compressQuality: 100,
        //maxWidth: 400,
        //maxHeight: 400,
        androidUiSettings: AndroidUiSettings(
            toolbarColor: Colors.deepOrange,
            toolbarTitle: 'Crop Image',
            statusBarColor: Colors.deepOrange.shade900,
            backgroundColor: Colors.white),
      );
      setState(() {
      _imageFile = cropped;
      _inProcess = false;
    }
    );
    }
    else{
      this.setState((){
        _inProcess = false;
      });
    }

    // Closes the bottom sheet
    Navigator.pop(context);
  }

  Future<Map<String, dynamic>> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });

    // Find the mime type of the selected file by looking at the header bytes of the file
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');

    // Intilize the multipart request
    final imageUploadRequest =
        http.MultipartRequest('POST', Uri.parse(baseUrl));

    // Attach the file in the request
    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    // Explicitly pass the extension of the image with request body
    // Since image_picker has some bugs due which it mixes up
    // image extension with file name like this filenamejpge
    // Which creates some problem at the server side to manage
    // or verify the file extension
    //imageUploadRequest.fields['image'] = mimeTypeData[0];
    imageUploadRequest.fields['ext'] = mimeTypeData[1];
    imageUploadRequest.files.add(file);
    print(image.path);
    print(mimeTypeData[0]);
    print(imageUploadRequest);
    print(file);

    try {
      final streamedResponse = await imageUploadRequest.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      //_resetState();

      return responseData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void changeDateFormat(String oldDate){
    //You can Add manually here
    if(oldDate != ''){
      var temp = oldDate.split("|");
      date = temp[0];
      dateList = temp[0].split("/");
      dateFormat = temp[1].split("/");
    }
    dateToSpeak = '';
    for(int i=0;i<dateList.length;i++){
      dateToSpeak += dateFormat[i] + " "+dateList[i] + ",";
    }
    dateToSpeak += ".";
  }
  void _startUploading() async {
    final Map<String, dynamic> response = await _uploadImage(_imageFile);
    setState(() {
      _isUploaded = true;
      _isUploading = false;
    });
    //setController();
    print(response);
    setState(() {
        fromTo = '';
        date = '';
        time = '';
        perHeadPrice = '';
        numOfTraveller = '';
        netPrice = '';
      });
    // Check if any error occured
    if (response['response'] == '0' ||
        response == null ||
        response.containsKey("error")) {
      //data = jsonDecode(response);
      Toast.show(" Data Fetched Failed!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      //var arr = response['date'].split('/');
      setState(() {
        fromTo = response['FromTo'];
        date = response['date'];
        changeDateFormat(date);
        time = response['time'];
        perHeadPrice = response['PerHeadPrice'];
        numOfTraveller = response['total_travellers'];
        netPrice = response['total_price'];
      });
      Toast.show("Data Fetched Successfully!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      if(fromTo.indexOf("not sure") != -1||perHeadPrice.indexOf("not sure") != -1){
        _speak("Fetched Data is incorrect! Please scan your ticket again." );
      }
    }
    setController();
  }

  void _resetState() {
    setState(() {
      _isUploading = false;
      _imageFile = null;
      _isUploaded = false;
    });
  }

  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    print('Image Picker Modal Called');
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Pick an image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Camera'),
                  onPressed: () {
                    _resetState();
                    _getImage(context, ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Gallery'),
                  onPressed: () {
                    _resetState();
                    _getImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(width: 1.0),
      borderRadius: BorderRadius.all(
          Radius.circular(15.0) //         <--- border radius here
          ),
    );
  }

  Widget _buildUploadBtn() {
    Widget btnWidget = Container();

    if (_isUploading) {
      // File is being uploaded then show a progress indicator
      btnWidget = Container(
          margin: EdgeInsets.only(top: 10.0),
          child: CircularProgressIndicator());
    } else if (!_isUploading && _imageFile != null && !_isUploaded) {
      // If image is picked by the user then show a upload btn

      btnWidget = Container(
        margin: EdgeInsets.only(top: 10.0),
        child: RaisedButton(
          child: Text('Fetch Data'),
          onPressed: () {
            _startUploading();
          },
          color: Colors.pinkAccent,
          textColor: Colors.white,
        ),
      );
    }

    return btnWidget;
  }

  Future _speak(String _newVoiceText) async {
    //print(await flutterTts.getLanguages);
    await flutterTts.setLanguage("hi-IN");
    var translatedVoiceText =
        await translator.translate(_newVoiceText, from: 'en', to: this.languagecode);
    await flutterTts.setSpeechRate(0.7);
    await flutterTts.setPitch(1);
    await flutterTts.speak(translatedVoiceText);
  }

  Widget _dataViewWidget() {
    Widget dataViewWidget = Column();
    if (_imageFile != null && _isUploaded) {
      dataViewWidget = Column(
        children: <Widget>[
          fromTo == ''? Container():
          Stack(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 5.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () => _speak("Price Per Ticket between "+ fromTo + " is "+ perHeadPrice+" rupees"),
                ),
              ),
            ],
          ),
          fromTo == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: fromToController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'FromTo',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () => _speak("Your ticket is between " + fromTo),
                ),
              ),
            ],
          ),
          date == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: dateController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Date',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () => _speak("Date of Ticket booking is " + date),
                ),
              ),
            ],
          ),
          time == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: timeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Time',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () => _speak("Time of ticket booking is " + time),
                ),
              ),
            ],
          ),
          perHeadPrice == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: perHeadPriceController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'PerHeadPrice',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () =>
                      _speak("Price per ticket is " + perHeadPrice + " Rupees"),
                ),
              ),
            ],
          ),
          numOfTraveller == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: numofTravellerController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'NumOfTraveller',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () => _speak(
                      "Total number of travellers are " + numOfTraveller),
                ),
              ),
            ],
          ),
          netPrice == ''? Container():
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(10.0),
                child: TextField(
                  enabled: false,
                  controller: netPriceController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Total Price',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: Icon(Icons.volume_up, color: const Color(0xfff96800)),
                  onPressed: () =>
                      _speak("Total Ticket Price is " + netPrice + " Rupees"),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return dataViewWidget;
  }

  void _changeLanguage(Language language){
    setState(() {
      this.languagecode = language.languageCode;
    });
    print(language.languageCode);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Data Extractor'),
        actions: <Widget>[
          Padding(padding: EdgeInsets.all(8.0),
          child: DropdownButton(
            onChanged: (Language language){
              _changeLanguage(language);
            },
            underline: SizedBox(),
            icon: Icon(
              Icons.language,
              color: Colors.white,
            ),
            items: Language.languageList().map<DropdownMenuItem<Language>>((lang)=> DropdownMenuItem(
              value: lang,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:<Widget>[
                  Text(lang.flag),
                  Text(lang.name)
                ]
              ),
            )).toList(),
          ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0),
                child: OutlineButton(
                  onPressed: () => _openImagePickerModal(context),
                  borderSide: BorderSide(
                      color: Theme.of(context).accentColor, width: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.camera_alt),
                      SizedBox(
                        width: 5.0,
                      ),
                      Text('Add Image'),
                    ],
                  ),
                ),
              ),
              _imageFile == null
                  ? Text('Please pick an image')
                  : Image.file(
                      _imageFile,
                      fit: BoxFit.cover,
                      height: 400.0,
                      alignment: Alignment.topCenter,
                      width: MediaQuery.of(context).size.width,
                    ),
              _buildUploadBtn(),
              _dataViewWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
