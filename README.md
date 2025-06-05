# SmartLife Companion 🌍📱

**SmartLife Companion** is a modern and feature-rich Flutter mobile app built to showcase advanced capabilities in personal productivity, health tracking, geolocation, and user customization. Originally developed as a class project, it has grown into a versatile tool and a portfolio highlight.

## ✨ Features

- 🔐 **Firebase Authentication** – Sign in with Google, register, and logout securely.

- 🧮 **Smart Calculator** – Perform basic arithmetic calculations.

- 📊 **Dashboard Screen** – View activity summary and toggle light/dark themes.

- 🏃‍♂️ **Step & Distance Tracker** – Track walking steps and total distance moved with real-time notifications.

- 📍 **Geofencing** – Receive alerts when leaving a custom defined area (e.g., your Home).

- 🗺️ **Interactive Map** – Display current location and set a personalized Home location.

- 🧾 **Product Posting Screen** – Create product entries with images – ideal for small-scale sellers or listings.

- 👤 **User Profile Editing** – Edit avatar, email, and name within the app.

- 🌗 **Theme Switching** – Persistent light and dark theme options.

- 📇 **Contact Integration** – Access and interact with phone contacts.

## 🧰 Tech Stack

- **Flutter & Dart**

- **Firebase Authentication & Notifications**

- **Google Maps & Geolocator**

- **Geofencing Plugin**

- **SQLite for local storage**

- **Device Sensors & Permissions**

- **Shared Preferences**

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/honore-munyemana/smartlife-companion.git
cd smartlife-companion
```
### 2. Install dependencies
```bash
flutter pub get
```
### 3. Run the app
```bash
flutter run
```
## 🔐 Permissions Required

📍 Location (foreground & background)

📷 Camera & Gallery

📇 Contacts

## 📁 Project Structure

lib/

├── main.dart                         # App entry point


├── helpers/                          # Utility and UI helpers

│   ├── notification_helper.dart

│   └── theme_helper.dart


├── models/                           # Data models

│   └── product.dart


├── screens/                          # All app screens

│   ├── add_product_screen.dart

│   ├── calculator_screen.dart

│   ├── contacts_screen.dart

│   ├── dashboard_screen.dart

│   ├── home_screen.dart

│   ├── light_monitor_screen.dart

│   ├── myhome_map_screen.dart

│   ├── product_list_screen.dart

│   ├── profile_screen.dart

│   ├── signin_screen.dart

│   └── signup_screen.dart



├── service/                          # Core service (singular folder, might be legacy)

│   └── auth_service.dart


├── services/                         # All integrated device and data services

│   ├── auth_service.dart

│   ├── battery_service.dart

│   ├── bluetooth_service.dart

│   ├── connectivity_service.dart

│   ├── database_helper.dart

│   ├── geofence_service.dart

│   ├── motion_service.dart

│   ├── sensor_service.dart

│   └── shake_detector_service.dart

## ✅ Explanation:

helpers/: Contains reusable utility functions or UI logic (like notifications and theming).

models/: Defines app data structures.

screens/: All UI screens for navigation and user interaction.

service/: Contains an auth_service.dart file (possibly moved to services/ now).

services/: Device and system integrations, such as battery, Bluetooth, geolocation, sensors, etc.

main.dart: Entry point of your Flutter app.


## 👨‍💻 Author

Honore Munyemana

Information Management Student

📧 honoremushya@gmail.com

🔗 https://www.linkedin.com/in/honore-?lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_view_base_contact_details%3BuytplIQyQoSkcbw9Pi2RxA%3D%3D

## 📜 License

This project is licensed under the MIT License.
