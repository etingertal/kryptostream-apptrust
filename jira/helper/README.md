# JIRA Helper - Technical Documentation

This directory contains the technical implementation of the JIRA evidence gathering tool. The `main.go` application is a consolidated Go program that handles all JIRA-related operations including git commit extraction, JIRA API integration, and evidence generation.

## Quick Start

```bash
# Build the application
go build -o main main.go

# Basic usage - extract JIRA IDs from a specific commit and fetch details
./main <commit_hash>

# Process commit range (from commit to HEAD)
./main --range <start_commit>

# Direct JIRA ticket processing
./main EV-123 EV-456 EV-789

# Extract only mode
./main --extract-only <commit_hash>

# Get help
./main --help
```

## Command Line Interface

### Primary Mode: Git-based Evidence Gathering
```bash
./main [OPTIONS] <start_commit>
```

**Arguments:**
- `commit`: The commit to process
  - Without `--range`: Processes only this specific commit
  - With `--range`: Starting commit hash for processing range to HEAD

**Options:**
- `-r, --regex PATTERN`: JIRA ID regex pattern (default: `[A-Z]+-[0-9]+`)
- `-o, --output FILE`: Output file for JIRA data (default: `transformed_jira_data.json`)
- `--extract-only`: Only extract JIRA IDs, don't fetch details
- `--extract-from-git`: Extract JIRA IDs from git commits (legacy mode, use --extract-only instead)
- `--range`: Process commits from the specified commit to HEAD (starting commit is excluded)
- `-h, --help`: Display help message

### Direct Mode: Process Specific JIRA Tickets
```bash
./main <jira_id1> [jira_id2] [jira_id3] ...
```



## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `JIRA_API_TOKEN` | JIRA API token for authentication | Yes¹ | - |
| `JIRA_URL` | JIRA instance URL | Yes¹ | - |
| `JIRA_USERNAME` | JIRA username for authentication | Yes¹ | - |
| `JIRA_ID_REGEX` | JIRA ID regex pattern | No | `[A-Z]+-[0-9]+` |
| `OUTPUT_FILE` | Output file path | No | `transformed_jira_data.json` |

¹ Required only when fetching JIRA details (not needed for `--extract-only` mode)

## Usage Examples

### Basic Evidence Gathering (Single Commit)
```bash
export JIRA_API_TOKEN="your_token"
export JIRA_URL="https://your-domain.atlassian.net"
export JIRA_USERNAME="your_email@domain.com"

# Process only the specific commit
./main abc123def456
```

### Process Commit Range
```bash
# Process all commits from abc123def456 to HEAD
./main --range abc123def456
```

### Custom Configuration
```bash
./main -r 'EV-\d+' -o my_results.json abc123def456
```

### Extract Only (for debugging)
```bash
# Extract from single commit
./main --extract-only abc123def456

# Extract from commit range
./main --extract-only --range abc123def456
```

### Direct Ticket Processing
```bash
# Outputs JSON to transformed_jira_data.json
./main EV-123 EV-456 EV-789
```

## Execution Modes

The application determines execution mode based on provided arguments:

1. **Direct JIRA Mode**: When all arguments match JIRA ID pattern
   - Outputs JSON to file (default: `transformed_jira_data.json`)
   - No git operations performed

2. **Git-based Mode**: When a commit hash is provided
   - **Single Commit** (default): Processes only the specified commit
   - **Range Mode** (with `--range`): Processes from specified commit to HEAD (excluding the start commit)
   - Outputs to file (default: `transformed_jira_data.json`)

3. **Extract Only Mode**: With `--extract-only` flag
   - Only extracts JIRA IDs without fetching details
   - Outputs comma-separated IDs to stdout

## Technical Architecture

### Core Components

#### Git Service
- Encapsulates all git operations in a `GitService` struct
- `GetBranchInfo()`: Extracts current branch, commit hash, and JIRA ID from latest commit
- `ValidateHEAD()`: Validates that HEAD commit exists in repository
- `ValidateCommit()`: Validates commit existence in repository
- `ExtractJiraIDs()`: Extracts JIRA IDs from commit messages using regex (single commit or range)
- `CheckRepository()`: Validates git repository state

#### JIRA Client
- Encapsulates JIRA API operations in a `JiraClient` struct
- `NewJiraClient()`: Creates authenticated JIRA client
- `FetchJiraDetails()`: Fetches comprehensive ticket details from JIRA API
- Helper functions for field extraction (status, description, assignee, etc.)
- `getDescription()`: Parses JIRA's Atlassian Document Format (ADF) to extract plain text
- `extractTextFromADFNode()`: Recursively extracts text from ADF nodes

#### Configuration & CLI
- `AppConfig`: Holds all application configuration
- `FlagConfig`: Manages command-line flags
- `determineExecutionMode()`: Routes to appropriate execution mode
- `displayUsage()`: Shows comprehensive help information
- Custom error types: `GitError`, `ValidationError` for better error handling

