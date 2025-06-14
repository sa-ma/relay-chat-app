import SwiftUI
import Relay
import MarkdownUI

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

// Simplified handler for conversation completion
class ExampleStreamHandler: ConversationStreamHandler {
    let onCompletedCallback: (ConversationDetailResponse) -> Void
    let onErrorCallback: (Error) -> Void
    
    init(onComplete: @escaping (ConversationDetailResponse) -> Void, 
         onError: @escaping (Error) -> Void) {
        self.onCompletedCallback = onComplete
        self.onErrorCallback = onError
    }
    
    func onConversationComplete(_ conversation: ConversationDetailResponse) {
        print("🎯 Received complete conversation:")
        print("  - Title: \(conversation.title)")
        print("  - Messages: \(conversation.messages.count)")
        
        // Send the complete conversation data to the callback
        onCompletedCallback(conversation)
    }
    
    func onError(_ error: Error) {
        print("Handler error: \(error)")
        onErrorCallback(error)
    }
}

struct RelayExampleView: View {
    @State private var currentMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var openAIClient: OpenAIClient?
    @State private var errorMessage: String?
    
    // Model State
    @State private var availableModels: [ModelItem] = []
    @State private var selectedModel: String = "auto"
    @State private var isAuthenticated: Bool = false
    @State private var isDebugView: Bool = false
    
    // Remote History State
    @State private var conversationHistory: [ConversationItem] = []
    @State private var selectedConversationItem: ConversationItem?
    @State private var currentConversation: Conversation?
    
