module github.com/chimeh/s2ego

go 1.14

require (
	github.com/spf13/cobra v0.0.7
	github.com/spf13/pflag v1.0.5 // indirect
	github.com/spf13/viper v1.6.2
	golang.org/x/sys v0.0.0-20190412213103-97732733099d // indirect
	gopkg.in/yaml.v2 v2.2.4
)

replace github.com/chimeh/s2ego/pkg => ./pkg
