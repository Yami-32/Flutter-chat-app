import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

User loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  String messagetext;
  final _fireStore = FirebaseFirestore.instance;
  final messageTextController = TextEditingController();

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(fireStore: _fireStore),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messagetext = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _fireStore.collection('messages').add({
                        'Text': messagetext,
                        'sender': loggedInUser.email,
                        'timeStamp': FieldValue.serverTimestamp(),
                      });
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({
    Key key,
    @required FirebaseFirestore fireStore,
  })  : _fireStore = fireStore,
        super(key: key);

  final FirebaseFirestore _fireStore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream:
            _fireStore.collection('messages').orderBy('timeStamp').snapshots(),
        builder: (context, snapshot) {
          List<MessageBubble> messageWidgetList = [];
          if (!snapshot.hasData) {
            return Container(
              child: Expanded(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            );
          }
          final messages = snapshot.data.docs;

          for (var message in messages) {
            final messageData = message.data();
            final messageText = messageData['Text'];
            final sender = messageData['sender'];
            final messageWidget = MessageBubble(
              text: messageText,
              sender: sender,
              isme: sender == loggedInUser.email,
            );

            messageWidgetList.add(messageWidget);
          }
          return Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              children: messageWidgetList,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isme});

  final String text;
  final String sender;
  final bool isme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '$sender',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Material(
            elevation: 5,
            borderRadius: BorderRadius.only(
              topLeft: isme ? Radius.circular(30) : Radius.circular(0),
              topRight: isme ? Radius.circular(0) : Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            color: isme ? Colors.lightBlueAccent[100] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '$text',
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