    var body: some View {
        HSplitView {
            // Right column - Remote History (smaller)
            VStack {
                // Authentication Status
                HStack {
                    Circle()
                        .fill(isAuthenticated ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(isAuthenticated ? "Authenticated" : "Not Authenticated")
                        .font(.caption)
                        .foregroundColor(isAuthenticated ? .green : .red)
                    Spacer()
                    Toggle("Debug View", isOn: $isDebugView)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: isDebugView) { _, newValue in
                            if let client = openAIClient {
                                Relay.shared.isDebugView = newValue
                                // Force window visibility update
                                if newValue {
                                    client.showWindow()
                                } else if isAuthenticated {
                                    client.hideWindow()
                                }
                            }
                        }
                    if !isAuthenticated {
                        Button("Authenticate") {
                            authenticate()
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Remote History Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Conversation History")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("New Chat") {
                            createNewConversation()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button {
                            fetchHistory()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal)
                    
                    List {
                        if conversationHistory.isEmpty && isAuthenticated {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(conversationHistory, id: \.id) { historyItem in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(historyItem.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text(historyItem.createdTime, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                                .background(selectedConversationItem?.id == historyItem.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                .onTapGesture {
                                    selectedConversationItem = historyItem
                                    loadConversation(historyItem)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .frame(minWidth: 250, maxWidth: 350)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Left column - Main Chat Area (bigger)
            VStack(spacing: 0) {
                // Model Selector at the top
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI Model")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            fetchModels()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Picker("Select Model", selection: $selectedModel) {
                        Text("Auto").tag("auto")
                        ForEach(availableModels, id: \.slug) { model in
                            Text(model.title).tag(model.slug)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 300, alignment: .leading)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Chat Area
                if let conversation = currentConversation {
                    ConversationDetailView(
                        conversation: conversation,
                        currentMessage: $currentMessage,
                        isLoading: $isLoading,
                        selectedModel: selectedModel,
                        onSendMessage: sendMessage
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Welcome to Relay Chat")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Select a conversation from the history or create a new one to get started.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if isAuthenticated {
                            Button("Start New Conversation") {
                                createNewConversation()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            Button("Authenticate to Start") {
                                authenticate()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            initializeRelay()
        }
    }
    
    private func initializeRelay() {
        print("Initializing Relay...")
        // Initialize OpenAI client using the new API
        openAIClient = Relay.OpenAI(autoInitialize: true)
        
        // Set initial debug view state
        isDebugView = Relay.shared.isDebugView
        
        // Check authentication status periodically
        checkAuthenticationStatus()
        
        // Set up a timer to periodically check auth status
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        guard let client = openAIClient else { return }
        
        let wasAuthenticated = isAuthenticated
        isAuthenticated = client.isAuthenticated
        
        print("Auth status check: \(isAuthenticated)")
        
        // If just authenticated, fetch initial data
        if !wasAuthenticated && isAuthenticated {
            print("Just authenticated, fetching initial data...")
            fetchModels()
            fetchHistory()
        }
    }
    
    private func authenticate() {
        guard let client = openAIClient else { return }
        
        // The new API automatically handles authentication when needed
        // We just need to trigger an action that requires auth (like fetching models)
        // and the client will show the auth window automatically
        print("Triggering authentication via model fetch...")
        fetchModels()
    }
    
    private func fetchModels() {
        guard let client = openAIClient else { return }
        
        print("Attempting to fetch models...")
        client.getModels { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let modelsResponse):
                    print("✅ Successfully fetched \(modelsResponse.models.count) models")
                    self.availableModels = modelsResponse.models
                    self.isAuthenticated = true
                    for model in modelsResponse.models {
                        print("  - Model: \(model.slug) - \(model.title)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch models: \(error)")
                    if let relayError = error as? RelayProviderError,
                       case .authenticationRequired = relayError {
                        print("Need to authenticate first for models")
                        self.isAuthenticated = false
                    } else {
                        print("Error fetching models: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func fetchHistory() {
        guard let client = openAIClient else { return }
        
        print("Attempting to fetch conversation history...")
        client.getConversationHistory(offset: 0, limit: 50) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let historyResponse):
                    print("✅ Successfully fetched conversation history: \(historyResponse.items.count) conversations")
                    self.conversationHistory = historyResponse.items
                    self.isAuthenticated = true
                    for item in historyResponse.items {
                        print("  - History: \(item.title)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch conversation history: \(error)")
                    if let relayError = error as? RelayProviderError,
                       case .authenticationRequired = relayError {
                        print("Need to authenticate first for history")
                        self.isAuthenticated = false
                    } else {
                        print("❌ Failed to fetch history: \(error)")
                        if let relayError = error as? RelayProviderError,
                           case .authenticationRequired = relayError {
                            print("Need to authenticate first for history")
                            self.isAuthenticated = false
                        }
                    }
                }
            }
        }
    }
    
    private func loadConversation(_ historyItem: ConversationItem) {
        // Create a conversation object from the history item
        let conversation = Conversation(
            title: historyItem.title,
            messages: [], // We'll load messages as needed
            conversationId: historyItem.id
        )
        currentConversation = conversation
        
        // Fetch the full conversation details using the new getConversationById method
        guard let client = openAIClient else {
            print("❌ No OpenAI client available")
            return
        }
        
        print("🔍 Fetching conversation details for ID: \(historyItem.id)")
        client.getConversationById(historyItem.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conversationDetail):
                    print("✅ Successfully fetched conversation detail:")
                    print("  - ID: \(conversationDetail.id)")
                    print("  - Title: \(conversationDetail.title)")
                    print("  - Created: \(conversationDetail.createdTime)")
                    print("  - Messages count: \(conversationDetail.messages.count)")
                    
                    // Log each message
                    for (index, message) in conversationDetail.messages.enumerated() {
                        print("  - Message \(index + 1): [\(message.author.role)] \(message.content.parts.first ?? "empty")")
                    }
                    
                    // Convert the ConversationMessage objects to our local Message objects for display
                    let localMessages = conversationDetail.messages.map { conversationMessage in
                        Message(
                            content: conversationMessage.content.parts.joined(separator: "\n"),
                            isUser: conversationMessage.author.role == "user"
                        )
                    }
                    
                    // Update the current conversation with the fetched messages
                    var updatedConversation = conversation
                    updatedConversation.messages = localMessages
                    updatedConversation.title = conversationDetail.title
                    self.currentConversation = updatedConversation
                    
                case .failure(let error):
                    print("❌ Failed to fetch conversation detail: \(error)")
                    if let relayError = error as? RelayProviderError,
                       case .authenticationRequired = relayError {
                        print("Need to authenticate first for conversation detail")
                        self.isAuthenticated = false
                    } else {
                        print("❌ Failed to fetch conversation: \(error)")
                        if let relayError = error as? RelayProviderError,
                           case .authenticationRequired = relayError {
                            print("Need to authenticate first for conversation")
                            self.isAuthenticated = false
                        }
                    }
                }
            }
        }
    }
    
    private func createNewConversation() {
        // Clear current conversation to start fresh
        selectedConversationItem = nil
        currentConversation = Conversation()
    }
    
    private func sendMessage() {
        guard let client = openAIClient,
              var conversation = currentConversation,
              !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add user message to conversation
        conversation.messages.append(
            Message(content: userMessage, isUser: true)
        )
        currentConversation = conversation
        
        // Clear input
        currentMessage = ""
        isLoading = true
        
        let handler = ExampleStreamHandler(
            onComplete: { conversationDetail in
                DispatchQueue.main.async {
                    print("🎯 Updating conversation with complete data")
                    
                    // Convert the ConversationMessage objects to our local Message objects
                    let completeMessages = conversationDetail.messages.map { conversationMessage in
                        Message(
                            content: conversationMessage.content.parts.joined(separator: "\n"),
                            isUser: conversationMessage.author.role == "user"
                        )
                    }
                    
                    // Update the conversation with complete data
                    if var updatedConversation = self.currentConversation {
                        updatedConversation.messages = completeMessages
                        updatedConversation.title = conversationDetail.title
                        updatedConversation.conversationId = conversationDetail.id
                        self.currentConversation = updatedConversation
                        
                        print("✅ Updated conversation with \(completeMessages.count) complete messages")
                    }
                    
                    self.isLoading = false
                    // Refresh history to get updated conversation list
                    self.fetchHistory()
                }
            },
            onError: { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Check if it's an authentication error
                    if let relayError = error as? RelayProviderError,
                       case .authenticationRequired = relayError {
                        print("Authentication required - triggering auth")
                        self.isAuthenticated = false
                        // The client will automatically show auth window when needed
                        self.fetchModels()
                    } else {
                        print("❌ Error: \(error.localizedDescription)")
                        if let relayError = error as? RelayProviderError,
                           case .authenticationRequired = relayError {
                            print("Need to authenticate first for sending message")
                            self.isAuthenticated = false
                        }
                    }
                }
            }
        )
        
        // Send message using the new client API with selected model
        print("Sending message: \(userMessage) with model: \(selectedModel)")
        print("Authentication status before sending: \(client.isAuthenticated)")
        
        client.sendConversation(
            message: userMessage,
            conversationId: conversation.conversationId,
            model: selectedModel,
            handler: handler
        )
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    @Binding var currentMessage: String
    @Binding var isLoading: Bool
    let selectedModel: String
    let onSendMessage: () -> Void
    
    var body: some View {
        VStack {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack {
                TextField("Type your message...", text: $currentMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !isLoading {
                            onSendMessage()
                        }
                    }
                
                Button("Send") {
                    onSendMessage()
                }
                .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
        }
        .navigationTitle(conversation.title)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                if message.isUser {
                    // User messages remain as plain text
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .textSelection(.enabled)
                } else {
                    // AI messages rendered as markdown
                    Markdown(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .textSelection(.enabled)
                        .markdownTextStyle(\.text) {
                            FontFamilyVariant(.normal)
                            FontSize(.em(0.95))
                        }
                        .markdownBlockStyle(\.codeBlock) { configuration in
                            configuration.label
                                .padding()
                                .markdownTextStyle {
                                    FontFamilyVariant(.monospaced)
                                    FontSize(.em(0.85))
                                }
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .markdownInlineImageProvider(.asset)
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    RelayExampleView()
        .frame(width: 1000, height: 700)
}
