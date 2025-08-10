# VS Code/Cursor Act Integration

This directory contains configuration files that add "play" buttons to your IDE for running GitHub Actions workflows locally using `act`.

## 🚀 Play Buttons Available

### 1. **Tasks (Ctrl/Cmd + Shift + P → "Tasks: Run Task")**
- **Act: Run Current Workflow** - Run the currently open workflow file in dry-run mode
- **Act: Run Current Workflow (Live)** - Run the currently open workflow file in live mode
- **Act: Test Environment Variables** - Test environment variables configuration
- **Act: Test Docker Login** - Test Docker login functionality
- **Act: List Workflows** - List all available workflows

### 2. **Debug/Run (F5 or Ctrl/Cmd + Shift + D)**
- **Act: Run Current Workflow (Dry Run)** - Play button for dry-run mode
- **Act: Run Current Workflow (Live)** - Play button for live mode
- **Act: Test Environment Variables** - Quick test environment variables
- **Act: Test Docker Login** - Quick test Docker login

## 🎯 How to Use

### Method 1: Using Tasks
1. Open any workflow file (`.yml` or `.yaml`) in `.github/workflows/`
2. Press `Ctrl/Cmd + Shift + P`
3. Type "Tasks: Run Task"
4. Select the desired act task

### Method 2: Using Debug/Run
1. Open any workflow file (`.yml` or `.yaml`) in `.github/workflows/`
2. Press `F5` or go to Run and Debug panel (`Ctrl/Cmd + Shift + D`)
3. Select the desired act configuration from the dropdown
4. Click the play button ▶️

### Method 3: Command Palette
1. Press `Ctrl/Cmd + Shift + P`
2. Type "Act:" to see all available act commands
3. Select the desired command

## 📋 Prerequisites

1. **Install act**: Make sure you have `act` installed on your system
   ```bash
   # macOS
   brew install act
   
   # Linux
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   
   # Windows
   choco install act-cli
   ```

2. **Environment File**: Ensure you have a `.env` file with your configuration
   ```bash
   # Example .env file
   DOCKER_REGISTRY=your-registry.com
   DOCKER_USERNAME=your-username
   DOCKER_ACCESS_TOKEN=your-token
   ```

## 🔧 Configuration Files

- **`.vscode/tasks.json`** - Defines tasks for running act commands
- **`.vscode/launch.json`** - Defines debug configurations with play buttons
- **`.vscode/settings.json`** - Enhances YAML editing experience
- **`.vscode/run-act.js`** - Helper script for executing act commands

## 🎨 Features

- ✅ **Play buttons** for workflow files
- ✅ **Syntax highlighting** for GitHub Actions YAML
- ✅ **Validation** using GitHub Actions schema
- ✅ **Auto-completion** for workflow syntax
- ✅ **Dry-run mode** for safe testing
- ✅ **Live mode** for actual execution
- ✅ **Integrated terminal** output

## 🚨 Safety Notes

- **Dry-run mode** is the default for safety
- **Live mode** will actually execute the workflow
- Always review the workflow before running in live mode
- The `.env` file contains sensitive data - never commit it

## 🐛 Troubleshooting

### Act not found
```bash
# Check if act is installed
act --version

# Install if missing
brew install act  # macOS
```

### Permission denied
```bash
# Make the script executable
chmod +x .vscode/run-act.js
```

### Environment file missing
```bash
# Create .env file with your configuration
cp .env.example .env
# Edit .env with your actual values
```

## 📚 Additional Resources

- [Act Documentation](https://github.com/nektos/act)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [VS Code Tasks Documentation](https://code.visualstudio.com/docs/editor/tasks)
