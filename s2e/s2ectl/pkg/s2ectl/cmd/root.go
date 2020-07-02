/*
Copyright © 2020 jimin.huang

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"bytes"
	"fmt"
	"github.com/spf13/cobra"
	//"log"
	"os"

	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "s2ectl",
	Short: "A brief description of your application",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print("s2ectl tool.")
	},
}

type S2eCtl struct {
	*cobra.Command
	cfgFile string
	*viper.Viper
}

var S2E = &S2eCtl{
	Command: rootCmd,
	cfgFile: cfgFile,
	Viper:   viper.GetViper(),
}
var configExample = []byte(`zorg:
    _pathenv:
        DOCKER_REPO: docker.io
        DOCKER_NS: default
        K8S_NS: ""
        INGRESS_CLASS_PUBLIC: nginx
        INGRESS_CLASS_INTERNAL: nginx
        DEV_KUBECONFIG: /root/.kube/config
        DEV_K8S_NS_SUFFIX: "-dev"
        DEV_INGRESS_CLASS_INTERNAL: nginx
        DEV_INGRESS_CLASS_PUBLIC: nginx
        DEV_INGRESS_INTERNAL_ENABLED: true
        DEV_INGRESS_PUBLIC_ENABLED: true
        TEST_K8S_NS_SUFFIX: "-test"
        TEST_KUBECONFIG: /root/.kube/config
        TEST_INGRESS_CLASS_INTERNAL: nginx
        TEST_INGRESS_CLASS_PUBLIC: nginx
        TEST_INGRESS_INTERNAL_ENABLED: true
        TEST_INGRESS_PUBLIC_ENABLED: true
        UAT_K8S_NS_SUFFIX: "-uat"
        UAT_KUBECONFIG: /root/.kube/config
        UAT_INGRESS_CLASS_INTERNAL: nginx
        UAT_INGRESS_CLASS_PUBLIC: nginx
        UAT_INGRESS_INTERNAL_ENABLED: true
        UAT_INGRESS_PUBLIC_ENABLED: true
        PRD_K8S_NS_SUFFIX: "-prd"
        PRD_KUBECONFIG: /root/.kube/config
        PRD_INGRESS_CLASS_INTERNAL: nginx
        PRD_INGRESS_CLASS_PUBLIC: nginx
        PRD_INGRESS_INTERNAL_ENABLED: true
        PRD_INGRESS_PUBLIC_ENABLED: false
`)

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.s2ectl/config)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		home, err := os.UserHomeDir()
		cfgpath := home + "/.s2ectl"
		err = os.MkdirAll(cfgpath, os.ModePerm)
		fmt.Println(err)
		viper.SetConfigName("config")
		viper.AddConfigPath(cfgpath)
		viper.AddConfigPath("/etc/s2ectl")
	}

	viper.AutomaticEnv() // read in environment variables that match
	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err != nil {
		r := bytes.NewBuffer(configExample)
		viper.SetConfigType("yaml")
		if err := viper.ReadConfig(r); err != nil {
			fmt.Println(err)
		}
		if err := viper.SafeWriteConfig(); err != nil {
			fmt.Println(err)
		}
	}
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// Config file not found; ignore error if desired
			fmt.Println(" Config file not found;")
		} else {
			// Config file was found but another error was produced
			fmt.Println("Error Using config file:", viper.ConfigFileUsed())
		}
	}
	fmt.Println("Using config file:", viper.ConfigFileUsed())

	//viper.WatchConfig()
	//viper.OnConfigChange(func(e fsnotify.Event) {
	//	fmt.Println("Config file changed:", e.Name)
	//})
}
