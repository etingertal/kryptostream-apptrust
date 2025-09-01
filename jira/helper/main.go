package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// Constants for default values
const (
	DefaultJIRAIDRegex = "[A-Z]+-[0-9]+"
	DefaultOutputFile  = "transformed_jira_data.json"
)

// AppConfig holds all configuration for the application
type AppConfig struct {
	// JIRA Configuration
	JIRAToken    string
	JIRAURL      string
	JIRAUsername string
	JIRAIDRegex  string

	// Output Configuration
	OutputFile string

	// Runtime Configuration
	ExtractOnly    bool
	ExtractFromGit bool
	SingleCommit   bool
	StartCommit    string
	JIRAIDs        []string
}

// FlagConfig holds command line flags
type FlagConfig struct {
	JIRAIDRegex    string
	OutputFile     string
	ExtractOnly    bool
	ExtractFromGit bool
	CommitRange    bool
	Help           bool
	HelpLong       bool
}

// Custom error types for better error handling
type GitError struct {
	Operation string
	Err       error
}

func (e *GitError) Error() string {
	return fmt.Sprintf("git operation '%s' failed: %v", e.Operation, e.Err)
}

type ValidationError struct {
	Field string
	Value string
	Err   error
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation failed for %s='%s': %v", e.Field, e.Value, e.Err)
}

// Helper function to get value with defaults
func getOrDefault(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}

// loadConfig loads configuration from flags and environment variables
func loadConfig(flags *FlagConfig, args []string) (*AppConfig, error) {
	config := &AppConfig{
		JIRAIDRegex:    getOrDefault(flags.JIRAIDRegex, os.Getenv("JIRA_ID_REGEX"), DefaultJIRAIDRegex),
		OutputFile:     getOrDefault(flags.OutputFile, os.Getenv("OUTPUT_FILE"), DefaultOutputFile),
		ExtractOnly:    flags.ExtractOnly,
		ExtractFromGit: flags.ExtractFromGit,
		SingleCommit:   !flags.CommitRange, // Default to single commit unless --range is specified
	}

	// Load JIRA credentials only if not in extract-only mode
	if !config.ExtractOnly && !config.ExtractFromGit {
		config.JIRAToken = os.Getenv("JIRA_API_TOKEN")
		config.JIRAURL = os.Getenv("JIRA_URL")
		config.JIRAUsername = os.Getenv("JIRA_USERNAME")

		// Validate JIRA configuration
		if err := validateJIRAConfig(config); err != nil {
			return nil, err
		}
	}

	return config, nil
}

// validateJIRAConfig validates JIRA-related configuration
func validateJIRAConfig(config *AppConfig) error {
	if config.JIRAToken == "" {
		return &ValidationError{Field: "JIRA_API_TOKEN", Value: "", Err: fmt.Errorf("environment variable is required")}
	}
	if config.JIRAURL == "" {
		return &ValidationError{Field: "JIRA_URL", Value: "", Err: fmt.Errorf("environment variable is required")}
	}
	if config.JIRAUsername == "" {
		return &ValidationError{Field: "JIRA_USERNAME", Value: "", Err: fmt.Errorf("environment variable is required")}
	}
	return nil
}

// validateCommitHash validates that a commit hash looks valid
func validateCommitHash(hash string) error {
	if hash == "" {
		return &ValidationError{Field: "commit", Value: hash, Err: fmt.Errorf("cannot be empty")}
	}

	// Basic validation - should be hex characters (allowing short hashes)
	validHex := regexp.MustCompile("^[a-fA-F0-9]+$")
	if !validHex.MatchString(hash) {
		return &ValidationError{Field: "commit", Value: hash, Err: fmt.Errorf("invalid format")}
	}

	return nil
}

// GitService handles all git operations
type GitService struct {
	execCommand func(args ...string) (string, error)
}

// NewGitService creates a new git service
func NewGitService() *GitService {
	return &GitService{
		execCommand: defaultGitCommand,
	}
}

// defaultGitCommand executes a git command and returns the output
func defaultGitCommand(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	output, err := cmd.Output()
	if err != nil {
		return "", &GitError{Operation: strings.Join(args, " "), Err: err}
	}
	return strings.TrimSpace(string(output)), nil
}

