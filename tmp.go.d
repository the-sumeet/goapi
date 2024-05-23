package main

import (
	"fmt"
	"strings"
)

func main() {

	a := strings.Split("/a/b/c", "/")
	fmt.Println(len(a))
	for _, v := range a {
		println(v)
	}

}
