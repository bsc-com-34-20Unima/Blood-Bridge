import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MandatoryLocationService {
  // Check if location is completely disabled on the device
  Future<bool> isLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  // Request and validate location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    // If denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    // Check if permission is granted
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Mandatory location check for signup
  Future<bool> validateLocationForSignup(BuildContext context) async {
    // Check if location service is enabled on device
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServiceDisabledDialog(context);
      return false;
    }

    // Request and check location permission
    bool permissionGranted = await requestLocationPermission();
    if (!permissionGranted) {
      await _showLocationPermissionDeniedDialog(context);
      return false;
    }

    // Attempt to get current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      return true;
    } catch (e) {
      await _showLocationCaptureFailedDialog(context);
      return false;
    }
  }

  // Dialog for location service disabled
  Future<void> _showLocationServiceDisabledDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text(
            'Location services are completely disabled on your device. '
            'Please enable location services in your device settings to continue.'
          ),
          actions: [
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog for location permission denied
  Future<void> _showLocationPermissionDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
            'Location access is mandatory for donors. '
            'Without location permission, you cannot sign up or log in.'
          ),
          actions: [
            TextButton(
              child: Text('Request Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.requestPermission();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog for location capture failure
  Future<void> _showLocationCaptureFailedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Capture Failed'),
          content: Text(
            'We could not capture your current location. '
            'Please ensure your device has a clear view of the sky and location services are enabled.'
          ),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}