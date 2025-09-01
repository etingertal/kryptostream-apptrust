package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	jira "github.com/andygrunwald/go-jira/v2/cloud"
)

// Constants
const (
	JiraTimeFormat = "2006-01-02T15:04:05.000-0700"
	ErrorStatus    = "Error"
	ErrorType      = "Error"
)

/*
    JiraTransitionResponse is the json formatted predicate that will be returned to the calling build process for cresting an evidence
    its structure should be:

    {
        "tasks": [
            {
                "key": "EV-1",
                "status": "QA in Progress",
                "description": "<description text>",
                "type": "Task",
                "project": "EV",
                "created": "2020-01-01T12:11:56.063+0530",
                "updated": "2020-01-01T12:12:01.876+0530",
                "assignee": "<assignee name>",
                "reporter": "<reporter name>",
                "priority": "Medium",
                "transitions": [
                    {
                        "from_status": "To Do",
                        "to_status": "In Progress",
                        "author": "<>author name>",
                        "author_user_name": "<author email>",
                        "transition_time": "2020-07-28T16:39:54.620+0530"
                    }
                ]
            },
            {
                "key": "EV-2",
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

   notice that the calling client should first check that return value was 0 before using the response JSON,
   otherwise the response is an error message which cannot be parsed
*/

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

// JiraClient wraps the JIRA client and provides methods for JIRA operations
type JiraClient struct {
	client *jira.Client
}

// NewJiraClient creates a new JIRA client with authentication
func NewJiraClient() (*JiraClient, error) {
	jiraToken := os.Getenv("JIRA_API_TOKEN")
	if jiraToken == "" {
		return nil, &ValidationError{Field: "JIRA_API_TOKEN", Value: "", Err: fmt.Errorf("environment variable not found")}
	}

	jiraURL := os.Getenv("JIRA_URL")
	if jiraURL == "" {
		return nil, &ValidationError{Field: "JIRA_URL", Value: "", Err: fmt.Errorf("environment variable not found")}
	}

	jiraUsername := os.Getenv("JIRA_USERNAME")
	if jiraUsername == "" {
		return nil, &ValidationError{Field: "JIRA_USERNAME", Value: "", Err: fmt.Errorf("environment variable not found")}
	}

	// Create JIRA client with basic auth transport
	tp := jira.BasicAuthTransport{
		Username: jiraUsername,
		APIToken: jiraToken,
	}

	client, err := jira.NewClient(jiraURL, tp.Client())
	if err != nil {
		return nil, fmt.Errorf("failed to create JIRA client: %w", err)
	}

	return &JiraClient{client: client}, nil
}

// FetchJiraDetails fetches JIRA details sequentially
func (jc *JiraClient) FetchJiraDetails(jiraIDs []string) TransitionCheckResponse {
	response := TransitionCheckResponse{
		Tasks: make([]JiraTransitionResult, 0, len(jiraIDs)),
	}

	for _, jiraID := range jiraIDs {
		result := jc.fetchSingleJiraDetail(jiraID)
		response.Tasks = append(response.Tasks, result)
	}

	return response
}

// fetchSingleJiraDetail fetches details for a single JIRA ID
func (jc *JiraClient) fetchSingleJiraDetail(jiraID string) JiraTransitionResult {
	issue, _, err := jc.client.Issue.Get(context.Background(), jiraID, &jira.GetQueryOptions{Expand: "changelog"})

	if err != nil || issue == nil || issue.Fields == nil {
		return jc.createErrorResult(jiraID, err)
	}

	return jc.createSuccessResult(issue)
}

// createErrorResult creates an error result for a failed JIRA fetch
func (jc *JiraClient) createErrorResult(jiraID string, err error) JiraTransitionResult {
	errorMsg := "Error: Could not retrieve issue"
	if err != nil {
		errorMsg = fmt.Sprintf("Error: %v", err)
		fmt.Fprintf(os.Stderr, "Failed to fetch JIRA %s: %v\n", jiraID, err)
	}

	return JiraTransitionResult{
		Key:         jiraID,
		Status:      ErrorStatus,
		Description: errorMsg,
		Type:        ErrorType,
		Project:     "",
		Created:     "",
		Updated:     "",
		Assignee:    nil,
		Reporter:    "",
		Priority:    "",
		Transitions: []Transition{},
	}
}

