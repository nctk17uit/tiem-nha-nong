<img width="293" height="634" alt="image" src="https://github.com/user-attachments/assets/76730d18-66e8-43b9-a12f-b68d54f7012d" /># Mobile App

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

## ScreenShot
1. Login Screen
<img width="293" height="634" alt="image" src="https://github.com/user-attachments/assets/10acbcfd-159f-4f2b-8f48-48bcc6dbf7d0" />
2. Home Page
<img width="269" height="573" alt="image" src="https://github.com/user-attachments/assets/4ca108a8-5636-49a4-88f7-aebd9e1c8ca8" />
<img width="271" height="582" alt="image" src="https://github.com/user-attachments/assets/f5fe5901-6042-4d30-9a13-ab253972a584" />
3. Category Screen
<img width="238" height="511" alt="image" src="https://github.com/user-attachments/assets/92bbeef6-21bd-4aed-9d44-b3fa501a361e" />
<img width="238" height="507" alt="image" src="https://github.com/user-attachments/assets/8c1f252e-8970-44c4-88db-992ea6d9973b" />
4. Product Detail
<img width="300" height="640" alt="image" src="https://github.com/user-attachments/assets/d37b55f1-eec3-4dc8-9612-203db835a398" />
5. Cart/CartList
<img width="257" height="550" alt="image" src="https://github.com/user-attachments/assets/9b569ce8-439a-4090-85c0-dc91943a4507" />
<img width="258" height="553" alt="image" src="https://github.com/user-attachments/assets/efd39517-bf03-4171-ba12-345a00685012" />
<img width="274" height="514" alt="image" src="https://github.com/user-attachments/assets/7086b770-5230-45b9-8493-4aabe99311bc" />
<img width="275" height="513" alt="image" src="https://github.com/user-attachments/assets/1977fb82-7a05-49d8-838c-f01a62ef599e" />
6. Checkout
<img width="259" height="550" alt="image" src="https://github.com/user-attachments/assets/7b504674-5257-44df-8ff5-b8cae3ca1ee3" />
<img width="259" height="551" alt="image" src="https://github.com/user-attachments/assets/e05651e6-f728-4661-923e-bb2a7d191812" />
<img width="288" height="613" alt="image" src="https://github.com/user-attachments/assets/2d2f4c92-526d-44dc-b168-9ca324280591" />

7. Profile
<img width="270" height="578" alt="image" src="https://github.com/user-attachments/assets/49f29da5-78fd-46bc-8a19-5b01a04505b4" />
<img width="274" height="581" alt="image" src="https://github.com/user-attachments/assets/eabd62c4-ef2b-4941-9433-69ee6e7dfb9e" />
8. Support Chat
<img width="287" height="615" alt="image" src="https://github.com/user-attachments/assets/018c92c5-bb1b-4057-b04e-df1c9c72bdb2" />
<img width="287" height="614" alt="image" src="https://github.com/user-attachments/assets/9cd41d6b-76cf-451f-a740-1d021e1e3888" />
<img width="276" height="590" alt="image" src="https://github.com/user-attachments/assets/72b69c70-43a1-420b-8895-e3222a873747" />
<img width="278" height="590" alt="image" src="https://github.com/user-attachments/assets/cedeca89-ef77-4d44-9768-7b41f0bffd1b" />
8. News Screen (In progress)
<img width="289" height="620" alt="image" src="https://github.com/user-attachments/assets/c8d1d9ea-111d-4b86-bdd4-4ef646f9bd4a" />

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
