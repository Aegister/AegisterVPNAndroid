# AEGISTER VPN - Flutter OpenVPN Client

This project is a simple Flutter-based VPN app that allows users to connect to a VPN.

## Features

- Connect and disconnect from a VPN using a toggle button
- Displays VPN connection status and data transferred

## Requirements

Before building the APK, ensure that you have the following set up:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- Android Studio
- An Android device or emulator (for testing)

## Getting Started

Follow these steps to build your own APK with your custom VPN configuration.

### Step 1: Clone the Repository

```bash
git clone https://github.com/Aegister/AegisterVPNAndroid.git
cd aegisterVPNAndroid
 ```

### Step 2: Build the APK

Now, you're ready to build your APK. Run the following commands to build the release APK:

```bash
flutter clean
flutter pub get
flutter build apk 
```

After the build is complete, your APK will be located in the following path:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for more details.


