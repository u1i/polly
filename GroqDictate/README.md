# Polly

![Polly Logo](logo-small.png)

Polly is a blazing-fast, native macOS menu bar app that uses the Groq API (`whisper-large-v3`) to provide instant, highly accurate voice dictation right where your cursor is.

## Features

- **Blazing Fast**: Powered by Groq's high-speed Whisper endpoints.
- **Native macOS**: Built purely in Swift, lives as a lightweight agent in your menu bar.
- **Hold-to-Talk**: Simply press and hold the `fn` (Globe) key to speak, and release to instantly paste the text into whatever app you're using.
- **Floating UI**: A beautiful, non-intrusive floating badge lets you know when it's listening.
- **Language Lock**: Restrict dictation to a specific ISO language code (e.g. `en`, `ko`) to prevent cross-language hallucinations.
- **Auto-Launch**: Optionally start automatically when you log in.

## Installation & Build

No bulky Xcode project required! Polly compiles directly via the Command Line Tools.

1. **Clone the repository** and navigate to the folder.
2. **Build the app**:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
   This script compiles the Swift files, copies the icon templates, and outputs the final `Polly.app` bundle right in the same directory!
3. **Launch the app**:
   ```bash
   open Polly.app
   ```

## Setup & Permissions

When you first run Polly, you'll see its parrot mask icon appear in the menu bar.

1. **Accessibility Permission**: Polly needs Accessibility rights to synthesize the `Cmd+V` keystroke so it can paste your text anywhere. Go to **System Settings > Privacy & Security > Accessibility** and ensure Polly is toggled on.
2. **Microphone Permission**: macOS will ask for mic access the first time you attempt to record.

## Configuration

![Settings Window](settings.png)
1. Click the parrot icon in the menu bar and select **Settings...**.
2. Enter your **Groq API Key** (you can get one from the Groq console).
3. Test your key to verify connectivity.
4. Enter your 2-letter ISO language code (e.g., `en` for English).
5. Toggle "Launch on system startup" if desired.

## Usage

1. Click any text box in any app.
2. **Press and hold the `fn` (Globe) key**.
3. A floating indicator will appear. Speak naturally!
4. **Release the `fn` key**.
5. Within milliseconds, Polly will paste the transcibed text directly where your cursor was!
