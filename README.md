# 📄 AppaPDF – Modern PDF Reader & AI Assistant

AppaPDF is a fast, modern, and visually polished **PDF reader application built with Flutter**.
It combines powerful document management with **AI-powered assistance** to create a smarter reading experience.

---

## 🚀 Features

* 📖 **Advanced PDF Reader**
  Smooth scrolling, page overview, night mode, and brightness control for comfortable reading.

* 🤖 **AI Document Assistant**
  Ask questions about your PDFs using **Google Gemini AI** (API key required).

* 📷 **Document Scanner**
  Scan physical documents and instantly convert them into PDFs.

* 🔗 **PDF Merger**
  Combine multiple PDF files into a single document.

* 📚 **Smart Library Management**
  Organize, search, and manage all your PDFs in one place.

* 🕒 **Recent Files Access**
  Quickly open recently viewed documents with pin support.

---

## 🛠 Tech Stack

| Technology                    | Purpose                     |
| ----------------------------- | --------------------------- |
| Flutter                       | Cross-platform UI framework |
| Provider                      | State management            |
| GoRouter                      | Navigation and routing      |
| Flutter Animate               | Smooth UI animations        |
| Google Generative AI (Gemini) | AI assistant                |
| flutter_pdfview               | PDF rendering               |
| pdf & printing                | PDF creation and printing   |

---

## 🎨 Design System

* 🌗 **Light & Dark Mode Support**
* 🔤 **Plus Jakarta Sans Typography**
* 🧭 **Clean Card-Based UI**
* ⚡ **Smooth Animations**

---

## 📸 Screenshots

*Add your screenshots here*

```
screenshots/
  dashboard.png
  reader.png
  ai_chat.png
```

Example:

```
![Dashboard](screenshots/dashboard.png)
![Reader](screenshots/reader.png)
```

---

## 📦 Installation

Clone the repository

```
git clone https://github.com/MdKhanBahadurSadi/appa_pdf.git
```

Navigate into the project folder

```
cd appa_pdf
```

Install dependencies

```
flutter pub get
```

Run the application

```
flutter run
```

---

## 🤖 AI Configuration

To use the AI assistant:

1. Get a **Google Gemini API key**
2. Open the AI Chat settings inside the app
3. Enter your API key

---

## ⚡ Performance & Architecture

* 🏗 **Clean Architecture**
  Decoupled services for AI, PDF tools, and document settings.

* 🚀 **Multi-threaded Processing (Isolates)**
  Heavy PDF operations like text extraction and merging are offloaded to **Dart Isolates** using `compute()`, ensuring a butter-smooth 120 FPS UI even during intensive tasks.

* 🧪 **Automated Testing**
  Core services like `RecentFilesService` and `DocumentSettingsService` are covered with comprehensive unit tests to ensure reliability and prevent regressions.

---

## 📂 Project Structure

```
lib/
  core/
  features/
  screens/
  widgets/

android/
ios/
web/
assets/
test/
```

---

## 🧪 Testing

Run unit and widget tests:

```
flutter test
```

---

## 📜 License

This project is licensed under the **MIT License**.

---

## ❤️ Author

**Md. Khan Bahadur Sadi**

Built with Flutter to create a smarter PDF reading experience.
