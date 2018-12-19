import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';



class Detail extends StatefulWidget {
  @override
  _DetailState createState() => _DetailState();
}
CloudFunctions cloudFunctions = CloudFunctions.instance;
FirebaseAuth auth = FirebaseAuth.instance;
var phonecontroller = new TextEditingController();

String vname;
class _DetailState extends State<Detail> {



  final formKey = new GlobalKey<FormState>();
  String _name,_housenumber,_purpose,_error,download;
  String image_process = "Please add image" ;
  bool load = false ;
  bool found=false ;
  DocumentReference documentReference ;
  
  Future<FirebaseUser> _ensureLoggedIn() async{
  FirebaseUser user = await auth.signInWithEmailAndPassword(
                email:    "9992306105@123.com",
                password: "e3539d",

  );
  print("login success");
  return user;
}
  
  var housenumber,purpose,downloadurl;
  dynamic check(res){
    dynamic obj = json.decode(res.toString());
    if(obj.containsKey("error"))
    {//todo
      print(obj['error']);
      return false;
    }else
    {
      return obj['data'];
    }
  }

  Future<dynamic> callCloudFunc({String functionName , Map<String , dynamic> parameters}) async {
    try{
      var res = await CloudFunctions.instance.call(functionName: functionName,parameters: parameters);
      print(res);
      print(res);
      var obj =  check(res);
      return obj;
    }catch(e){
      print(e);
    }
    return false;
  }
  bool phone_exist_check(){
    documentReference = Firestore.instance.collection("society").document("sunshine").collection("visitor").document("${phonecontroller.text.toString()}");
    String name;
    documentReference.get().then((snapshot){
      if(snapshot.exists){
        name=snapshot['name'];
        housenumber=snapshot['housenumber'];
        purpose=snapshot['purpose'];
        downloadurl=snapshot['downloadurl'];
      }
    }).whenComplete((){
      // print(name); 
      vname=name;
      found=true;
      load=false;
      // print(load);
      if(name==null){found=false;}
      setState(() {});
      return true;
    });
    if(name==null){
      // print("number not found");
      found=false;
      return false;

    }
  }

  bool phone_check(){
    if(phonecontroller.text.toString().length==10){
      // print("it is 10 now");
      return true;
    }else{
      // print("not 10");
      return false;
    }
  }

  bool _validate(){
    final form  = formKey.currentState;
    if(form.validate()){
      form.save();
      return true ;
    } else {
      return false ;
    }
  }

  void _update() async{
    DateTime dateTime = DateTime.now();
    Map<String,dynamic> data = <String,dynamic> {
      "name" : vname,
      "housenumber" : housenumber,
      "purpose" : purpose,
      "mobile" : phonecontroller.text.toString(),
      "time" : dateTime,
      "downloadurl" : downloadurl,
    };
    documentReference = Firestore.instance.collection("society").document("sunshine").collection("visitor").document("${phonecontroller.text.toString()}");
    documentReference.updateData(data).whenComplete((){
      print("Document updated $housenumber");
      Navigator.of(context).pop();
    });
  }

  void submit() async{
    DateTime dateTime = DateTime.now();
    if(_validate()){
      try {
        print("$_name  $_housenumber $_purpose ${phonecontroller.text.toString()}");
        print("$download");
        Map<String,dynamic> data = <String,dynamic> {
          "society": "sunshine",
          "house" : _housenumber,
          "name" : _name ,
          "purpose" : _purpose,
          "additional" :
          {
          "imageurl": download
          }
        };
        var res;
        try {
          res = await CloudFunctions.instance.call(
              functionName: 'addVisitor',parameters: data);
        }catch( e ){
          print("this error ${e.message}");
        }
        print("${res.toString()}");
          Navigator.of(context).pop();

      }
      catch(e){
        print(_error);
        setState(() {
                  _error="Some problem" ;
                });
      }
    }
  }

    File img;
    Future picker(int c,String s) async{
    print("picker called");
//    setState(() {});
    var _img;
    if(c==1){
      _img = await ImagePicker.pickImage(source: ImageSource.gallery);
    }
    else if(c==2){
      _img = await ImagePicker.pickImage(source: ImageSource.camera);
    }
  
    if(_img!=null){      
      img=_img;
      print("image adder called");
      imageadder(s);
    }

  }
  void down() async{
    download = await FirebaseStorage.instance.ref().child("Visitors").child("${phoneno}.jpg").getDownloadURL();
    print(download);
    image_process="Sucessfully uploaded image";
    setState(() {});
  }
  String location;
  String phoneno = phonecontroller.text.toString();