// GetBranchInfo returns current branch name, latest commit hash, and JIRA ID from latest commit
func (g *GitService) GetBranchInfo() (string, string, string, error) {
	// Get current branch
	branchName, err := g.execCommand("branch", "--show-current")
	if err != nil {
		return "", "", "", err
	}

	// Get commit hash and subject in one command to reduce git calls
	commitOutput, err := g.execCommand("log", "-1", "--format=%H%n%s")
	if err != nil {
		return "", "", "", err
	}

	lines := strings.Split(commitOutput, "\n")
	if len(lines) < 2 {
		return "", "", "", &GitError{Operation: "log -1", Err: fmt.Errorf("unexpected output format")}
	}

	commitHash := lines[0]
	subject := lines[1]

	// Extract JIRA ID using default pattern
	jiraID := extractFirstJIRAID(subject, DefaultJIRAIDRegex)

	return branchName, commitHash, jiraID, nil
}

// extractFirstJIRAID extracts the first JIRA ID from a string
func extractFirstJIRAID(text, pattern string) string {
	regex, err := regexp.Compile(pattern)
	if err != nil {
		return ""
	}

	matches := regex.FindAllString(text, -1)
	if len(matches) > 0 {
		return matches[0]
	}

	return ""
}

// ValidateCommit checks if a commit exists in the repository
func (g *GitService) ValidateCommit(commit string) error {
	// First validate the commit hash format
	if err := validateCommitHash(commit); err != nil {
		return err
	}

	if _, err := g.execCommand("rev-parse", "--verify", commit); err != nil {
		return &GitError{Operation: "rev-parse --verify", Err: fmt.Errorf("commit '%s' not found", commit)}
	}
	return nil
}

// ValidateHEAD checks if HEAD commit exists in the repository
func (g *GitService) ValidateHEAD() error {
	if _, err := g.execCommand("rev-parse", "--verify", "HEAD"); err != nil {
		return &GitError{Operation: "rev-parse --verify HEAD", Err: fmt.Errorf("repository may be empty or corrupted")}
	}
	return nil
}

// ExtractJiraIDs extracts JIRA IDs from git commit messages
func (g *GitService) ExtractJiraIDs(startCommit, jiraIDRegex, currentJiraID string, singleCommit bool) ([]string, error) {
	// Validate commit first
	if err := g.ValidateCommit(startCommit); err != nil {
		return nil, err
	}

	var output string
	var err error

	if singleCommit {
		// Get only the specified commit message
		output, err = g.execCommand("log", "-1", "--pretty=format:%s", startCommit)
		if err != nil {
			return nil, err
		}
	} else {
		// Get commit messages from startCommit to HEAD (original behavior)
		output, err = g.execCommand("log", "--pretty=format:%s", startCommit+"..HEAD")
		if err != nil {
			return nil, err
		}
	}

	// Parse regex
	regex, err := regexp.Compile(jiraIDRegex)
	if err != nil {
		return nil, &ValidationError{Field: "jira_id_regex", Value: jiraIDRegex, Err: err}
	}

	// Extract unique JIRA IDs
	// In single commit mode, don't add currentJiraID from branch
	jiraIDToAdd := currentJiraID
	if singleCommit {
		jiraIDToAdd = ""
	}
	uniqueIDs := extractUniqueJIRAIDs(output, jiraIDToAdd, regex)

	if len(uniqueIDs) == 0 {
		if singleCommit {
			fmt.Fprintf(os.Stderr, "⚠️  No JIRA IDs found in commit %s\n", startCommit)
		} else {
			fmt.Fprintf(os.Stderr, "⚠️  No JIRA IDs found in commit range %s..HEAD\n", startCommit)
		}
	}

	return uniqueIDs, nil
}

