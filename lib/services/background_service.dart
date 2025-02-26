import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:taleem_app/common_imports.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize notifications plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Setup background service
Future<void> initializeService() async {
  print("DEBUG: Initializing background service");
  final service = FlutterBackgroundService();

  // Configure for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'taleem_timer_channel', // id
    'Taleem Timer Service', // title
    description: 'Background service for Taleem timers', // description
    importance: Importance.high,
  );

  // Initialize notifications
  print("DEBUG: Creating notification channel");
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configure the background service
  print("DEBUG: Configuring background service");
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'taleem_timer_channel',
      initialNotificationTitle: 'Taleem Timer',
      initialNotificationContent: 'Timer running in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  print("DEBUG: Background service initialization complete");
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  print("DEBUG: iOS background handler called");
  return true;
}

// Main background service handler
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("DEBUG: Background service onStart called");
  
  // This function will be executed when the background service is started
  if (service is AndroidServiceInstance) {
    print("DEBUG: Setting as foreground service");
    service.setAsForegroundService();
  }
  
  // Listen for timer events
  service.on('start_timer').listen((event) async {
    print("DEBUG: start_timer event received: $event");
    if (event == null) return;
    
    // Extract timer data
    String sessionName = event['sessionName'] ?? 'Session';
    int durationInSeconds = event['durationInSeconds'] ?? 0;
    String soundPath = event['soundPath'] ?? 'sounds/soft_beep_1.wav';
    int soundDuration = event['soundDuration'] ?? 2;
    
    print("DEBUG: Starting timer for $sessionName, duration: $durationInSeconds seconds");
    
    // Calculate end time
    DateTime endTime = DateTime.now().add(Duration(seconds: durationInSeconds));
    print("DEBUG: End time set to $endTime");
    
    // Store the end time
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_end_time', endTime.toIso8601String());
    await prefs.setString('timer_session_name', sessionName);
    await prefs.setString('timer_sound_path', soundPath);
    await prefs.setInt('timer_sound_duration', soundDuration);
    await prefs.setBool('timer_active', true);
    print("DEBUG: Timer data stored in SharedPreferences");
    
    // Start checking the timer
    Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        prefs = await SharedPreferences.getInstance();
        bool isActive = prefs.getBool('timer_active') ?? false;
        
        if (!isActive) {
          print("DEBUG: Timer marked as inactive, canceling check");
          timer.cancel();
          return;
        }
        
        String? endTimeString = prefs.getString('timer_end_time');
        if (endTimeString == null) {
          print("DEBUG: No end time found, canceling check");
          timer.cancel();
          return;
        }
        
        DateTime storedEndTime = DateTime.parse(endTimeString);
        DateTime now = DateTime.now();
        
        // Update notification with remaining time
        int remaining = storedEndTime.difference(now).inSeconds;
        
        if (remaining % 10 == 0) {  // Only log every 10 seconds to reduce spam
          print("DEBUG: Timer check - $remaining seconds remaining");
        }
        
        if (remaining > 0) {
          // Format remaining time
          int minutes = remaining ~/ 60;
          int seconds = remaining % 60;
          String timeString = 
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          
          // Update notification for Android service
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: sessionName,
              content: 'Time remaining: $timeString',
            );
          }
        } else {
          // Timer is complete - play sound and show notification
          print("DEBUG: Timer completed for $sessionName!");
          timer.cancel();
          
          // Mark timer as inactive
          await prefs.setBool('timer_active', false);
          print("DEBUG: Timer marked inactive in SharedPreferences");
          
          // Show completion notification
          print("DEBUG: Showing completion notification");
          flutterLocalNotificationsPlugin.show(
            999,
            'Session Completed',
            '$sessionName has ended',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'taleem_timer_channel',
                'Taleem Timer Service',
                channelDescription: 'Background service for Taleem timers',
                importance: Importance.high,
                priority: Priority.high,
                playSound: false,
              ),
            ),
          );
          
          // Play completion sound
          print("DEBUG: Attempting to play sound: $soundPath");
          try {
            AudioPlayer player = AudioPlayer();
            await player.setReleaseMode(ReleaseMode.stop);
            await player.play(AssetSource(soundPath));
            print("DEBUG: Sound playback started");
            
            // Schedule to stop sound
            Timer(Duration(seconds: soundDuration), () async {
              print("DEBUG: Stopping sound playback");
              await player.stop();
              await player.dispose();
              print("DEBUG: Sound player disposed");
            });
          } catch (e) {
            print("DEBUG: Error playing sound: $e");
          }
          
          // Send completion event to app
          print("DEBUG: Sending timer_completed event to app");
          service.invoke('timer_completed', {
            'sessionName': sessionName,
          });
        }
      } catch (e) {
        print("DEBUG: Error in timer check: $e");
      }
    });
  });
  
  service.on('stop_timer').listen((event) async {
    print("DEBUG: stop_timer event received");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_active', false);
    print("DEBUG: Timer marked as inactive");
  });
  
  service.on('pause_timer').listen((event) async {
    print("DEBUG: pause_timer event received");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? endTimeString = prefs.getString('timer_end_time');
    
    if (endTimeString != null) {
      DateTime endTime = DateTime.parse(endTimeString);
      int remainingSeconds = endTime.difference(DateTime.now()).inSeconds;
      
      if (remainingSeconds > 0) {
        print("DEBUG: Pausing timer with $remainingSeconds seconds remaining");
        // Store remaining seconds instead of end time
        await prefs.setInt('timer_remaining_seconds', remainingSeconds);
        await prefs.setBool('timer_paused', true);
        print("DEBUG: Timer paused state saved");
      }
    }
  });
  
  service.on('resume_timer').listen((event) async {
    print("DEBUG: resume_timer event received");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int remainingSeconds = prefs.getInt('timer_remaining_seconds') ?? 0;
    
    if (remainingSeconds > 0) {
      print("DEBUG: Resuming timer with $remainingSeconds seconds");
      // Calculate new end time
      DateTime newEndTime = DateTime.now().add(Duration(seconds: remainingSeconds));
      await prefs.setString('timer_end_time', newEndTime.toIso8601String());
      await prefs.setBool('timer_paused', false);
      print("DEBUG: Timer resumed, new end time: $newEndTime");
    }
  });
}
