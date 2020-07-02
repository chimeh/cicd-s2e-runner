package pathenv

import (
	"bufio"
	"bytes"
	"fmt"
	"strconv"
	"time"

	//"fmt"
	"github.com/spf13/viper"
	yaml "gopkg.in/yaml.v2"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

//func initJSON(viper *viper.Viper) []string {
//
//	GITLAB_CI := os.Getenv("GITLAB_CI")
//	if GITLAB_CI != "true" {
//		log.Warn("Should be run on Gitlab CI")
//	}
//	CI_PROJECT_PATH := os.Getenv("CI_PROJECT_PATH")
//	s := strings.Split(CI_PROJECT_PATH, "/")
//	ls := len(s)
//	projOrg := "default"
//	projNs := "default"
//	if ls < 2 {
//		log.Warn("CI_PROJECT_PATH should be org-group/project-group")
//	} else {
//		projOrg := s[0]
//		projNs := s[1]
//	}
//
//	viper.SetConfigType("yaml")
//	r := bytes.NewReader(jsonExample)
//	v.
//	unmarshalReader(r, v.config)
//	BindEnv("id")
//	BindEnv("f", "FOOD")
//
//	os.Setenv("ID", "13")
//	os.Setenv("FOOD", "apple")
//	os.Setenv("NAME", "crunk")
//
//	assert.Equal(t, "13", Get("id"))
//	assert.Equal(t, "apple", Get("f"))
//	assert.Equal(t, "Cake", Get("name"))
//
//	AutomaticEnv()
//
//	assert.Equal(t, "crunk", Get("name"))
//}

func yamlStringSettings(viper *viper.Viper) string {
	c := viper.AllSettings()
	bs, err := yaml.Marshal(c)
	if err != nil {
		log.Fatalf("unable to marshal config to YAML: %v", err)
	}
	return string(bs)
}
func EnvStr2Map(env []string) map[string]string {
	str2map := func(env []string, getkv func(item string) (key, val string)) map[string]string {
		items := make(map[string]string)
		for _, item := range env {
			key, val := getkv(item)
			items[key] = val
		}
		return items
	}
	envmap := str2map(env, func(item string) (k, v string) {
		splits := strings.Split(item, "=")
		k = splits[0]
		v = strings.Join(splits[1:], "=")
		return
	})
	return envmap
}

func EnvMap2Str(envmap map[string]string) []string {
	var env []string
	var item string
	for k, v := range envmap {
		item = k + "=" + strconv.Quote(v)
		env = append(env, item)
	}
	return env
}

func calcPathEnv(viper *viper.Viper) ([]string, []string) {
	oldEnv := os.Environ()
	oldEnvMap := EnvStr2Map(oldEnv)
	newEnvMap := EnvStr2Map(oldEnv)
	detaEnvMap := EnvStr2Map([]string{})
	//fmt.Print(envmap)
	GITLAB_CI := oldEnvMap["GITLAB_CI"]
	if GITLAB_CI != "true" {
		log.Println("Should be run on Gitlab CI, otherwise export CI_PROJECT_PATH")
	}
	CI_PROJECT_PATH := oldEnvMap["CI_PROJECT_PATH"]
	s := strings.Split(CI_PROJECT_PATH, "/")
	projOrg := "default"
	projNs := "default"
	if len(s) < 2 {
		log.Println("CI_PROJECT_PATH should be org-group/project-group")
	} else {
		projOrg = strings.ToLower(s[0])
		projNs = strings.ToLower(s[1])
	}
	newEnvMap["S2E_ORG"] = projOrg
	newEnvMap["S2E_NS"] = projNs
	detaEnvMap["S2E_ORG"] = projOrg
	detaEnvMap["S2E_NS"] = projNs
	now := time.Now() // current local time
	sec := now.Unix() // number of seconds since January 1, 1970 UTC; eg, shell `date +%s`
	newEnvMap["S2E_CALLED_TIME"] = strconv.FormatInt(sec, 10)
	detaEnvMap["S2E_CALLED_TIME"] = strconv.FormatInt(sec, 10)
	log.Printf("org group: %s project group: %s", projOrg, projNs)
	nodePath := ""
	node := ""
	for _, node = range s {
		nodePath = strings.Join([]string{nodePath, node}, "")
		nodePathEnv := nodePath + "." + "_pathenv"
		log.Println(nodePathEnv)
		viperCur := viper.Sub(nodePathEnv)
		if viperCur == nil {
			continue
		}
		for _, k := range viperCur.AllKeys() {
			v := viperCur.GetString(k)
			uk := strings.ToUpper(k)
			//log.Println(uk, v)
			if v != "" {
				newEnvMap[uk] = v
			}
			oldV, ok := oldEnvMap[uk]
			if !ok || newEnvMap[uk] != oldV {
				detaEnvMap[uk] = v
				//log.Println(uk, v)
			}
		}
		nodePath = strings.Join([]string{nodePath, "."}, "")
	}

	newEnv := EnvMap2Str(newEnvMap)
	detaEnv := EnvMap2Str(detaEnvMap)
	log.Println(detaEnv)
	return newEnv, detaEnv
}
func writeLines(lines []string, path string) error {
	file, _ := os.Create(path)

	defer file.Close()

	w := bufio.NewWriter(file)
	for _, line := range lines {
		fmt.Fprintln(w, line)
	}
	return w.Flush()
}
func OsExecute(viper *viper.Viper, args []string) {
	const detaEnvFile = "./s2ectl.env"
	const newEnvFile = "./s2ectl.env.new"
	newEnv, detaEnv := calcPathEnv(viper)
	if len(detaEnv) > 0 {
		writeLines(detaEnv, detaEnvFile)
		log.Printf("Save %s detaEnvFile\n", detaEnvFile)
	}
	if "" != os.Getenv("S2IECTL_DEBUG") {
		if len(newEnv) > 0 {
			writeLines(newEnv, newEnvFile)
			log.Printf("Save %s newEnvFile\n", newEnvFile)
		}
	}

	invoke_args := ""
	for _, v := range args[1:] {
		invoke_args += " "
		invoke_args += v
	}
	invoke_cmd := args[0]
	execcmd := exec.Command(invoke_cmd)
	//fmt.Println(invoke_cmd, args)
	//fmt.Println(newEnv)
	execcmd.Args = args
	execcmd.Env = newEnv

	var stdBuffer bytes.Buffer
	mw := io.MultiWriter(os.Stdout, &stdBuffer)

	execcmd.Stdout = mw
	execcmd.Stderr = mw
	log.Println("")
	if err := execcmd.Run(); err != nil {
		log.Panic(err)
	}

	//log.Println(stdBuffer.String())
	//_, err := execcmd.StdoutPipe()
	//if err != nil {
	//	log.Fatal(err)
	//}
	//_, err = execcmd.StderrPipe()
	//if err != nil {
	//	log.Fatal(err)
	//}
	//if err := execcmd.Start(); err != nil {
	//	log.Fatal(err)
	//}
	//if err := execcmd.Wait(); err != nil {
	//	log.Fatal(err)
	//}
	//stdoutStderr, err := execcmd.CombinedOutput()
	//fmt.Printf("%s\n", stdoutStderr)
	//if err != nil {
	//	log.Fatal(err)
	//}
	//fmt.Printf("%s\n", stdoutStderr)
}
