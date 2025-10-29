# flashcard_app
# Flutter Flashcard Application

A mobile application built with Flutter designed to help users create, manage, and study flashcards effectively across various subjects.

## Overview

This application provides a user-friendly interface for creating personalized decks of flashcards. Users can add question-and-answer pairs to each deck, edit or delete existing cards, and utilize a dedicated quiz mode to test their knowledge. The app includes several pre-loaded decks with examples to demonstrate functionality and provide immediate value. All user-created data is persistently stored locally on the device.

## Key Features

* **Deck Management:** Create, rename, and delete custom flashcard decks.
* **Card Management:** Add, edit, and delete individual flashcards (question/answer pairs) within each deck.
* **Quiz Mode:**
    * Review cards one by one in a shuffled order.
    * Reveal answers with a button press and card flip animation.
    * Navigate between cards using "Previous" and "Next" buttons.
    * Track progress through the deck with a visual progress bar.
* **Local Data Persistence:** All decks and flashcards are saved directly on the user's device using `shared_preferences`, ensuring data is retained between app sessions.
* **Default Content:** Includes several pre-loaded decks (e.g., General Knowledge, Flutter Basics, Science, Geography) loaded from a local JSON file on first launch.
* **Clean UI:** Utilizes Material 3 design principles for a modern and intuitive user experience.

## Technologies Used

* **Framework:** Flutter
* **Language:** Dart
* **State Management:** `setState` (within StatefulWidget)
* **Local Storage:** `shared_preferences` package
* **Asset Management:** Loading default data from a local JSON file.

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

* Flutter SDK installed ([Installation Guide](https://flutter.dev/docs/get-started/install))
* Dart SDK (comes with Flutter)
* An IDE such as Android Studio or Visual Studio Code with Flutter plugins installed.
* An Android device or emulator configured for development.

### Installation & Execution

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/nadakudhiti8srujana/flashcard_app.git](https://github.com/nadakudhiti8srujana/flashcard_app.git)
    cd flashcard_app
    ```
    *(Ensure the URL matches your repository)*

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    Ensure a device is connected or an emulator is running, then execute:
    ```bash
    flutter run
    ```

## Project Structure

* `lib/main.dart`: Contains the primary Dart code, including data models (`Deck`, `Flashcard`), data persistence logic (`DataService`), and UI screens (`DeckListScreen`, `CardListScreen`, `QuizScreen`).
* `assets/flashcards.json`: Stores the default decks and cards loaded on the first app launch.
* `pubspec.yaml`: Defines project metadata, dependencies (`shared_preferences`), and asset declarations.
* `android/`: Contains Android-specific configuration files (including `build.gradle` files adjusted for compatibility).

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check [issues page](https://github.com/nadakudhiti8srujana/flashcard_app/issues) if you want to contribute. *(Adjust URL if needed)*

*(Optional: Add license information here)*

---

*Developed with Flutter.*
