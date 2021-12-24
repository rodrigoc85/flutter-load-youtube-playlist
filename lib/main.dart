import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:stackoverflowsamples/youtube_api_v3/yt_api_v3.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DemoApp(),
    );
  }
}

class DemoApp extends StatefulWidget {
  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  static String key = "YOUR_API_KEY";

  YTAPIV3 ytApi = YTAPIV3(key, maxResults: 10);
  List<YT_API> ytResult = [];
  YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: '',
    flags: YoutubePlayerFlags(
      autoPlay: false,
      mute: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    print('hello');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("ytResult.length ${ytResult.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text('Youtube API & Youtube Player'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "This example retrieves all the videos in a playlist by id"),
          ),
          Expanded(
            child: FutureBuilder<List<YT_API>>(
                future: ytApi
                    .getPlaylistItems("PLKFGaNXRy6K0cKJTmeHSkr2R1aK8pkJJ3"),
                builder: (context, AsyncSnapshot<List<YT_API>> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'Error:${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData) {
                    snapshot.data.forEach((element) {
                      ytResult.add(element);
                    });

                    return Container(
                      child: ListView.builder(
                        itemCount: ytResult.length,
                        itemBuilder: (_, int index) => listItem(index),
                      ),
                    );
                  } else {
                    return Text('not video data');
                  }
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RaisedButton(
                  child: Text(
                    "<< Prev page",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                  onPressed: () async {
                    ytResult = await ytApi.prevPage();
                    if (ytResult != null) {
                      setState(() {});
                    }
                  }),
              RaisedButton(
                  child: Text(
                    "Next page >>",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                  onPressed: () async {
                    ytResult = await ytApi.nextPage();
                    if (ytResult != null) {
                      setState(() {});
                    }
                  }),
            ],
          )
        ],
      ),
    );
  }

  Widget listItem(index) {
    return InkWell(
      onTap: () {
        _controller = YoutubePlayerController(
          flags: YoutubePlayerFlags(
            autoPlay: true,
            hideThumbnail: true,
          ),
          initialVideoId: ytResult[index].videoId,
        );
        showDialog(
            context: context,
            builder: (context) {
              return YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blueAccent,
                progressColors: ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.blueAccent,
                ),
              );
            });
      },
      child: Card(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 7.0),
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: <Widget>[
              Image.network(
                ytResult[index].thumbnail['default']['url'],
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
              Padding(padding: EdgeInsets.only(right: 20.0)),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                    Text(
                      'Channel: ${ytResult[index].channelTitle}',
                      softWrap: true,
                    ),
                    Text(
                      ytResult[index].title,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15.0),
                    ),
                    Padding(padding: EdgeInsets.only(bottom: 1.5)),
                    Padding(padding: EdgeInsets.only(bottom: 3.0)),
                    Text(
                      'URL:${ytResult[index].url}',
                      maxLines: 3,
                      softWrap: true,
                      textAlign: TextAlign.left,
                    ),
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}
