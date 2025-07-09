package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestBuildExecutable(t *testing.T) {
	testScript := `
-- Simple test script
local app = tui.newApp()
local textView = tui.newTextView("Test successful!")
app:SetRoot(textView, true)
print("Lua script executed successfully")
`

	// Create temporary test script
	tempDir, err := os.MkdirTemp("", "luax-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	scriptPath := filepath.Join(tempDir, "test.lua")
	if err := os.WriteFile(scriptPath, []byte(testScript), 0644); err != nil {
		t.Fatalf("Failed to write test script: %v", err)
	}

	outputPath := filepath.Join(tempDir, "test-app")
	
	// Test building executable
	err = buildExecutable(scriptPath, outputPath, "current")
	if err != nil {
		t.Fatalf("buildExecutable failed: %v", err)
	}

	// Check if executable was created
	expectedPath := outputPath
	if runtime.GOOS == "windows" {
		expectedPath += ".exe"
	}

	if _, err := os.Stat(expectedPath); os.IsNotExist(err) {
		t.Fatalf("Executable was not created at %s", expectedPath)
	}

	// Test that the executable is actually executable
	if runtime.GOOS != "windows" {
		info, err := os.Stat(expectedPath)
		if err != nil {
			t.Fatalf("Failed to stat executable: %v", err)
		}
		if info.Mode()&0111 == 0 {
			t.Fatalf("Executable does not have execute permissions")
		}
	}
}

func TestBuildExecutableCrossPlatform(t *testing.T) {
	testScript := `print("Cross-platform test")`

	tempDir, err := os.MkdirTemp("", "luax-cross-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	scriptPath := filepath.Join(tempDir, "cross-test.lua")
	if err := os.WriteFile(scriptPath, []byte(testScript), 0644); err != nil {
		t.Fatalf("Failed to write test script: %v", err)
	}

	targets := []string{"linux", "windows", "darwin"}
	
	for _, target := range targets {
		t.Run(target, func(t *testing.T) {
			outputPath := filepath.Join(tempDir, "cross-test-"+target)
			
			err := buildExecutable(scriptPath, outputPath, target)
			if err != nil {
				t.Fatalf("buildExecutable failed for %s: %v", target, err)
			}

			expectedPath := outputPath
			if target == "windows" {
				expectedPath += ".exe"
			}

			if _, err := os.Stat(expectedPath); os.IsNotExist(err) {
				t.Fatalf("Executable was not created for %s at %s", target, expectedPath)
			}
		})
	}
}

func TestBuildExecutableInvalidScript(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "luax-invalid-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Test with non-existent script
	nonExistentScript := filepath.Join(tempDir, "nonexistent.lua")
	outputPath := filepath.Join(tempDir, "should-not-exist")

	err = buildExecutable(nonExistentScript, outputPath, "current")
	if err == nil {
		t.Fatalf("Expected error for non-existent script, but got none")
	}

	if !strings.Contains(err.Error(), "failed to resolve dependencies") {
		t.Fatalf("Expected 'failed to resolve dependencies' error, got: %v", err)
	}
}

func TestIntegrationCLI(t *testing.T) {
	// First build the luax binary
	cmd := exec.Command("go", "build", "-o", "luax-test", ".")
	if err := cmd.Run(); err != nil {
		t.Fatalf("Failed to build luax binary: %v", err)
	}
	defer os.Remove("luax-test")

	// Create a simple test script
	testScript := `
local app = tui.newApp()
local textView = tui.newTextView("CLI Test")
print("CLI integration test passed")
os.exit(0)
`

	tempDir, err := os.MkdirTemp("", "luax-cli-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	scriptPath := filepath.Join(tempDir, "cli-test.lua")
	if err := os.WriteFile(scriptPath, []byte(testScript), 0644); err != nil {
		t.Fatalf("Failed to write test script: %v", err)
	}

	outputPath := filepath.Join(tempDir, "cli-test-app")

	// Test CLI build command
	cmd = exec.Command("./luax-test", "build", scriptPath, "-o", outputPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("CLI build command failed: %v\nOutput: %s", err, output)
	}

	// Check if executable was created
	expectedPath := outputPath
	if runtime.GOOS == "windows" {
		expectedPath += ".exe"
	}

	if _, err := os.Stat(expectedPath); os.IsNotExist(err) {
		t.Fatalf("CLI did not create executable at %s", expectedPath)
	}
}