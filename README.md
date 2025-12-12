## Project structure

```
lib/
├── main.dart                  # Entry point
├── models/                    # Data classes (User)
├── services/                  # Low-level tools (Dio, Storage)
├── repositories/              # API definitions (AuthRepository)
├── controllers/               # State Management (AuthController)
├── router/                    # GoRouter configuration
└── ui/                        # All visual elements
    ├── widgets/               # Reusable components (NavBar)
    └── screens/               # Full pages (Login, Profile, Home)
```
