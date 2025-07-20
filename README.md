# DevUpper - AI-Powered Development Assistant

DevUpper is a Flutter application that serves as an AI-powered development assistant for your GitHub repositories. The app provides GitHub integration, git operations, and intelligent code analysis capabilities.

## Recent Fixes & Improvements

### 🔧 GitHub Token Authentication Issues Fixed

The following issues with GitHub token authentication have been resolved:

1. **Token Persistence**: Added `SharedPreferences` to save GitHub tokens securely
2. **Auto-login**: App now checks for saved credentials on startup
3. **Token Validation**: Validates saved tokens to ensure they're still valid
4. **Improved Error Handling**: Better error messages and user feedback

### 🎨 iOS-Style UI Improvements

Enhanced the authentication screen with:

- **Modern Input Field**: Redesigned token input with better iOS-style aesthetics
- **Paste Functionality**: Added clipboard paste button for easy token entry
- **Visual Feedback**: Added success/error states with proper colors and animations
- **Haptic Feedback**: Added tactile feedback for better user experience
- **Gradient Buttons**: Modern gradient styling for action buttons

### 📱 System UI Customization

Implemented proper system UI styling:

- **Status Bar**: Transparent status bar with proper light/dark theme support
- **Navigation Bar**: Themed system navigation bar matching app colors
- **Splash Screen**: Added loading screen while checking authentication
- **Theme Consistency**: Consistent iOS-style theming throughout the app

### 🔧 Git Operations Implementation

Added comprehensive git functionality:

- **Local Repository Management**: Clone, init, and manage local repositories
- **Git Commands**: Pull, push, commit, add, branch operations
- **Status Monitoring**: Real-time git status with file change tracking
- **Branch Management**: Create, switch, and list branches
- **Commit History**: View recent commits with author and hash information
- **Error Handling**: Proper error handling and user feedback for all operations

## Features

### Core Functionality

- **GitHub Authentication**: Secure token-based authentication with persistence
- **Repository Management**: Browse and manage your GitHub repositories
- **AI Integration**: AI-powered code analysis and suggestions
- **Git Operations**: Full local git functionality with modern UI
- **Cross-Platform**: Works on iOS and Android with platform-specific styling

### Git Operations Widget

The new `GitOperationsWidget` provides:

- Real-time git status display
- File change tracking (modified, added, deleted, untracked)
- Quick action buttons for common git operations
- Commit message input with validation
- Recent commit history display
- Branch information and switching

## Installation & Setup

1. **Prerequisites**:
   ```bash
   flutter --version  # Ensure Flutter is installed
   git --version      # Ensure Git is installed
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## GitHub Token Setup

1. Go to GitHub.com → Settings → Developer settings
2. Navigate to "Personal access tokens" → "Tokens (classic)"
3. Click "Generate new token (classic)"
4. Select the following scopes:
   - `repo` (Full repository access)
   - `user` (Read user profile)
   - `workflow` (Update workflows)
5. Copy the generated token
6. Paste it in the app's authentication screen

## Technical Architecture

### Services

- **GitHubService**: Handles GitHub API interactions and authentication
- **GitService**: Manages local git operations and repository state
- **AIService**: Processes AI-powered code analysis (existing)

### Key Files

- `lib/main.dart`: App entry point with system UI configuration
- `lib/screens/auth_screen.dart`: Enhanced authentication screen
- `lib/services/github_service.dart`: GitHub API service with persistence
- `lib/services/git_service.dart`: Local git operations service
- `lib/widgets/git_operations_widget.dart`: Git operations UI component

### Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.1.0                    # HTTP requests
  shared_preferences: ^2.2.2      # Local data persistence
  git: ^2.2.1                     # Git operations
  path: ^1.8.3                    # Path utilities
  path_provider: ^2.1.1           # File system access
  cupertino_icons: ^1.0.6         # iOS-style icons
```

## Authentication Flow

1. **App Launch**: Check for saved credentials
2. **Token Validation**: Verify saved token with GitHub API
3. **Auto-Login**: Proceed to home screen if valid
4. **Manual Login**: Show authentication screen if needed
5. **Token Storage**: Save valid tokens securely

## Git Operations Flow

1. **Repository Detection**: Check for existing local repositories
2. **Clone/Initialize**: Clone from GitHub or initialize existing repo
3. **Status Monitoring**: Real-time git status updates
4. **Operation Execution**: Execute git commands with proper error handling
5. **UI Updates**: Refresh status and provide user feedback

## Error Handling

The app includes comprehensive error handling for:

- Network connectivity issues
- Invalid GitHub tokens
- Git command failures
- File system permissions
- API rate limiting

## Security

- GitHub tokens are stored securely using `SharedPreferences`
- Tokens are validated before use
- No tokens are logged or exposed in debug output
- Proper cleanup on logout

## Platform Support

- **iOS**: Native iOS styling with proper system UI integration
- **Android**: Material Design with iOS-style customizations
- **Theme Support**: Light and dark themes with proper status bar styling

## Contributing

When contributing to this project:

1. Follow the existing code style and architecture
2. Add proper error handling for new features
3. Update documentation for any new functionality
4. Test on both iOS and Android platforms
5. Ensure proper theme support in light and dark modes

## Troubleshooting

### Common Issues

1. **"Git not found"**: Ensure Git is installed and available in PATH
2. **"Invalid token"**: Generate a new GitHub token with proper scopes
3. **"Clone failed"**: Check network connectivity and repository permissions
4. **"Authentication failed"**: Verify token hasn't expired

### Debug Mode

To enable debug logging, add debug prints in the respective service files and run:

```bash
flutter run --debug
```

## Future Enhancements

- SSH key support for git operations
- Multiple GitHub account support
- Advanced git operations (merge, rebase, cherry-pick)
- Repository analytics and insights
- Team collaboration features