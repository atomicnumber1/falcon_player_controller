import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String HOST = '10.0.0.1';
const int PORT = 2017;
final Duration timeout = new Duration(seconds: 3);
const String BASE_URL = 'http://$HOST:$PORT/';

enum ButtonActions { play, pause, stop, reboot, shutdown }

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String dropdownvalue = 'audio';
  List<String> playlists = <String>['audio', 'video'];

  Future runAction(String action, [String playlist]) async {
    var url;
    if (playlist != null)
      url = Uri.encodeFull(BASE_URL + action + '/' + playlist);
    else
      url = Uri.encodeFull(BASE_URL + action);

    http.Response response =
        await http.get(url, headers: {"Accept": "application/json"});
    return JSON.decode(response.body);
  }

  updateWifiSSID() {
    Socket.connect(HOST, PORT, timeout: timeout).then((socket) {
      socket.close();
      runAction('check_ssid').then((data) {
        if (data['status'] == 7)
          getSSID().then((ssid) {
            ssid ??= null;
            if (ssid == '') {
              showInSnackBar(
                  'SSID Can\'t be blank!. Please Provide a valid SSID',
                  timeout: 5);
              return;
            } else {
              var url = Uri.encodeFull(BASE_URL + 'update_ssid');
              http.post(
                url,
                headers: {"Accept": "application/json"},
                body: {"wifi_ssid": ssid},
              ).then((response) {
                var data = JSON.decode(response.body);
                if (data['status'] == 0)
                  showInSnackBar(
                      'WiFi SSID Updated! System will reboot in 10 secs...');
                else
                  showInSnackBar('[!] [${data['status']}] ${data['msg']}');
              }).catchError((e) {
                showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
              });
            }
          });
        else
          showInSnackBar(data['msg']);
      }).catchError((e) {
        showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
      });
    }).catchError((e) {
      String msg =
          '[!] Uh Oh! You\'re Not Connected to PI.\nPlease connect to PI Wifi Hotspot first.';
      showInSnackBar(msg, timeout: 5);
      return;
    });
  }

  Future<String> getSSID() async {
    String ssid = '';
    return await showDialog<String>(
      context: _scaffoldKey.currentContext,
      child: new AlertDialog(
        title: const Text('Update WiFi SSID'),
        content: new TextField(
          autofocus: true,
          maxLines: 1,
          onChanged: (value) => ssid = value,
          onSubmitted: (value) => ssid = value,
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('Update'),
            onPressed: () {
              Navigator.of(_scaffoldKey.currentContext).pop(ssid);
            },
          ),
        ],
      ),
    );
  }

  void _handleSelection(String value) {
    if (value == 'Update WiFi SSID') {
      updateWifiSSID();
    }
  }

  Future<bool> confirmAction(String action) async {
    return await showDialog<bool>(
          context: _scaffoldKey.currentContext,
          child: new AlertDialog(
            content: new Text('Are you sure you want to $action?'),
            actions: <Widget>[
              new FlatButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(_scaffoldKey.currentContext).pop(false);
                },
              ),
              new FlatButton(
                child: new Text('Yes'),
                onPressed: () {
                  Navigator.of(_scaffoldKey.currentContext).pop(true);
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  void showInSnackBar(String value, {int timeout: 3}) {
    _scaffoldKey.currentState.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
      duration: new Duration(seconds: timeout),
    ));
  }

  void _handleButton(ButtonActions action) {
    Socket.connect(HOST, PORT, timeout: timeout).then((socket) {
      socket.close();

      switch (action) {
        case ButtonActions.play:
          runAction('play', dropdownvalue).then((var data) {
            if (data['status'] == 0)
              showInSnackBar('Playing Playlist $dropdownvalue...');
            else
              showInSnackBar('[!] [${data['status']}] ${data['msg']}');
          }).catchError((e) {
            showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
          });
          break;
        case ButtonActions.stop:
          runAction('stop', dropdownvalue).then((var data) {
            if (data['status'] == 0)
              showInSnackBar('Stoping Playlist $dropdownvalue...');
            else
              showInSnackBar('[!] [${data['status']}] ${data['msg']}');
          }).catchError((e) {
            showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
          });
          break;
        case ButtonActions.reboot:
          confirmAction('reboot').then((val) {
            if (val)
              runAction('reboot').then((var data) {
                if (data['status'] == 0)
                  showInSnackBar('Rebooting PI in 10 secs...');
                else
                  showInSnackBar('[!] [${data['status']}] ${data['msg']}');
              }).catchError((e) {
                showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
              });
          });
          break;
        case ButtonActions.shutdown:
          confirmAction('shutdown').then((val) {
            if (val)
              runAction('shutdown').then((var data) {
                if (data['status'] == 0)
                  showInSnackBar('Shuting Down PI in 10 secs...');
                else
                  showInSnackBar('[!] [${data['status']}] ${data['msg']}');
              }).catchError((e) {
                showInSnackBar('Oops! Somethings\'s wrong. Please try again.');
              });
          });
          break;
        default:
          throw new Exception('No Such Action');
          break;
      }
    }).catchError((e) {
      String msg =
          '[!] Uh Oh! You\'re Not Connected to PI.\nPlease connect to PI Wifi Hotspot first.';
      showInSnackBar(msg, timeout: 5);
      return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(widget.title),
          actions: <Widget>[
            new PopupMenuButton<String>(
              onSelected: _handleSelection,
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(
                        value: 'Update WiFi SSID',
                        child: const Text('Update WiFi SSID')),
                  ],
            ),
          ],
        ),
        body: new SingleChildScrollView(
            child: new Column(
          children: <Widget>[
            new Container(
                padding: const EdgeInsets.only(top: 64.0),
                child: new Center(
                    child: new DropdownButton<String>(
                        hint: new Text('Select Playlist'),
                        value: dropdownvalue,
                        onChanged: (String newValue) {
                          setState(() {
                            if (newValue != null) dropdownvalue = newValue;
                          });
                        },
                        items: playlists.map((String playlist) {
                          return new DropdownMenuItem<String>(
                              value: playlist, child: new Text(playlist));
                        }).toList()))),
            new Container(
              padding: const EdgeInsets.only(top: 42.0),
              child: new Center(
                child: new RaisedButton(
                  child: const Text('Play'),
                  onPressed: () => _handleButton(ButtonActions.play),
                ),
              ),
            ),
            new Container(
              padding: const EdgeInsets.only(top: 42.0),
              child: new Center(
                child: new RaisedButton(
                  child: const Text('Stop'),
                  onPressed: () => _handleButton(ButtonActions.stop),
                ),
              ),
            ),
            new Container(
              padding: const EdgeInsets.only(top: 42.0),
              child: new Center(
                child: new RaisedButton(
                  child: const Text('Reboot'),
                  onPressed: () => _handleButton(ButtonActions.reboot),
                ),
              ),
            ),
            new Container(
              padding: const EdgeInsets.only(top: 42.0),
              child: new Center(
                child: new RaisedButton(
                  child: const Text('Shutdown'),
                  onPressed: () => _handleButton(ButtonActions.shutdown),
                ),
              ),
            ),
          ],
        )));
  }
}