// extractUniqueJIRAIDs extracts unique JIRA IDs from commit messages
func extractUniqueJIRAIDs(commitMessages, currentJiraID string, regex *regexp.Regexp) []string {
	jiraIDs := make(map[string]bool)

	// Add current JIRA ID if it matches the pattern
	if currentJiraID != "" && regex.MatchString(currentJiraID) {
		jiraIDs[currentJiraID] = true
	}

	// Extract from commit messages
	lines := strings.Split(commitMessages, "\n")
	for _, line := range lines {
		matches := regex.FindAllString(line, -1)
		for _, match := range matches {
			jiraIDs[match] = true
		}
	}

	// Convert map to slice
	var result []string
	for jiraID := range jiraIDs {
		if jiraID != "" {
			result = append(result, jiraID)
		}
	}

	return result
}

// CheckRepository checks if we're in a git repository
func (g *GitService) CheckRepository() error {
	if _, err := g.execCommand("rev-parse", "--git-dir"); err != nil {
		return &GitError{Operation: "rev-parse --git-dir", Err: fmt.Errorf("not in a git repository")}
	}
	return nil
}

// writeToFile writes data to a file
func writeToFile(filename string, data []byte) error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(filename)
	if dir != "." {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory: %v", err)
		}
	}

	return os.WriteFile(filename, data, 0644)
}

// displayUsage shows the usage information
func displayUsage() {
	fmt.Println("JIRA Evidence Tool - Enhanced")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  ./main [OPTIONS] <start_commit>")
	fmt.Println("  ./main <jira_id1> [jira_id2] [jira_id3] ...")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  -r, --regex PATTERN    JIRA ID regex pattern (default: '[A-Z]+-[0-9]+')")
	fmt.Println("  -o, --output FILE      Output file for JIRA data (default: transformed_jira_data.json)")
	fmt.Println("  --extract-only         Only extract JIRA IDs, don't fetch details")
	fmt.Println("  --extract-from-git     Extract JIRA IDs from git commits (legacy mode)")
	fmt.Println("  --range                Process commits from the specified commit to HEAD (instead of single commit)")
	fmt.Println("  -h, --help             Display this help message")
	fmt.Println("")
	fmt.Println("Arguments:")
	fmt.Println("  commit                 The commit to process (default: process only this commit)")
	fmt.Println("                         With --range: Starting commit hash (excluded from evidence filter)")
	fmt.Println("")
	fmt.Println("Environment Variables:")
	fmt.Println("  JIRA_API_TOKEN         JIRA API token")
	fmt.Println("  JIRA_URL              JIRA instance URL")
	fmt.Println("  JIRA_USERNAME         JIRA username")
	fmt.Println("  JIRA_ID_REGEX         JIRA ID regex pattern (can be overridden with -r)")
	fmt.Println("  OUTPUT_FILE           Output file path (can be overridden with -o)")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  ./main abc123def456                   # Process only commit abc123def456")
	fmt.Println("  ./main --range abc123def456           # Process commits from abc123def456 to HEAD")
	fmt.Println("  ./main -r 'EV-\\d+' -o jira_results.json abc123def456")
	fmt.Println("  ./main --extract-only abc123def456")
	fmt.Println("  ./main EV-123 EV-456 EV-789         # Direct JIRA ticket processing")
}

// Split main function helpers

// runExtractOnlyMode runs the tool in extract-only mode
func runExtractOnlyMode(config *AppConfig) error {
	git := NewGitService()

	fmt.Println("=== JIRA ID Extraction (Extract Only Mode) ===")
	if config.SingleCommit {
		fmt.Printf("Commit: %s\n", config.StartCommit)
	} else {
		fmt.Printf("Start Commit: %s\n", config.StartCommit)
	}
	fmt.Printf("JIRA ID Regex: %s\n", config.JIRAIDRegex)
	fmt.Println("")

	// Get branch info
	branchName, commitHash, currentJiraID, err := git.GetBranchInfo()
	if err != nil {
		return fmt.Errorf("failed to get branch info: %w", err)
	}

	fmt.Printf("Branch: %s\n", branchName)
	fmt.Printf("Latest Commit: %s\n", commitHash)

	// Validate HEAD
	if err := git.ValidateHEAD(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		return nil // Exit gracefully
	}

	// Extract JIRA IDs
	jiraIDs, err := git.ExtractJiraIDs(config.StartCommit, config.JIRAIDRegex, currentJiraID, config.SingleCommit)
	if err != nil {
		return fmt.Errorf("failed to extract JIRA IDs: %w", err)
	}

	if len(jiraIDs) == 0 {
		fmt.Println("No JIRA IDs found")
		return nil
	}

	// Output comma-separated JIRA IDs
	fmt.Println(strings.Join(jiraIDs, ","))
	return nil
}

