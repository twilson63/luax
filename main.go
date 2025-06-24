package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// Version information - can be set at build time with -ldflags
var (
	version = "1.3.0"
	commit  = "unknown"
	date    = "unknown"
)

var rootCmd = &cobra.Command{
	Use:   "hype",
	Short: "Package Lua scripts into standalone executables",
	Long:  fmt.Sprintf(`hype %s - Lua Script to Executable Packager

hype is a tool that combines a Lua runtime with your Lua scripts to create 
cross-platform executable applications with TUI support.`, version),
}

var buildCmd = &cobra.Command{
	Use:   "build [lua-script]",
	Short: "Build a Lua script into an executable",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		scriptPath := args[0]
		outputName, _ := cmd.Flags().GetString("output")
		target, _ := cmd.Flags().GetString("target")
		
		fmt.Printf("Building %s into executable %s for %s\n", scriptPath, outputName, target)
		
		if err := buildExecutable(scriptPath, outputName, target); err != nil {
			fmt.Fprintf(os.Stderr, "Error building executable: %v\n", err)
			os.Exit(1)
		}
	},
}

var runCmd = &cobra.Command{
	Use:   "run [lua-script] -- [script-args...]",
	Short: "Run a Lua script directly",
	Long:  `Run a Lua script directly without building an executable. Useful for development and testing.

Any arguments after '--' are passed to the Lua script as command line arguments.

Examples:
  hype run server.lua
  hype run server.lua -- --port 8080 --dir ./public`,
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		scriptPath := args[0]
		scriptArgs := args[1:] // Pass remaining args to script
		
		if err := runScript(scriptPath, scriptArgs); err != nil {
			fmt.Fprintf(os.Stderr, "Error running script: %v\n", err)
			os.Exit(1)
		}
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number",
	Run: func(cmd *cobra.Command, args []string) {
		if version == "dev" {
			fmt.Printf("hype %s - Lua Script to Executable Packager\n", version)
			fmt.Printf("Commit: %s\n", commit)
			fmt.Printf("Built: %s\n", date)
		} else {
			fmt.Printf("hype %s - Lua Script to Executable Packager\n", version)
		}
	},
}

func init() {
	buildCmd.Flags().StringP("output", "o", "", "Output executable name")
	buildCmd.Flags().StringP("target", "t", "current", "Target platform (current, linux, windows, darwin)")
	rootCmd.AddCommand(buildCmd)
	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(versionCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

