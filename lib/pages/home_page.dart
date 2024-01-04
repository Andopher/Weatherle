// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/weather.dart';
import 'package:weatherle0/consts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);

  List<String> cities = [
    "New York",
    "Tokyo",
    "London",
  ];

  String selectedCity = "";
  bool isGameEnded = false;
  bool isCongratulationsScreen = false;

  Weather? _weather;

  TextEditingController _userGuessController = TextEditingController();

  CountdownTimerController? _timerController;
  DateTime? _resumeTime;

  @override
  void initState() {
    super.initState();

    // Lock the orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Adding a delay of 1 second (1000 milliseconds) before fetching and loading the data
    Future.delayed(Duration(seconds: 1), () {
      _selectRandomCity();
    });
  }

  void _selectRandomCity() {
    final random = Random();
    selectedCity = cities[random.nextInt(cities.length)];
    _wf.currentWeatherByCityName(selectedCity).then((w) {
      setState(() {
        _weather = w;
      });
    });

    // Set the resume time for the next 6:00 AM
    _resumeTime = _next6AM();
    _startTimer();
  }

  DateTime _next6AM() {
    final now = DateTime.now();
    final next6AM = DateTime(now.year, now.month, now.day, 6, 0);

    if (now.isAfter(next6AM)) {
      return next6AM.add(
          Duration(days: 1)); // If it's already past 6 AM, set for the next day
    } else {
      return next6AM;
    }
  }

  void _checkGuess(String guess) {
    if (isGameEnded) {
      return;
    }

    if (guess.toLowerCase() == selectedCity.toLowerCase()) {
      // Correct guess
      setState(() {
        isGameEnded = true;
        isCongratulationsScreen = true;
        _resumeTime = _next6AM();
        _startTimer();
      });
    } else {
      // Incorrect guess
      _showResultDialog("Incorrect! Try again.");
    }
  }

  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Game Result"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isGameEnded) {
                  // Restart the game
                  setState(() {
                    isGameEnded = false;
                    isCongratulationsScreen = false;
                  });
                  _selectRandomCity();
                }
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    if (_timerController != null) {
      _timerController!.dispose();
    }

    final now = DateTime.now();
    _resumeTime = _next6AM();

    _timerController = CountdownTimerController(
      endTime: _resumeTime!.millisecondsSinceEpoch,
    );

    _timerController!.addListener(() {
      if (_timerController!.currentRemainingTime == Duration()) {
        setState(() {
          isCongratulationsScreen = false;
        });
        _selectRandomCity();
      }
    });
  }

  @override
  void dispose() {
    // Allow all orientations when the widget is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _timerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCongratulationsScreen
          ? _buildCongratulationsScreen()
          : SingleChildScrollView(
              child: _buildUI(),
            ),
    );
  }

  Widget _buildCongratulationsScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Congratulations!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            "Tomorrow's WeatherGuess is at",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          CountdownTimer(
            endTime: _resumeTime!.millisecondsSinceEpoch,
            textStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            onEnd: () {
              // Handle the end of the timer
            },
            widgetBuilder: (context, time) {
              // Ensure hours and minutes are displayed as 00 when there are no hours or minutes left
              final hours = time?.hours ?? 0;
              final minutes = time?.min ?? 0;
              final seconds = time?.sec ?? 0;

              return Text(
                '${hours < 10 ? '0$hours' : hours}:${minutes < 10 ? '0$minutes' : minutes}:${seconds < 10 ? '0$seconds' : seconds}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _guessHeader(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.05,
          ),
          _weatherIcon(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          _currentTemp(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          _extraInfo(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          _guessInput(),
        ],
      ),
    );
  }

  Widget _guessHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Can you guess the city?",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Text(
          isGameEnded ? selectedCity : "",
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _weatherIcon() {
    String animationAsset;

    // Check if temperature is below zero and it's rainy
    if ((_weather?.temperature?.celsius ?? 0) < 0 &&
        ['rain', 'drizzle', 'shower rain'].contains(
          _weather?.weatherMain?.toLowerCase(),
        )) {
      animationAsset = 'assets/snowy.json';
    } else {
      switch (_weather?.weatherMain?.toLowerCase()) {
        case 'clouds':
          animationAsset = 'assets/cloudy.json';
          break;
        case 'mist':
        case 'smoke':
        case 'haze':
        case 'dust':
        case 'fog':
          animationAsset = 'assets/misty.json';
          break;
        case 'rain':
        case 'drizzle':
        case 'shower rain':
          animationAsset = 'assets/rainy.json';
          break;
        case 'thunderstorm':
          animationAsset = 'assets/sunnyThunderstorm.json';
          break;
        case 'clear':
          animationAsset = 'assets/sunny.json';
          break;
        default:
          animationAsset = 'assets/sunny.json';
      }
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.20,
            width: MediaQuery.of(context).size.width * 0.20,
            alignment: Alignment.centerLeft, // Adjust the alignment to the left
            child: Lottie.asset(
              animationAsset,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _weather?.weatherDescription ?? "",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0)}° C",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 90,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _extraInfo() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width * 0.80,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      padding: const EdgeInsets.all(
        8.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Max: ${_weather?.tempMax?.celsius?.toStringAsFixed(0)}° C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                "Min: ${_weather?.tempMin?.celsius?.toStringAsFixed(0)}° C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Wind: ${_weather?.windSpeed?.toStringAsFixed(0)}m/s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                "Humidity: ${_weather?.humidity?.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _guessInput() {
    return isGameEnded
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                TextFormField(
                  controller: _userGuessController,
                  onChanged: (value) {
                    // Handle user's guess
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your guess",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Check the user's guess
                    _checkGuess(_userGuessController.text);
                  },
                  child: Text("Submit"),
                ),
              ],
            ),
          );
  }
}
