# Mobile App

This repository contains a Flutter mobile application targeting Android, iOS, web, macOS, Linux, and Windows. The app follows a clean layered architecture to promote separation of concerns, testability, and scalability.

## Key Features

- **Authentication flow**: login, logout, user profile handling
- **State management** via controllers (GetX or similar)
- **Network communication** using Dio with repository pattern
- **Local persistence** (secure storage, shared preferences)
- **Routing** configured with GoRouter
- **Modular UI** with reusable widgets and screen-based navigation

## Project Structure

```
lib/
├── main.dart                  # Application entry point & bootstrap
├── models/                    # Data classes (User, Product, etc.)
├── services/                  # Low-level utilities (Dio client, Storage service)
├── repositories/              # API definitions (AuthRepository, DataRepository)
├── controllers/               # State management classes (AuthController, HomeController)
├── router/                    # GoRouter configuration and navigation helpers
└── ui/                        # All visual elements
    ├── widgets/               # Reusable components (NavBar, Buttons, FormFields)
    └── screens/               # Full pages (LoginScreen, ProfileScreen, HomeScreen)
```

## Getting Started

1. **Prerequisites**
   - Flutter SDK (>=3.0.0)
   - Dart SDK (bundled with Flutter)
   - Android Studio / Xcode (for mobile builds)

2. **Clone the repository**
   ```bash
   git clone https://github.com/nctk17uit/tiem-nha-nong.git
   cd your-repo/mobile
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configuration**

Sensitive settings (API URLs, keys) are kept out of source control using an environment file. Follow these steps after cloning:

- Copy the example file:
  ```bash
  cp .env.example .env
  ```
- Edit `.env` and replace the placeholder URL with your real API base URL, e.g.:
  ```env
  API_BASE_URL=https://api.example.com
  ```
- The app loads these via `flutter_dotenv` (see `lib/services/config.dart`).

> `.env` is listed in `.gitignore`, so when you push to GitHub it will not include your configuration. Any collaborator who pulls the repo must create their own `.env` and supply the appropriate values.

For more complex setups you can also use Flutter flavors or build-time Dart defines.
5. **Run the app**
   ```bash
   flutter run
   ```
   or specify a device:
   ```bash
   flutter run -d chrome   # web
   flutter run -d emulator-5554  # android emulator
   ```

## Testing

Unit and widget tests can be run with:
```bash
flutter test
```
Add more tests under the `test/` directory as needed.

## Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/foo`)
3. Commit your changes (`git commit -am 'Add some foo'`)
4. Push to the branch (`git push origin feature/foo`)
5. Open a pull request

Please follow the code style and add tests for new functionality.

## License

This project is provided as-is for learning purposes.  
Feel free to adapt or extend it under your own terms.