// runLegacyExtractFromGit runs the legacy extract-from-git mode
func runLegacyExtractFromGit(args []string) error {
	if len(args) < 2 {
		fmt.Println("Usage: ./main --extract-from-git <start_commit> <jira_id_regex>")
		return fmt.Errorf("insufficient arguments")
	}

	git := NewGitService()
	startCommit := args[0]
	regex := args[1]

	// Get branch info
	branchName, commitHash, currentJiraID, err := git.GetBranchInfo()
	if err != nil {
		return fmt.Errorf("error getting branch info: %v", err)
	}

	fmt.Printf("BRANCH_NAME: %s\n", branchName)
	fmt.Printf("JIRA ID: %s\n", currentJiraID)
	fmt.Printf("START_COMMIT: %s\n", commitHash)

	// Validate HEAD
	if err := git.ValidateHEAD(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		return nil // Exit gracefully
	}

	// Validate commit
	if err := git.ValidateCommit(startCommit); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		return nil // Exit gracefully
	}

	// Extract JIRA IDs
	jiraIDs, err := git.ExtractJiraIDs(startCommit, regex, currentJiraID, false)
	if err != nil {
		return fmt.Errorf("error extracting JIRA IDs: %v", err)
	}

	if len(jiraIDs) == 0 {
		fmt.Println("No JIRA IDs found")
		return nil
	}

	// Print comma-separated JIRA IDs
	fmt.Println(strings.Join(jiraIDs, ","))
	return nil
}

// runFullMode runs the complete JIRA evidence gathering process
func runFullMode(config *AppConfig) error {
	git := NewGitService()

	fmt.Println("=== JIRA Details Fetching Process ===")
	if config.SingleCommit {
		fmt.Printf("Commit: %s\n", config.StartCommit)
	} else {
		fmt.Printf("Start Commit: %s\n", config.StartCommit)
	}
	fmt.Printf("JIRA ID Regex: %s\n", config.JIRAIDRegex)
	fmt.Printf("Output File: %s\n", config.OutputFile)
	fmt.Println("")

	// Step 1: Extract JIRA IDs from git commits
	if config.SingleCommit {
		fmt.Println("Step 1: Extracting JIRA IDs from commit...")
	} else {
		fmt.Println("Step 1: Extracting JIRA IDs from git commits...")
	}

	// Get branch info
	branchName, commitHash, currentJiraID, err := git.GetBranchInfo()
	if err != nil {
		return fmt.Errorf("error getting branch info: %v", err)
	}

	// Display branch information
	fmt.Printf("Branch: %s\n", branchName)
	fmt.Printf("Latest Commit: %s\n", commitHash)

	// Validate HEAD
	if err := git.ValidateHEAD(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ %v\n", err)
		return nil // Exit gracefully
	}

	// Extract JIRA IDs
	jiraIDs, err := git.ExtractJiraIDs(config.StartCommit, config.JIRAIDRegex, currentJiraID, config.SingleCommit)
	if err != nil {
		return fmt.Errorf("error extracting JIRA IDs: %v", err)
	}

	if len(jiraIDs) == 0 {
		fmt.Println("No JIRA IDs found in commit range")
		return nil
	}

	fmt.Printf("Found JIRA IDs: %s\n", strings.Join(jiraIDs, ", "))
	config.JIRAIDs = jiraIDs

	// Step 2: Fetch JIRA details
	fmt.Println("")
	fmt.Println("Step 2: Fetching JIRA details...")

	// Create JIRA client
	jiraClient, err := NewJiraClient()
	if err != nil {
		return fmt.Errorf("error creating JIRA client: %v", err)
	}

	// Process JIRA IDs and get results
	response := jiraClient.FetchJiraDetails(config.JIRAIDs)

	// Step 3: Write results to file
	fmt.Println("")
	fmt.Println("Step 3: Writing results...")

	if err := saveJiraResults(response, config); err != nil {
		return err
	}

	fmt.Println("")
	fmt.Println("=== Process completed successfully ===")
	return nil
}

