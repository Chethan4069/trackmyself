# TrackMySelf — Personal Wellness, Habits, Calendar & Warranty Tracker 🚀

![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Database](https://img.shields.io/badge/Database-Drift%20(SQLite)-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![State Management](https://img.shields.io/badge/State-Riverpod-38BDF8?style=for-the-badge)

**TrackMySelf** is an offline-first, privacy-focused personal self-management application that unifies daily fitness & nutrition logging, habit building, event scheduling, and purchase warranty management into an executive dashboard.

---

## 🌟 Key Features

### 1. 🏠 Executive Home Dashboard
- **Scenic Mountain Sunrise Header**: Personalized time-based greetings (*"Good Morning, Chethan!"*), daily inspiration, and live date badge.
- **Your Fitness Overview**: Real-time BMI (with color-coded health badges), Basal Metabolic Rate (BMR), Daily Target Calories, and personal vitals strip (Age, Height, Weight, Activity level).
- **Quick Action Grid**: One-tap shortcuts to log Fitness, Habits, Events, Purchases, or Warranties.
- **Panoramic Motivational Card**: Uncropped inspirational visual quote.
- **Daily Fitness Tip**: Contextual wellness and hydration advice with interactive check-off feedback.

### 2. 🏋️ Fitness, Nutrition & Progress Photos
- **Daily Food Log**: Meal categorization (Breakfast, Lunch, Snacks, Dinner) with real-time calorie calculation.
- **Exercise Tracking**: Duration, intensity levels, and estimated calories burned.
- **Adaptive Recommendation Engine**: Contextual exercise suggestions based on daily calorie targets and remaining activity minutes.
- **📸 Progress Photos ("Same You, Stronger Every Day")**:
  - Photo timeline with weight logs (`kg`) and dates.
  - Interactive Camera / Photo Gallery capture via `image_picker`.
  - Dynamic weight change badge (e.g. `↓ -3.8 kg since first photo`).
  - Side-by-side comparative photo slider with date selectors.

### 3. 📋 Daily Routines, Habits & Streaks
- **Custom Habit Schedules**: Daily, Weekdays, Weekends, or specific days of the week.
- **Streak Calculation Engine**: Preserves active streaks over rest days and tracks 30-day consistency rates.
- **Tactile Haptic Feedback**: Satisfying physical tap feedback on completion checkboxes.
- **100% Celebration Banner**: Celebratory milestone card when all scheduled habits for the day are finished.
- **Local Notifications**: Automated background daily habit reminders.

### 4. 📅 Calendar & Agenda Management
- **Monthly Interactive Calendar**: Month grid with multi-event dot indicators.
- **Chronological Agenda**: Filtered agenda card list for any selected date.
- **Scheduled Reminders**: Pre-event notifications (exact time, 15m, 30m, 1h, or 1d prior).

### 5. 🛡️ Memory, Purchases & Warranty Tracker
- **Purchase Log**: Track products, categories, stores, prices, and purchase dates.
- **Automated Warranty Computation**: Dynamic status badges (🟢 Active, 🟠 Expiring Soon ≤ 30 days, 🔴 Expired).
- **7-Day Expiry Notifications**: Automated scheduled alerts 7 days prior to warranty expiration.
- **Receipt Photo Attachment**: Capture and store receipts with an interactive pinch-to-zoom viewer.

### 6. 🔒 Offline Authentication & Multi-User Isolation
- Secure offline account registration and login powered by deterministic SHA-256 password hashing.
- **Strict Data Isolation**: Every piece of data is partitioned by user ID (`userId`).
- Single-time onboarding workflow ensuring returning users launch directly into their personal dashboard.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK 3.13+) |
| **State Management** | Flutter Riverpod (`Notifier`, `AsyncNotifier`, `StreamProvider`) |
| **Local Database** | Drift (SQLite ORM) with relational tables, foreign keys & DAOs |
| **Navigation** | go_router with stateful shell routes |
| **Local Notifications** | `flutter_local_notifications` with Android Notification Channels & exact alarms |
| **Media & Images** | `image_picker` + local persistent document storage |
| **Design System** | Material 3 with Google Fonts (Inter) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.47.2 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK 21+ (Android 5.0 Lollipop or newer)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Chethan4069/trackmyself.git
   cd trackmyself
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run database code generation** (if needed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

5. **Run test suite**:
   ```bash
   flutter test
   ```

6. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Test Suite

TrackMySelf comes with 52 automated tests covering:
- BMI, BMR, TDEE, and daily calorie target calculators
- Multi-user data isolation across Food, Exercises, Routines, Events, and Purchases
- Habit streak algorithms and 30-day consistency calculations
- Warranty status computations and expiration notification triggers
- Progress photo weight delta tracking

---

## 📄 License
This project is licensed under the MIT License.
