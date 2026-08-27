import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {


  int counter=0;
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
            'Test Screen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: Column(
        children:
        [
          Container(
            width: double.infinity,
          ),
          Text(
            'Simple Text'
          ),

          Text(
              ' Text ${counter}'
          ),

          TextButton(
              onPressed: ()
              {
                print(counter);
              },
              child: Text(
                'Click me'
              )),


          IconButton(
              onPressed: ()
              {
                setState(() {
                  counter++;
                });
              },
              icon:Icon(
                Icons.add,
                color: Colors.blue,
              ),),
        ],
      ),
    );
  }
}
