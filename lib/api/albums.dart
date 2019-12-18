import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/album.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/albumview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Albums {
  static Future loadAlbumsFromNetworkOrCache(
      BuildContext context, String photoprismUrl) async {
    var key = 'albumList';
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      print(sp.getString(key));
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Album> albumList =
          parsed.map<Album>((json) => Album.fromJson(json)).toList();
      Provider.of<PhotoprismModel>(context).setAlbumList(albumList);
      return;
    }
    await loadAlbums(context, photoprismUrl);
  }

  static Future loadAlbums(BuildContext context, String photoprismUrl) async {
    http.Response response =
        await http.get(photoprismUrl + '/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Album> albumList =
        parsed.map<Album>((json) => Album.fromJson(json)).toList();

    Provider.of<PhotoprismModel>(context).setAlbumList(albumList);
  }

  static List<Album> getAlbumList(context) {
    Map<String, Album> albums =
        Provider.of<PhotoprismModel>(context, listen: false).albums;
    if (albums == null) {
      return null;
    }
    return albums.entries.map((e) => e.value).toList();
  }

  static Consumer<PhotoprismModel> getGridView(String photoprismUrl) {
    return Consumer<PhotoprismModel>(
        builder: (context, photoprismModel, child) {
      if (Albums.getAlbumList(context) == null) {
        return Text("loading");
      }
      return GridView.builder(
          key: ValueKey('albumsGridView'),
          gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: Albums.getAlbumList(context).length,
          itemBuilder: (context, index) {
            return GestureDetector(
                onTap: () {
                  Photos.loadPhotosFromNetworkOrCache(context, photoprismUrl,
                      Albums.getAlbumList(context)[index].id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AlbumView(
                            context,
                            Albums.getAlbumList(context)[index],
                            photoprismUrl)),
                  );
                },
                child: GridTile(
                  child: CachedNetworkImage(
                    imageUrl: photoprismUrl +
                        '/api/v1/albums/' +
                        Albums.getAlbumList(context)[index].id +
                        '/thumbnail/tile_500',
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  footer: GestureDetector(
                    child: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: _GridTitleText(
                          Albums.getAlbumList(context)[index].name),
                    ),
                  ),
                ));
          });
    });
  }
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}