### Data Structures

```go
type TransitionCheckResponse struct {
    Tasks []JiraTransitionResult `json:"tasks"`
}

type JiraTransitionResult struct {
    Key         string       `json:"key"`
    Status      string       `json:"status"`
    Description string       `json:"description"`
    Type        string       `json:"type"`
    Project     string       `json:"project"`
    Created     string       `json:"created"`
    Updated     string       `json:"updated"`
    Assignee    *string      `json:"assignee"`
    Reporter    string       `json:"reporter"`
    Priority    string       `json:"priority"`
    Transitions []Transition `json:"transitions"`
}

type Transition struct {
    FromStatus     string `json:"from_status"`
    ToStatus       string `json:"to_status"`
    Author         string `json:"author"`
    AuthorEmail    string `json:"author_user_name"`
    TransitionTime string `json:"transition_time"`
}
```

## Building and Development

### Prerequisites
- Go 1.21 or later
- Git (for git operations)
- JIRA Cloud API access

### Build Commands
```bash
# Standard build
go build -o main main.go

# Using build script
./build.sh

# Cross-platform build
GOOS=linux GOARCH=amd64 go build -o main main.go
```

### Dependencies
```go
import (
    "context"
    "encoding/json"
    "flag"
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
    "regexp"
    "strings"
    "time"

    jira "github.com/andygrunwald/go-jira/v2/cloud"
)
```

### Testing
```bash
# Run tests
go test ./...

# Test specific functionality
go test -v -run TestExtractJiraIDs
```

## Constants

```go
// Default values
const DefaultJIRAIDRegex = "[A-Z]+-[0-9]+"
const DefaultOutputFile = "transformed_jira_data.json"

// JIRA-specific constants
const JiraTimeFormat = "2006-01-02T15:04:05.000-0700"
const ErrorStatus = "Error"
const ErrorType = "Error"
```

## Error Handling

### Git Errors
- Repository validation failures
- HEAD commit existence checks
- Commit existence checks
- Branch information extraction errors

### JIRA API Errors
- Authentication failures
- Network connectivity issues
- Invalid ticket IDs
- API rate limiting

### File System Errors
- Output file creation failures
- Directory permission issues
- JSON marshaling errors

### Error Response Format
```json
{
  "tasks": [
    {
      "key": "EV-123",
      "status": "Error",
      "description": "Error: Could not retrieve issue",
      "type": "Error",
      "project": "",
      "created": "",
      "updated": "",
      "assignee": null,
      "reporter": "",
      "priority": "",
      "transitions": []
    }
  ]
}
```

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Fetch details from jira
  run: |
    cd jira/helper
    echo "Processing JIRA details for commit: ${{ steps.build_info.outputs.vcs_revision }}"
    ./main "${{ steps.build_info.outputs.vcs_revision }}"
    cd -
```



## Performance Considerations

### Git Operations
- Uses `git log` with specific format for efficiency
- Validates commits before processing
- Handles large commit ranges gracefully

### JIRA API
- Processes tickets sequentially to avoid rate limiting
- Graceful error handling for individual ticket failures
- Continues processing even if some tickets fail

### Memory Usage
- Streams JSON output to avoid large memory allocations
- Uses maps for deduplication of JIRA IDs
- Efficient string handling for large commit histories

## Troubleshooting

### Common Issues

1. **Git Repository Not Found**
   ```
   Error: not in a git repository
   ```
   **Solution**: Ensure you're running the command from a git repository

2. **JIRA Authentication Failed**
   ```
   JIRA token not found, set jira_token variable
   ```
   **Solution**: Set the required environment variables

3. **Invalid Regex Pattern**
   ```
   Error: invalid JIRA ID regex
   ```
   **Solution**: Check your regex pattern syntax

4. **Commit Not Found**
   ```
   ❌ commit 'abc123' not found
   ```
   **Solution**: Verify the commit hash exists and fetch depth is sufficient

5. **HEAD Commit Not Found**
   ```
   ❌ HEAD commit not found. Repository may be empty or corrupted
   ```
   **Solution**: Ensure the repository has at least one commit and is not corrupted

### Debug Mode
```bash
# Enable verbose output
export DEBUG=true
./main <start_commit>

# Extract only to debug git operations
./main --extract-only <start_commit>
```

## Contributing

### Code Style
- Follow Go conventions and `gofmt`
- Add comments for exported functions
- Include error handling for all external calls

### Testing
- Add unit tests for new functions
- Test error conditions
- Validate JSON output format

### Dependencies
- Keep dependencies minimal
- Use specific versions in `go.mod`
- Document any new dependencies

## License

This tool is part of the Evidence-Examples repository and follows the same licensing terms. 