  void imageadder(String s) async{
    image_process = "Uploading image please wait" ;
    setState(() {});
    var ref=FirebaseStorage.instance.ref();
    print("${img.path} $phoneno");
    ref..child("Visitors").child("${phoneno}.jpg").putFile(img).onComplete.then((onValue){
      down();
    });
    
    // download = await ref.child("${phoneno}.jpg").getDownloadURL();
    
    // location = await ref.getDownloadURL();
    // print(location);
    setState(() {});
  }

  @override
    void initState(){
      // TODO: implement initState
      super.initState();
      phonecontroller.clear();
      _ensureLoggedIn();
      print("done");
      // const oneSec = const Duration(seconds:4);
      // new Timer.periodic(oneSec, (Timer t){
      //   if(phone_check()==true){
      //     load = true;
      //     setState(() {});
      //     phone_exist_check();
      //     // print(load);
      //     // if(phone_exist_check()==true){
      //     //   print("number found");
      //     //   t.cancel();
      //     // }
      //     // if(found==true){
      //     //   phonecontroller.addListener((){
      //     //     print("listner call");
              
      //     //   });
      //     // }
      //   }
      // });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Enter Details"),
      ),
      body: new ListView(
        padding: EdgeInsets.all(30.0),
        children: <Widget>[
          
          new TextField(
           keyboardType: TextInputType.number,
           decoration: InputDecoration(
           labelText: "Phone Number",
            hintText: "Enter 10 digit phone number",             
            ),
            // onEditingComplete: (){
            //   print("edit complete");
            // },
            onChanged: (String s){
              print("text changed");
              if(phone_check()==true){
                load=true;
                image_process = "Please add image";
                setState(() {});
                phone_exist_check();
              }
              // if(found==true){
              //   found=false;
              // }
            }, 
            maxLength: 10,
            controller: phonecontroller,
          ),
          (load==true&&found==false) ? 
          new Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: LinearProgressIndicator(),
          ) : new Container(),
          new Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          vname!=null ? new Container(
            child: new MaterialButton(
              child: new Column(
                children: <Widget>[
                  Text("$vname",style: TextStyle(color: Colors.white,fontSize: 20.0),),
                  Text("Tap to Allow/ अनुमति दे",style: TextStyle(color: Colors.white,fontSize: 20.0))
                ],
              ),
              padding: EdgeInsets.all(10.0),
              color: new Color(0xFF5424eb),
              onPressed: (){
                _update();
              },
            )
          ) : new Container(
            child: Form(
                key: formKey,
                child: new Column(
                children: <Widget>[
              new IconButton(
              padding: EdgeInsets.only(right: 45.0),
              icon: Icon(Icons.photo_camera,size: 100.0,),
              onPressed: (){
                picker(2, "photo");
              },
              ),
              new Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                ),
              new TextFormField(
                decoration: new InputDecoration(
                  hintText: "eg. F0212",
                  labelText: "House number/ घर का नंबर"
                ),
                validator: (value) => value.isEmpty ? 'Please Enter House number' : null,
                onSaved: (value) => _housenumber=value,
              ),
              new Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                ),
                new TextFormField(
                decoration: new InputDecoration(
                  hintText: "Enter name",
                  labelText: "Name / नाम"
                ),
                validator: (value) => value.isEmpty ? 'Please Enter name' : null,
                onSaved: (value) => _name=value,
              ),
              new Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                ),
                new TextFormField(
                decoration: new InputDecoration(
                  hintText: "Enter Purpose of visit",
                  labelText: "purpose / उद्देश्य"
                ),
                validator: (value) => value.isEmpty ? 'Please Enter purpose' : null,
                onSaved: (value) => _purpose=value,
              ),
              new Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                ),
              ((image_process=="Uploading image please wait")||(image_process=="Please add image")) ? new Container():
                new MaterialButton(
                  child: Text("Tap to Allow/ अनुमति दे",style: TextStyle(color: Colors.white,fontSize: 20.0)),
                  onPressed: (){
                    submit();
                  },
                  color: new Color(0xFF5424eb),
                )  ,
                new Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                ),
                new Text("$image_process"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
