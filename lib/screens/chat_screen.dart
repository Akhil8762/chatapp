import 'package:chatapp/components/constant.dart';
import 'package:chatapp/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// object of firebase
final _auth = FirebaseAuth.instance;

//object for firestore in firebase
final _firestore = FirebaseFirestore.instance;

User loggedInUser; // for getting data currently using user
// User is data type in firebase

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageText; // for storing sended messages
  // TextEditingController => for editing text to our like(textfield)
  final messageController = TextEditingController();

  // for adding current user to logged user
  void getUser() async {
    try {
      if (_auth != null) {
        loggedInUser = _auth.currentUser;
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();

                // to go to previous page
                Navigator.pushNamed(context, WelcomeScreen.id);
              })
        ],
        title: Text('Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            MessageStream(),
            Container(
              decoration: kMessageContainer,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextField,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      messageController.clear();
                      await _firestore.collection("messages").add({
                        "text": messageText,
                        "user": loggedInUser.email,
                        "time": FieldValue.serverTimestamp(),
                      }).whenComplete(() => print("completed"));
                    },
                    child: Text(
                      "send",
                      style: kSendButton,
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
  @override
  Widget build(BuildContext context) {
    // streamBuilder used to add and fetch data from db from firebase
    // here streamBuilder is used to automatically store data & fetch from db
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("messages").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          var messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final String messageText = message.data()["text"];
            final String messageSender = message.data()["user"];
            final Timestamp messageTime = message.data()["time"] as Timestamp;
            final currentUser = loggedInUser.email;
            final messageBubble = MessageBubble(
              messageText: messageText,
              messageSender: messageSender,
              isMe: currentUser == messageSender,
              time: messageTime,
            );

            messageBubbles.add(messageBubble);
            messageBubbles
                .sort((a, b) => b.time.toString().compareTo(a.time.toString()));
          }

          return Expanded(
              child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            children: messageBubbles,
          ));
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String messageText;
  final bool isMe;
  final String messageSender;
  final Timestamp time;

  MessageBubble(
      {@required this.messageText, this.messageSender, this.isMe, this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            messageSender,
            style: TextStyle(
              fontSize: 11.0,
            ),
          ),
          Material(
            elevation: 15.0,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 30.0 : 0.0),
              bottomLeft: Radius.circular(30.0),
              topRight: Radius.circular(isMe ? 0.0 : 30.0),
              bottomRight: Radius.circular(0.0),
            ),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                messageText,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
