# Project Overview
This project is a Flutter library that improves the existing Flutter Dialog widget.
There are key limitations to the current Dialog widget that this library aims to address, including:
- Limited flow control due to using `showDialog` and `Navigator.pop` for dialog management.
  - Many bugs arise from this approach, such as `BuildContext` used after being disposed
  - Difficulty in managing multiple dialogs, especially when they are stacked or need to be dismissed in a specific order.
  - Lack of prioritization for dialogs, making it hard to control which dialog should be displayed first.
  - Lack of scoping dialogs to specific parts of the widget tree, leading to potential conflicts and unexpected behavior.

This library provides a more robust solution for dialog management using a MVVM (Model-View-ViewModel) architecture, allowing for better flow control, prioritization, and scoping of dialogs within the widget tree.

## Tech Stack
- Flutter
- Dart
- FVM (Flutter Version Management)
- GitHub Actions for CI/CD
- Pub.dev for package distribution
- GitHub Release for versioning and release management

Since this is a Flutter library, it must follow semantic versioning to ensure compatibility with other Flutter projects. The library will be published on pub.dev, making it easily accessible for developers to integrate into their applications.

## Coding Guidelines
- Follow the official Dart and Flutter style guides.
- Following the MVVM architecture pattern is mandatory for all code contributions.
- Unit and Widget tests are required for all new features and bug fixes.
- An example application demonstrating the library's usage should be included in the repository.
  - Any new features or breaking changes must be reflected in the example application.
- All public classes, methods, and properties must have clear and concise documentation comments.
  - All doc comments should be written in English using Dart doc format.
  - Use descriptive names for classes, methods, and variables to enhance code readability.
  - Avoid using magic numbers or hard-coded values; instead, use constants or enums where appropriate.
  - Ensure that the code is modular and reusable, promoting separation of concerns and maintainability.
  - Use dependency injection where appropriate to enhance testability and flexibility of the codebase.
- No dependency on third-party libraries is allowed unless it is absolutely necessary and approved by the maintainers.
  - Typical Dart and Flutter libraries are allowed, but any external dependencies must be justified and reviewed.