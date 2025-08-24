# RelayExample

A comprehensive macOS SwiftUI example application demonstrating the Relay SDK's capabilities for ChatGPT integration. This example showcases a full-featured chat interface with conversation history, model selection, and real-time streaming responses.

## 🚀 Features

- **Real-time Chat Interface**: Full conversation experience with streaming AI responses
- **Conversation History**: Browse and load previous conversations from your ChatGPT account
- **Model Selection**: Choose from available AI models (GPT-4, GPT-3.5, etc.)
- **Markdown Rendering**: AI responses are beautifully rendered with MarkdownUI
- **Authentication Management**: Seamless authentication with ChatGPT
- **Debug Mode**: Toggle debug view to see the underlying WebView
- **Responsive UI**: Modern SwiftUI interface with proper window sizing

## 📋 Prerequisites

- macOS 12.0+
- Xcode 15.0+
- Swift 6.0+
- A valid Relay API key (contact the library maintainer to obtain one)

## 🛠️ Setup & Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd relay-work/RelayExample
```

### 2. Open in Xcode

```bash
open RelayExample.xcodeproj
```

### 3. Configure API Key

The example uses a hardcoded API key for demonstration. In a production app, you should store this securely:

```swift
// In RelayExampleView.swift, line ~200
openAIClient = Relay.OpenAI(apiKey: "your-relay-api-key-here", autoInitialize: true)
```

### 4. Build and Run

- Select the `RelayExample` target
- Press `Cmd+R` to build and run

## 🎯 Usage

### First Launch

1. **Authentication**: Click "Authenticate" to sign in to your ChatGPT account
2. **Model Selection**: Choose your preferred AI model from the dropdown
3. **Start Chatting**: Begin a new conversation or load from history

### Key Features

#### Conversation Management

- **New Chat**: Start fresh conversations
- **History**: Browse and load previous conversations
- **Auto-sync**: Conversations are automatically saved and synced

#### Model Selection

- **Auto**: Let ChatGPT choose the best model
- **GPT-4**: Latest GPT-4 models for advanced reasoning
- **GPT-3.5**: Faster, more cost-effective models

#### Debug Features

- **Debug View**: Toggle to see the underlying WebView
- **Console Logging**: Detailed logs for development

## 🏗️ Architecture

### Main Components

#### `RelayExampleView.swift`

The main view controller that orchestrates the entire application:

- **State Management**: Handles authentication, models, and conversations
- **UI Layout**: Split view with conversation history and chat area
- **API Integration**: Manages all Relay SDK interactions

#### `ConversationDetailView.swift`

Renders individual conversations with:

- **Message Display**: User and AI messages with proper styling
- **Markdown Rendering**: AI responses rendered with MarkdownUI
- **Real-time Updates**: Streaming response handling

#### `MessageBubble.swift`

Individual message components with:

- **User Messages**: Plain text with blue styling
- **AI Messages**: Markdown-rendered with syntax highlighting
- **Code Blocks**: Properly formatted code with monospace fonts

### Data Models

```swift
struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct Conversation: Identifiable {
    let id = UUID()
    var title: String = "New Conversation"
    var messages: [Message] = []
    var conversationId: String?
}
```

## 🔧 Dependencies

- **Relay.framework**: The main SDK (embedded in the project)
- **MarkdownUI**: For rendering AI responses with markdown
- **SwiftUI**: Modern UI framework

## 📱 UI/UX Features

### Layout

- **Split View**: Conversation history (left) and chat area (right)
- **Responsive Design**: Minimum window size of 1000x700
- **Modern Styling**: Native macOS appearance

### Interactions

- **Real-time Typing**: Live message input with multi-line support
- **Auto-scroll**: Messages automatically scroll to bottom
- **Loading States**: Visual feedback during AI processing
- **Error Handling**: Graceful error states and recovery

## 🚨 Troubleshooting

### Common Issues

#### Authentication Problems

- Ensure you have a valid Relay API key
- Check internet connectivity
- Verify ChatGPT account credentials

#### Build Errors

- Ensure Xcode 15.0+ is installed
- Clean build folder (`Cmd+Shift+K`)
- Check that Relay.framework is properly embedded

#### Runtime Issues

- Check console logs for detailed error messages
- Verify API key is correctly configured
- Ensure macOS 12.0+ compatibility

### Debugging

- Enable debug view to see WebView
- Check console for detailed logs
- Use Xcode's debugging tools

## 🤝 Contributing

This example demonstrates best practices for using the Relay SDK. When contributing:

1. Follow the existing code style
2. Add proper error handling
3. Include documentation for new features
4. Test thoroughly on different macOS versions

## 📞 Support

For issues with this example or the Relay SDK:

- Check the main project documentation
- Review console logs for error details
- Contact the project maintainers
