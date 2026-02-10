# Habit Tracker Flutter App

A comprehensive monthly habit tracking application built with Flutter, featuring AI-powered insights and cloud synchronization.

## Features

- **Monthly Habit Tracking**: Track habits with daily check-ins across a monthly calendar view
- **Flexible Goal Setting**: Support for both daily habits and frequency-based goals (X times per month)
- **Progress Analytics**: Visual progress tracking with success rates, streaks, and monthly summaries
- **AI-Powered Insights**: Get personalized habit suggestions and progress analysis using Google Gemini AI
- **Cloud Synchronization**: Firebase Cloud Functions for data backup and sync across devices
- **Responsive Design**: Clean, modern UI that works on both mobile and tablet

## Technical Architecture

Based on the comprehensive technical specification, this app implements:

- **Double-Denominator Logic**: Distinguishes between frequency habits and daily habits
- **State-Input-Calculation Model**: Reactive state management with real-time aggregation
- **Temporal Engine**: Dynamic month/year handling with leap year support
- **Mathematical Aggregation**: Precise calculation of success rates, progress metrics, and momentum scores

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Firebase project
- Google Gemini API key (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd habit_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   
   Create a Firebase project and configure it:
   
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication (Email/Password)
   - Enable Cloud Functions
   - Download the configuration files

4. **Update Firebase Configuration**
   
   Update `lib/config/firebase_options.dart` with your Firebase project details:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'your-android-api-key',
     appId: 'your-android-app-id',
     messagingSenderId: 'your-sender-id',
     projectId: 'your-project-id',
     storageBucket: 'your-project-id.appspot.com',
   );
   ```

5. **AI Features Setup (Optional)**
   
   To enable AI insights:
   
   - Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Uncomment and update the AI service initialization in `lib/screens/ai_insights_screen.dart`:
   ```dart
   await aiService.initialize('your-gemini-api-key');
   ```

6. **Cloud Functions Setup**
   
   Deploy the required Cloud Functions (see `cloud_functions/` directory):
   ```bash
   firebase deploy --only functions
   ```

### Running the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── firebase_options.dart # Firebase configuration
├── models/
│   ├── habit.dart           # Habit data model
│   ├── habit_state.dart     # Temporal state model
│   └── daily_stats.dart     # Statistics model
├── providers/
│   └── habit_provider.dart  # State management with Provider
├── services/
│   ├── habit_service.dart   # Business logic for habits
│   ├── ai_service.dart      # Google Gemini AI integration
│   └── cloud_functions_service.dart # Firebase Cloud Functions
├── screens/
│   ├── dashboard_screen.dart # Main dashboard
│   └── ai_insights_screen.dart # AI insights interface
└── widgets/
    ├── habit_grid.dart      # Habit tracking grid
    ├── stats_card.dart      # Statistics display cards
    ├── month_selector.dart  # Month/year picker
    └── add_habit_dialog.dart # Add habit dialog
```

## Data Models

### Habit
- **ID**: Unique identifier
- **Name**: Habit description
- **Target Goal**: Monthly frequency (null for daily habits)
- **Daily Logs**: Boolean array for each day of the month
- **Progress Metrics**: Calculated progress percentages

### Habit State
- **Year/Month**: Current tracking period
- **Date Range**: Start and end dates for the month
- **Day Labels**: Weekday abbreviations for each day
- **Days Elapsed Mask**: Boolean mask for past/present days

### Daily Stats
- **Daily Totals**: Sum of completed habits per day
- **Efficiency Scores**: Daily completion percentages
- **Global Metrics**: Monthly progress, success rate, current streak

## Key Algorithms

### Progress Calculation
```dart
// For frequency-based habits
progress = totalCompletions / targetGoal

// For daily habits  
progress = totalCompletions / daysInMonth

// Capped for global aggregation
cappedProgress = min(rawProgress, 1.0)
```

### Success Rate
```dart
successRate = average(individualHabitProgressScores)
```

### Monthly Progress
```dart
monthlyProgress = totalChecks / totalGoalsDefined
```

## AI Features

The app integrates Google Gemini AI for:

1. **Progress Analysis**: Personalized insights based on habit performance
2. **Habit Suggestions**: Recommendations for new habits based on current routine
3. **Weekly Planning**: Actionable plans to improve consistency
4. **Q&A Assistant**: Answer questions about habit formation and motivation

## Cloud Functions

Required Firebase Cloud Functions:

- `syncHabitData`: Sync user data to cloud
- `loadHabitData`: Load saved data from cloud
- `getHistoricalData`: Retrieve historical tracking data
- `generateAnalytics`: Generate detailed analytics reports
- `backupData`: Create data backups
- `shareProgress`: Generate shareable progress reports

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Check the [Issues](../../issues) page
- Review the technical specification documentation
- Contact the development team

---

**Built with ❤️ using Flutter and Firebase**
