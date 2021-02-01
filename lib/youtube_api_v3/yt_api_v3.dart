import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class YTAPIV3 {
  static String baseURL = 'www.googleapis.com';
  String playlistId;
  String prevPageToken;
  String nextPageToken;
  int    maxResults;
  String key;

  YTAPIV3(key, {int maxResults: 10}) {
    this.maxResults = maxResults;
    this.key       = key;
  }

  Future<List<YT_API>> getPlaylistItems(String playlistId) async {
    this.playlistId = playlistId;
    Object options = {
      "playlistId": playlistId,
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
    };

    Uri url      = new Uri.https(baseURL, "youtube/v3/playlistItems", options);
    var res      = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);
    print(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YT_API>[];
    List<YT_API> result = await _getResultFromJson(jsonData);
    return result;
  }

  Uri videoUri(List<String> videoId) {
    int length      = videoId.length;
    String videoIds = videoId.join(',');
    var options = {
      "part": "contentDetails",
      "id": videoIds,
      "maxResults": "$length",
      "key": "${this.key}",
    };

    Uri url = new Uri.https(baseURL, "youtube/v3/videos", options);
    return url;
  }

  /*
  Get video details from video Id
   */
  Future<List<YT_VIDEO>> video(List<String> videoId) async {
    List<YT_VIDEO> result = [];
    Uri url = videoUri(videoId);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);

    if (jsonData == null) return [];

    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];

    for (int i = 0; i < total; i++) {
      result.add(new YT_VIDEO(jsonData['items'][i]));
    }
    return result;
  }

  Future<List<YT_API>> _getResultFromJson(jsonData) async {
    List<YT_API> result = [];
    if (jsonData == null) return [];
    nextPageToken = jsonData['nextPageToken'];
    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    print("total $total");
    result = await _getListOfYTAPIs(jsonData, total);
    return result;
  }

  Future<List<YT_API>> _getListOfYTAPIs(dynamic data, int total) async {
    List<YT_API> result      = [];
    List<String> videoIdList = [];
    for (int i = 0; i < total; i++) {
      print("_getListOfYTAPIs $i $total");
      YT_API ytApiObj =
      new YT_API(data['items'][i], getTrendingVideo: false);
      if (ytApiObj.kind == "video") videoIdList.add(ytApiObj.id);
      result.add(ytApiObj);
    }
    List<YT_VIDEO> videoList = await video(videoIdList);
    await Future.forEach(videoList, (YT_VIDEO ytVideo) {
      YT_API ytAPIObj = result.singleWhere((ytAPI) => ytAPI.id == ytVideo.id,
          orElse: () => null);
      ytAPIObj.duration = getDuration(ytVideo?.duration ?? "") ?? "";
    });
    return result;
  }

  Future<List<YT_API>> nextPage() async {
    if (nextPageToken == null) return null;
    List<YT_API> result = [];

    Object options = {
      "pageToken": nextPageToken,
      "playlistId": playlistId,
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
    };
    Uri url = new Uri.https(baseURL, "youtube/v3/playlistItems", options);
    print(url.toString());
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return <YT_API>[];

    if (jsonData == null) return <YT_API>[];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];

    int total = jsonData['items'].length;
    result = await _getListOfYTAPIs(jsonData, total);

    if (total == 0) {
      return <YT_API>[];
    }
    return result;
  }

  Future<List<YT_API>> prevPage() async {
    if (prevPageToken == null) return null;
    List<YT_API> result = [];

    Object options = {
      "pageToken": prevPageToken,
      "playlistId": playlistId,
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
    };
    Uri url = new Uri.https(baseURL, "youtube/v3/playlistItems", options);
    var res = await http.get(url, headers: {"Accept": "application/json"});

    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return <YT_API>[];

    if (jsonData == null) return <YT_API>[];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];

    int total = jsonData['items'].length;
    result = await _getListOfYTAPIs(jsonData, total);
    if (total == 0) {
      return <YT_API>[];
    }
    return result;
  }

}

///
/// @TODO: The next classes should be in their own files.
///
class YT_API {
  dynamic thumbnail;
  String kind,
      id,
      publishedAt,
      channelId,
      channelurl,
      title,
      description,
      channelTitle,
      url,
      duration;

  YT_API(dynamic data, {bool getTrendingVideo: false}) {
    thumbnail = {
      'default': data['snippet']['thumbnails']['default'],
      'medium': data['snippet']['thumbnails']['medium'],
      'high': data['snippet']['thumbnails']['high']
    };
    kind          = 'video';
    id            = data['id'];
    url           = getURL(kind, id);
    publishedAt   = data['snippet']['publishedAt'];
    channelId     = data['snippet']['channelId'];
    channelurl    = "https://www.youtube.com/channel/$channelId";
    title         = data['snippet']['title'];
    description   = data['snippet']['description'];
    channelTitle  = data['snippet']['channelTitle'];
  }

  String getURL(String kind, String id) {
    String baseURL = "https://www.youtube.com/";
    switch (kind) {
      case 'channel':
        return "${baseURL}channel/$id";
        break;
      case 'video':
        return "${baseURL}watch?v=$id";
        break;
      case 'playlist':
        return "${baseURL}playlist?list=$id";
        break;
    }
    return baseURL;
  }
}

class YT_VIDEO {
  String duration;
  String id;

  YT_VIDEO(dynamic data) {
    id = data['id'];
    duration = data['contentDetails']['duration'];
  }
}

String getDuration(String duration) {
  if (duration.isEmpty) return null;
  duration = duration.replaceFirst("PT", "");

  var validDuration = ["H", "M", "S"];
  if (!duration.contains(new RegExp(r'[HMS]'))) {
    return null;
  }
  var hour = 0, min = 0, sec = 0;
  for (int i = 0; i < validDuration.length; i++) {
    var index = duration.indexOf(validDuration[i]);
    if (index != -1) {
      var valInString = duration.substring(0, index);
      var val = int.parse(valInString);
      if (i == 0)
        hour = val;
      else if (i == 1)
        min = val;
      else if (i == 2) sec = val;
      duration = duration.substring(valInString.length + 1);
    }
  }
  List buff = [];
  if (hour != 0) {
    buff.add(hour);
  }
  if (min == 0) {
    if (hour != 0) buff.add(min.toString().padLeft(2, '0'));
  } else {
    buff.add(min.toString().padLeft(2, '0'));
  }
  buff.add(sec.toString().padLeft(2, '0'));

  return buff.join(":");
}
