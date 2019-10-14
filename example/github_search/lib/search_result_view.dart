import 'package:flutter/material.dart';
import 'package:github_search/github_client.dart';
import 'package:transparent_image/transparent_image.dart';

class SearchPopulatedView extends StatelessWidget {
  final SearchResult result;

  SearchPopulatedView(this.result);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: result?.items?.length ?? 0,
      itemBuilder: (context, index) {
        final item = result.items[index];
        return _SearchItem(item: item);
      },
    );
  }

  void showItem(BuildContext context, SearchResultItem item) {
    Navigator.push(
      context,
      MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return Scaffold(
            resizeToAvoidBottomPadding: false,
            body: GestureDetector(
              key: Key(item.avatarUrl),
              onTap: () => Navigator.pop(context),
              child: SizedBox.expand(
                child: Hero(
                  tag: item.fullName,
                  child: FadeInImage.memoryNetwork(
                    fadeInDuration: Duration(milliseconds: 700),
                    placeholder: kTransparentImage,
                    image: item.avatarUrl,
                    width: MediaQuery.of(context).size.width,
                    height: 300.0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  const _SearchItem({
    Key key,
    @required this.item,
  }) : super(key: key);

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return Scaffold(
                resizeToAvoidBottomPadding: false,
                body: GestureDetector(
                  key: Key(item.avatarUrl),
                  onTap: () => Navigator.pop(context),
                  child: SizedBox.expand(
                    child: Hero(
                      tag: item.fullName,
                      child: Image.network(
                        item.avatarUrl,
                        width: MediaQuery.of(context).size.width,
                        height: 300.0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      child: Container(
        alignment: FractionalOffset.center,
        margin: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 16.0),
              child: Hero(
                tag: item.fullName,
                child: ClipOval(
                  child: Image.network(
                    item.avatarUrl,
                    width: 56.0,
                    height: 56.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(
                      top: 6.0,
                      bottom: 4.0,
                    ),
                    child: Text(
                      "${item.fullName}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      "${item.url}",
                      style: TextStyle(
                        fontFamily: "Hind",
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
