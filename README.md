# DevUpper

DevUpper is a Flutter application that replicates Cursor AI agents functionality for mobile development. It provides an AI-powered development assistant that can understand large codebases, generate code, perform reviews, create pull requests, and much more.

## Features

### 🤖 AI Agent Capabilities
- **Think, Plan, Execute**: Function-based AI workflow that thinks about tasks, creates plans, and executes them
- **Code Generation**: Generate clean, production-ready code based on requirements
- **Code Review**: Automated code review with suggestions for improvements
- **Refactoring**: Intelligent code refactoring and optimization
- **Bug Fixing**: Identify and fix bugs with AI assistance
- **Testing**: Generate and run tests for your code
- **Documentation**: Auto-generate documentation

### 📱 Repository Management
- **GitHub Integration**: Full GitHub API integration with personal access tokens
- **Repository Browser**: Browse and manage your GitHub repositories
- **Pull Request Management**: Create, review, and merge pull requests
- **Branch Management**: Create and switch between branches
- **File Operations**: Read, write, and modify files in repositories

### 🧠 Large Codebase Understanding
- **Smart Analysis**: Analyze entire codebases without token limits
- **Pattern Recognition**: Identify architectural and design patterns
- **Dependency Mapping**: Understand project dependencies and structure
- **Code Search**: Fast and accurate code search across files
- **Language Detection**: Support for multiple programming languages

### 💬 Interactive Chat
- **AI Assistant**: Chat with the AI agent about your code
- **Context Aware**: Understands your current repository and project context
- **Suggestions**: Get intelligent suggestions for development tasks
- **Multi-turn Conversations**: Maintain conversation history and context

### 🎨 iOS-Style Design
- **Minimal Interface**: Clean, minimal design inspired by iOS
- **Smooth Animations**: Fluid transitions and interactions
- **Dark Mode Support**: Beautiful dark and light themes
- **Responsive Layout**: Works great on different screen sizes

## Technical Stack

- **Frontend**: Flutter (Dart)
- **AI Model**: Google Gemini 2.0 Flash (latest model)
- **Backend Integration**: GitHub REST API
- **Architecture**: Clean Architecture with service layers
- **State Management**: setState (for simplicity)
- **HTTP Client**: Built-in Dart HTTP package

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- GitHub Personal Access Token
- Internet connection for AI and GitHub API calls

### Installation
1. Clone this repository
2. Navigate to the project directory
3. Install dependencies (see pubspec.yaml information below)
4. Run the app

### GitHub Token Setup
1. Go to GitHub.com → Settings → Developer settings
2. Navigate to Personal access tokens → Tokens (classic)
3. Generate new token with these scopes:
   - `repo` (Full repository access)
   - `user` (Read user profile)
   - `workflow` (Update workflows)
4. Copy the token and paste it in the app

## Configuration Files

### pubspec.yaml Dependencies
```yaml
name: devupper
description: AI-powered development assistant inspired by Cursor AI agents
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client for API calls
  http: ^1.1.0
  
  # Material Design icons
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  # Add custom fonts if needed
  # fonts:
  #   - family: SF Pro Display
  #     fonts:
  #       - asset: fonts/SF-Pro-Display-Regular.otf
  #       - asset: fonts/SF-Pro-Display-Medium.otf
  #         weight: 500
  #       - asset: fonts/SF-Pro-Display-Semibold.otf
  #         weight: 600
  #       - asset: fonts/SF-Pro-Display-Bold.otf
  #         weight: 700
```

### Android Manifest Configuration
File: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Network state permission for connectivity checks -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Optional: Wake lock for background processing -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="DevUpper"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/LaunchTheme"
        android:exported="true"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- App launch intent -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- URL scheme for GitHub OAuth (if implementing OAuth later) -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="devupper" />
            </intent-filter>
        </activity>
        
        <!-- Required for Flutter embedding -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### iOS Configuration
File: `ios/Runner/Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- App name and version -->
<key>CFBundleDisplayName</key>
<string>DevUpper</string>
<key>CFBundleName</key>
<string>DevUpper</string>

<!-- URL scheme for GitHub OAuth -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>devupper.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>devupper</string>
        </array>
    </dict>
</array>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── repository.dart       # GitHub repository model
│   └── agent_task.dart       # AI task model
├── services/                 # Business logic
│   ├── ai_service.dart       # Gemini AI integration
│   ├── github_service.dart   # GitHub API integration
│   └── codebase_analyzer.dart # Code analysis engine
├── screens/                  # UI screens
│   ├── auth_screen.dart      # Authentication
│   ├── home_screen.dart      # Main dashboard
│   └── repository_screen.dart # Repository details
└── widgets/                  # Reusable UI components
    ├── repository_card.dart  # Repository display
    ├── task_card.dart        # Task status display
    └── agent_chat.dart       # AI chat interface
```

## AI Model Configuration

The app uses Google Gemini 2.0 Flash with the following configuration:
- **Model**: `gemini-2.0-flash-exp`
- **API Key**: `AIzaSyBUiSSswKvLvEK7rydCCRPF50eIDI_KOGc` (for testing)
- **Max Tokens**: 8192
- **Temperature**: 0.7
- **Function Calling**: Enabled for tool usage

### Available AI Tools
1. **analyze_codebase** - Analyze repository structure and content
2. **search_code** - Search for patterns in codebase
3. **generate_code** - Generate new code based on requirements
4. **refactor_code** - Refactor existing code
5. **review_code** - Review code for quality and issues
6. **create_pull_request** - Create GitHub pull requests
7. **run_tests** - Execute project tests

## Security Considerations

- **API Keys**: The Gemini API key is included for testing. In production, use environment variables or secure storage
- **GitHub Tokens**: Personal access tokens are stored locally and used for API authentication
- **HTTPS**: All API calls use HTTPS for secure communication
- **Permissions**: Minimal Android permissions requested

## Development Workflow

The AI agent follows Cursor AI's approach:
1. **Think**: Analyze the task and understand requirements
2. **Plan**: Create a detailed execution plan with steps
3. **Execute**: Use available tools to complete the task
4. **Report**: Provide comprehensive results and feedback

## Future Enhancements

- [ ] Real-time collaboration features
- [ ] Advanced code editor with syntax highlighting
- [ ] Git operations (commit, push, pull)
- [ ] CI/CD pipeline integration
- [ ] Plugin system for custom tools
- [ ] Offline mode for basic functionality
- [ ] Multi-language support
- [ ] Advanced analytics and insights

## Contributing

This is a demonstration project showcasing AI-powered development tools. The code is designed to be educational and extensible.

## License

This project is created for educational and demonstration purposes. The AI capabilities are powered by Google's Gemini API, and GitHub integration uses their public API.

---

**Note**: This app demonstrates the future of AI-assisted mobile development, bringing powerful coding tools to your fingertips with an intuitive, iOS-inspired interface.