// createSuccessResult creates a result from a successfully fetched JIRA issue
func (jc *JiraClient) createSuccessResult(issue *jira.Issue) JiraTransitionResult {
	result := JiraTransitionResult{
		Key:         issue.Key,
		Status:      getStatusName(issue.Fields.Status),
		Description: getDescription(issue.Fields.Description),
		Type:        getIssueTypeName(issue.Fields.Type),
		Project:     getProjectKey(issue.Fields.Project),
		Created:     getTimeAsString(issue.Fields.Created),
		Updated:     getTimeAsString(issue.Fields.Updated),
		Assignee:    getAssignee(issue.Fields.Assignee),
		Reporter:    getReporterName(issue.Fields.Reporter),
		Priority:    getPriorityName(issue.Fields.Priority),
		Transitions: jc.extractTransitions(issue),
	}

	return result
}

// extractTransitions extracts status transitions from issue changelog
func (jc *JiraClient) extractTransitions(issue *jira.Issue) []Transition {
	var transitions []Transition

	if issue.Changelog == nil || len(issue.Changelog.Histories) == 0 {
		return transitions
	}

	for _, history := range issue.Changelog.Histories {
		for _, item := range history.Items {
			if item.Field == "status" {
				transition := Transition{
					FromStatus:     item.FromString,
					ToStatus:       item.ToString,
					Author:         history.Author.DisplayName,
					AuthorEmail:    history.Author.EmailAddress,
					TransitionTime: history.Created,
				}
				transitions = append(transitions, transition)
			}
		}
	}

	return transitions
}

// Helper function to extract description text from JIRA description field
func getDescription(desc interface{}) string {
	if desc == nil {
		return ""
	}

	// Handle the Atlassian Document Format (ADF) structure
	descMap, ok := desc.(map[string]interface{})
	if !ok {
		// Fallback to string representation
		return fmt.Sprintf("%v", desc)
	}

	content, ok := descMap["content"].([]interface{})
	if !ok {
		return fmt.Sprintf("%v", desc)
	}

	var result strings.Builder
	for _, item := range content {
		text := extractTextFromADFNode(item)
		if text != "" {
			result.WriteString(text)
		}
	}

	if result.Len() == 0 {
		return fmt.Sprintf("%v", desc)
	}
	return result.String()
}

// extractTextFromADFNode extracts text from an ADF node (paragraph, text, etc.)
func extractTextFromADFNode(node interface{}) string {
	nodeMap, ok := node.(map[string]interface{})
	if !ok {
		return ""
	}

	nodeType, _ := nodeMap["type"].(string)

	switch nodeType {
	case "paragraph":
		// Extract text from paragraph's content
		content, ok := nodeMap["content"].([]interface{})
		if !ok {
			return ""
		}

		var texts []string
		for _, item := range content {
			if text := extractTextFromADFNode(item); text != "" {
				texts = append(texts, text)
			}
		}
		return strings.Join(texts, "")

	case "text":
		// Direct text node
		text, _ := nodeMap["text"].(string)
		return text

	default:
		// Handle other node types if needed
		return ""
	}
}

// Field extractors for JIRA objects - all handle nil values safely

func getStatusName(status *jira.Status) string {
	if status == nil {
		return ""
	}
	return status.Name
}

func getIssueTypeName(issueType jira.IssueType) string {
	return issueType.Name
}

func getProjectKey(project jira.Project) string {
	return project.Key
}

func getReporterName(reporter *jira.User) string {
	if reporter == nil {
		return ""
	}
	return reporter.DisplayName
}

func getPriorityName(priority *jira.Priority) string {
	if priority == nil {
		return ""
	}
	return priority.Name
}

func getAssignee(assignee *jira.User) *string {
	if assignee == nil {
		return nil
	}
	return &assignee.DisplayName
}

// getTimeAsString converts various time representations to string format
func getTimeAsString(timeField interface{}) string {
	if timeField == nil {
		return ""
	}

	switch v := timeField.(type) {
	case string:
		return v
	case time.Time:
		return v.Format(JiraTimeFormat)
	case *time.Time:
		if v != nil {
			return v.Format(JiraTimeFormat)
		}
		return ""
	default:
		// Try JSON marshaling as last resort
		if jsonBytes, err := json.Marshal(timeField); err == nil {
			var timeStr string
			if json.Unmarshal(jsonBytes, &timeStr) == nil && timeStr != "" {
				return timeStr
			}
		}
		// Final fallback
		return fmt.Sprintf("%v", timeField)
	}
}