// saveJiraResults saves JIRA results to JSON
func saveJiraResults(response TransitionCheckResponse, config *AppConfig) error {
	// Save JSON
	jsonBytes, err := json.MarshalIndent(response, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshaling JSON: %v", err)
	}

	if err := writeToFile(config.OutputFile, jsonBytes); err != nil {
		return fmt.Errorf("error writing to file: %v", err)
	}

	fmt.Printf("JIRA data saved to: %s\n", config.OutputFile)

	return nil
}

// determinExecutionMode determines which mode to run based on flags and arguments
func determineExecutionMode(flags *FlagConfig, args []string, config *AppConfig) error {
	// Handle legacy extract-from-git mode
	if flags.ExtractFromGit {
		return runLegacyExtractFromGit(args)
	}

	// Check if we have required arguments
	if len(args) == 0 {
		return fmt.Errorf("missing required arguments")
	}

	// Check if this is direct JIRA ID processing mode
	if !flags.ExtractOnly && len(args) > 0 {
		// Check if all arguments match JIRA ID pattern
		regex, err := regexp.Compile(config.JIRAIDRegex)
		if err == nil && allArgsMatchPattern(args, regex) {
			// All arguments are JIRA IDs - process them directly
			config.JIRAIDs = args
			return processDirectJiraIDs(config)
		}
	}

	// Otherwise, we're in git-based mode
	config.StartCommit = args[0]

	// Check if we're in a git repository
	git := NewGitService()
	if err := git.CheckRepository(); err != nil {
		return err
	}

	// Run the appropriate mode
	if config.ExtractOnly {
		return runExtractOnlyMode(config)
	}
	return runFullMode(config)
}

// allArgsMatchPattern checks if all arguments match the given regex pattern
func allArgsMatchPattern(args []string, regex *regexp.Regexp) bool {
	for _, arg := range args {
		if !regex.MatchString(arg) {
			return false
		}
	}
	return true
}

func main() {
	// Parse command line flags
	flags := &FlagConfig{}
	flag.StringVar(&flags.JIRAIDRegex, "r", "", "JIRA ID regex pattern")
	flag.StringVar(&flags.OutputFile, "o", "", "Output file for JIRA data")
	flag.BoolVar(&flags.ExtractOnly, "extract-only", false, "Only extract JIRA IDs, don't fetch details")
	flag.BoolVar(&flags.ExtractFromGit, "extract-from-git", false, "Extract JIRA IDs from git commits (legacy mode)")
	flag.BoolVar(&flags.CommitRange, "range", false, "Process commits from the specified commit to HEAD (instead of single commit)")
	flag.BoolVar(&flags.Help, "h", false, "Display help message")
	flag.BoolVar(&flags.HelpLong, "help", false, "Display help message")
	flag.Parse()

	// Handle help flags
	if flags.Help || flags.HelpLong {
		displayUsage()
		return
	}

	// Get remaining arguments
	args := flag.Args()

	// Load configuration
	config, err := loadConfig(flags, args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading configuration: %v\n", err)
		displayUsage()
		os.Exit(1)
	}

	// Determine and execute the appropriate mode
	if err := determineExecutionMode(flags, args, config); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// processDirectJiraIDs handles direct JIRA ID processing (no git operations)
func processDirectJiraIDs(config *AppConfig) error {
	fmt.Printf("Processing JIRA IDs: %s\n", strings.Join(config.JIRAIDs, ", "))

	// Create a new Jira client
	jiraClient, err := NewJiraClient()
	if err != nil {
		return fmt.Errorf("error creating JIRA client: %v", err)
	}

	// Get response
	response := jiraClient.FetchJiraDetails(config.JIRAIDs)

	// Save results to file using the same method as other modes
	if err := saveJiraResults(response, config); err != nil {
		return err
	}

	return nil
}
