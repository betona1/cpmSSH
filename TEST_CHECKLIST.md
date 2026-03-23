# CPM SSH Terminal - Test Checklist

## 1. Server Management

- [ ] App launches without crash (Windows)
- [ ] App launches without crash (Android)
- [ ] Empty server list shows placeholder message
- [ ] Add new server via FAB (+) button
- [ ] Edit server profile (name, host, port, username)
- [ ] Save server with password authentication
- [ ] Save server with key-based authentication
- [ ] Import private key file (.pem)
- [ ] Delete server from list (long-press menu)
- [ ] Toggle server favorite (long-press menu)
- [ ] Favorite icon displays on server card
- [ ] Server group/folder display
- [ ] Search servers by name/IP

## 2. SSH Connection

- [ ] Connect to server via password auth
- [ ] Connect to server via key auth
- [ ] Connection progress indicator shown
- [ ] Connection error displays message with Go Back button
- [ ] Terminal renders after successful connect
- [ ] Type commands in terminal and see output
- [ ] Ctrl+C sends interrupt signal
- [ ] Ctrl+D sends EOF
- [ ] Terminal scrollback works (scroll up to see history)
- [ ] Disconnect from server (close tab X button)
- [ ] Multiple simultaneous SSH sessions (multi-tab)
- [ ] Switch between tabs
- [ ] Session auto-reconnect / keep-alive

## 3. Terminal UI

- [ ] Dark theme renders correctly
- [ ] Light theme renders correctly
- [ ] Theme toggle button works in toolbar
- [ ] Font family change applies to terminal
- [ ] Font size change applies to terminal
- [ ] Pinch-to-zoom on mobile
- [ ] Copy text from terminal
- [ ] Paste text into terminal
- [ ] Korean (한글) input via input bar
- [ ] Input bar opens via FAB button
- [ ] Input bar send button works
- [ ] Input bar history (up/down arrows)
- [ ] Input bar expand/collapse (multi-line)
- [ ] Input bar close button
- [ ] Shift+Enter for newline in input bar
- [ ] Dual mode toggle (split screen)
- [ ] Dual mode shows two terminals side by side
- [ ] Active panel highlight in dual mode
- [ ] Click to switch active panel in dual mode

## 4. Port Forwarding (Tunnel)

- [ ] Port forward list screen loads
- [ ] Empty state shows example card
- [ ] Add new port forward rule
- [ ] Configure local port, remote host, remote port, gateway
- [ ] Start port forward (play button)
- [ ] Stop port forward (stop button)
- [ ] Status indicator (running/stopped/error/connecting)
- [ ] Auto-start checkbox toggle
- [ ] Edit existing port forward
- [ ] Delete port forward with confirmation dialog
- [ ] Error message displayed on failure
- [ ] Port forward persists across app restart

## 5. CPM Dashboard

- [ ] Dashboard loads when CPM server connected
- [ ] Disconnected view shows when CPM unavailable
- [ ] Retry button reconnects to CPM
- [ ] Stats row displays (Total Prompts, Projects, Days, Tokens)
- [ ] Favorites filter shows only favorited projects
- [ ] All filter shows all projects
- [ ] Project cards display name, days, tokens, prompt count
- [ ] Project screenshot thumbnail loads
- [ ] Tap project card shows full screenshot
- [ ] GitHub link opens in browser
- [ ] Dev URL link opens in browser
- [ ] Deploy URL link opens in browser
- [ ] Pull-to-refresh reloads data
- [ ] Responsive grid layout (1/2/3 columns)

## 6. Prompt History

- [ ] Prompt history screen loads
- [ ] Prompts listed per project
- [ ] Search prompts by keyword
- [ ] Prompt status display (success/fail/pending)
- [ ] Reuse prompt (send to terminal)
- [ ] Tag filtering (bug, feature, refactor)

## 7. Settings

- [ ] Settings screen loads
- [ ] Theme toggle (Dark/Light) persists
- [ ] Font family dropdown works
- [ ] Font size slider works
- [ ] Font preview updates in real-time
- [ ] Default SSH port setting
- [ ] Keep-alive interval dropdown
- [ ] Connection timeout dropdown
- [ ] CPM Server URL input and save
- [ ] CPM connection test button
- [ ] CPM connection status indicator
- [ ] Version number displays correctly

## 8. Navigation

- [ ] Bottom navigation or shell screen works
- [ ] Navigate to Servers tab
- [ ] Navigate to Port Forwarding tab
- [ ] Navigate to CPM Dashboard tab
- [ ] Navigate to Prompt History
- [ ] Navigate to Settings
- [ ] Hamburger menu (end drawer) in terminal
- [ ] Drawer navigation links work
- [ ] Back navigation from terminal to server list
- [ ] Deep link: /server/add
- [ ] Deep link: /server/edit/:id

## 9. Data Persistence

- [ ] Server profiles saved to SQLite database
- [ ] Port forward configs saved to database
- [ ] Settings saved via SharedPreferences
- [ ] Secure storage for passwords/keys
- [ ] Data survives app restart

## 10. Platform-Specific

### Windows
- [ ] Window renders at correct size
- [ ] Keyboard input works directly in terminal
- [ ] Hardware keyboard only mode active
- [ ] Window resize does not break layout

### Android
- [ ] Mobile keyboard toolbar shows special keys
- [ ] Haptic feedback on key press
- [ ] Portrait orientation layout
- [ ] Landscape orientation layout
- [ ] Back button behavior correct
- [ ] App icon and splash screen

## 11. Edge Cases

- [ ] Invalid server address shows error
- [ ] Network timeout handled gracefully
- [ ] Large terminal output does not freeze UI
- [ ] Rapid tab switching stable
- [ ] App backgrounded and resumed (Android)
- [ ] No memory leaks on repeated connect/disconnect
