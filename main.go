package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "luax",
	Short: "Package Lua scripts into standalone executables",
	Long:  `luax is a tool that combines a Lua runtime with your Lua scripts to create cross-platform executable applications with TUI support.`,
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

var evalCmd = &cobra.Command{
	Use:   "eval [lua-script]",
	Short: "Evaluate and run a Lua script directly",
	Long:  `Run a Lua script directly without building an executable. Useful for development and testing.`,
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		scriptPath := args[0]
		
		if err := evalScript(scriptPath); err != nil {
			fmt.Fprintf(os.Stderr, "Error running script: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	buildCmd.Flags().StringP("output", "o", "", "Output executable name")
	buildCmd.Flags().StringP("target", "t", "current", "Target platform (current, linux, windows, darwin)")
	rootCmd.AddCommand(buildCmd)
	rootCmd.AddCommand(evalCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

