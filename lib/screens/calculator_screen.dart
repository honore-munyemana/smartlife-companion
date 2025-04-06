import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";  // Display output
  String _input = "";    // Current input
  String _operator = ""; // Current operator
  double _num1 = 0;      // First operand
  double _num2 = 0;      // Second operand

  // Function to update the display based on button press
  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "=") {
        // If '=' is pressed, calculate the result
        _num2 = double.parse(_input);
        if (_operator == "+") {
          _output = (_num1 + _num2).toString();
        } else if (_operator == "-") {
          _output = (_num1 - _num2).toString();
        } else if (_operator == "*") {
          _output = (_num1 * _num2).toString();
        } else if (_operator == "/") {
          if (_num2 != 0) {
            _output = (_num1 / _num2).toString();
          } else {
            _output = "Error"; // Prevent division by zero
          }
        }
        _input = _output;  // Set the output to the input for further calculations
        _operator = "";  // Clear the operator
      } else if (buttonText == "C") {
        // Clear the input and reset the calculator
        _output = "0";
        _input = "";
        _num1 = 0;
        _num2 = 0;
        _operator = "";
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "*" || buttonText == "/") {
        // If an operator is pressed, set the operator and save the first operand
        if (_input.isNotEmpty) {
          _num1 = double.parse(_input);
        }
        _operator = buttonText;
        _input = "";  // Clear the input for the second operand
      } else {
        // For number buttons, append the button text to the input
        _input += buttonText;
        _output = _input;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calculator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              _output, 
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                String buttonText = '';
                switch (index) {
                  case 0:
                    buttonText = '7';
                    break;
                  case 1:
                    buttonText = '8';
                    break;
                  case 2:
                    buttonText = '9';
                    break;
                  case 3:
                    buttonText = '/';
                    break;
                  case 4:
                    buttonText = '4';
                    break;
                  case 5:
                    buttonText = '5';
                    break;
                  case 6:
                    buttonText = '6';
                    break;
                  case 7:
                    buttonText = '*';
                    break;
                  case 8:
                    buttonText = '1';
                    break;
                  case 9:
                    buttonText = '2';
                    break;
                  case 10:
                    buttonText = '3';
                    break;
                  case 11:
                    buttonText = '-';
                    break;
                  case 12:
                    buttonText = 'C';
                    break;
                  case 13:
                    buttonText = '0';
                    break;
                  case 14:
                    buttonText = '=';
                    break;
                  case 15:
                    buttonText = '+';
                    break;
                }

                return ElevatedButton(
                  onPressed: () => _buttonPressed(buttonText),
                  child: Text(buttonText, style: TextStyle(fontSize: 24)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
