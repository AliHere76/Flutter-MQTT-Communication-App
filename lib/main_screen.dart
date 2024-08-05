import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mqtt/mqtt.dart';

class main_screen extends StatefulWidget {
  @override
  _mainScreenState createState() => _mainScreenState();
}

class _mainScreenState extends State<main_screen> {
  final  mqttClientWrapper = MQTTClientWrapper('public.mqtthq.com', 'mqttHQ-client-test', 1883);
  bool isSubscribed = false;
  String latestMsg = 'No messages yet';
  double weight = 0.0;
  bool leakage = false;

  triggerNotification(String msg) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Alert',
        body: msg,
        color: Colors.red,
      ),
    );
  }

  void _showAlertDialog(BuildContext context,String msg) async {

    showDialog(
      context: context,
      builder: (BuildContext context,) {
        return AlertDialog(
          backgroundColor: Colors.red.withOpacity(0.8),
          content:  Text(msg,style: TextStyle(color: Colors.white),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void toggleSubscription() {
    setState(() {
      if (isSubscribed){
        mqttClientWrapper.unsubscribe();
      }
      else{
        mqttClientWrapper.subscribe((message) {
          setState(() {
            latestMsg = message;
            if (message.startsWith('Weight: ')) {
              weight = double.parse(message.split(' ')[1]);
            } else if (message == 'Leakage: True') {
              leakage = true;
              _showAlertDialog(context,'ALERT: Gas leakage detected!');
              triggerNotification("Gas leakage detected!");
            } else if (message == 'Leakage: False') {
              leakage = false;
            }
          });
        });}
      isSubscribed = !isSubscribed;
      if (isSubscribed && !mqttClientWrapper.isConnected){
        _showAlertDialog(context, "Check your internet connection and Restart the app");
        triggerNotification("Check your internet connection and Restart the app");
    }
    });
  }

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.showAlert = () {
      _showAlertDialog(context, "Check your internet connection and Restart the app");
    };
    mqttClientWrapper.connect().then((_) {
      setState(() {
        isSubscribed = mqttClientWrapper.isSubscribed;
      });
    });
  }

  @override
  void dispose() {
    mqttClientWrapper.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MQTT Test App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              mqttClientWrapper.isConnected ? 'Connected' : 'Connecting with server...',
              style: TextStyle(
                color: mqttClientWrapper.isConnected ? Colors.green : Colors.red,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 20),
            Text('Latest Msg: $latestMsg'),
            SizedBox(height: 20),
            CircularScale(weight: weight),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: toggleSubscription,
              child: Text(isSubscribed ? 'Unsubscribe' : 'Subscribe'),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularScale extends StatelessWidget {
  final double weight;

  CircularScale({required this.weight});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200),
      painter: ScalePainter(weight),
    );
  }
}

class ScalePainter extends CustomPainter {
  final double weight;
  final double minWeight = 0;
  final double maxWeight = 25;

  ScalePainter(this.weight);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final outerCirclePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outerCirclePaint);

    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 25; i++) {
      final angle = (2 * pi * i / 25) - (pi / 2); // Adjusted angle calculation
      final tickStart = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      final tickEnd = Offset(center.dx + (radius - 10) * cos(angle), center.dy + (radius - 10) * sin(angle));
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      if (i % 5 == 0 && i !=25) {
        final textSpan = TextSpan(text: '$i', style: TextStyle(color: Colors.black, fontSize: 12));
        textPainter.text = textSpan;
        textPainter.layout();
        final xOffset = center.dx + (radius - 20) * cos(angle) - textPainter.width / 2;
        final yOffset = center.dy + (radius - 20) * sin(angle) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(xOffset, yOffset));
      }
    }

    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4;
    final needleAngle = (2 * pi * weight / maxWeight) - (pi / 2); // Adjusted needle angle calculation
    final needleEnd = Offset(center.dx + (radius - 20) * cos(needleAngle), center.dy + (radius - 20) * sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}