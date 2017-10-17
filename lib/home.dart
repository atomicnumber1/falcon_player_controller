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

  Future<bool> confirmAction(BuildContext context, String action) async {
    return showDialog<bool>(
      context: context,
      child: new AlertDialog(
        content: new Text('Are you sure you want to $action?'),
        actions: <Widget>[
          new FlatButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          new FlatButton(
            child: new Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  void _notify(BuildContext context, String text, {int timeout: 3}) {
    Scaffold.of(context).removeCurrentSnackBar();
    Scaffold.of(context).showSnackBar(new SnackBar(
          content: new Text(text),
          duration: new Duration(seconds:timeout),
    ));
  }

  void _handleButton(BuildContext context, ButtonActions action) {
    Socket.connect(HOST, PORT, timeout: timeout).then((socket) {
      socket.close();

      switch (action) {
        case ButtonActions.play:
          runAction('play', dropdownvalue).then((var data) {
            if (data['status'] == 0)
              _notify(context, 'Playing Playlist $dropdownvalue...');
            else
              _notify(context, '[!] [${data['status']} ${data['msg']}');
          });
          break;
        case ButtonActions.stop:
          runAction('stop', dropdownvalue).then((var data) {
            if (data['status'] == 0)
              _notify(context, 'Stoping Playlist $dropdownvalue...');
            else
              _notify(context, '[!] [${data['status']} ${data['msg']}');
          });
          break;
        case ButtonActions.reboot:
          confirmAction(context, 'reboot').then((val) {
            if (val)
              runAction('reboot').then((var data) {
                if (data['status'] == 0)
                  _notify(context, 'Rebooting PI in 10 secs...');
                else
                  _notify(context, '[!] [${data['status']} ${data['msg']}');
              });
          });
          break;
        case ButtonActions.shutdown:
          confirmAction(context, 'shutdown').then((val) {
            if (val)
              runAction('shutdown').then((var data) {
                if (data['status'] == 0)
                  _notify(context, 'Shuting Down PI in 10 secs...');
                else
                  _notify(context, '[!] [${data['status']} ${data['msg']}');
              });
          });
          break;
        default:
          throw new Exception('No Such Action');
          break;
      }
    }).catchError((e) {
      String msg =
          '[!] Uh Oh! You\'re Not Connected to PI. Please connect to PI Wifi Hotspot first.';
      _notify(context, msg, timeout:5);
      return;
    });
  }

  Widget buildBody(BuildContext context) {
    return new Container(
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
              onPressed: () => _handleButton(context, ButtonActions.play),
            ),
          ),
        ),
        new Container(
          padding: const EdgeInsets.only(top: 42.0),
          child: new Center(
            child: new RaisedButton(
              child: const Text('Stop'),
              onPressed: () => _handleButton(context, ButtonActions.stop),
            ),
          ),
        ),
        new Container(
          padding: const EdgeInsets.only(top: 42.0),
          child: new Center(
            child: new RaisedButton(
              child: const Text('Reboot'),
              onPressed: () => _handleButton(context, ButtonActions.reboot),
            ),
          ),
        ),
        new Container(
          padding: const EdgeInsets.only(top: 42.0),
          child: new Center(
            child: new RaisedButton(
              child: const Text('Shutdown'),
              onPressed: () => _handleButton(context, ButtonActions.shutdown),
            ),
          ),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Builder(builder: buildBody));
  }
}
