package main

import (
	"fmt"
	"goapi/goapi"
	"net/http"
)

func hello(w http.ResponseWriter, req *http.Request, params ...any) {

	fmt.Fprintf(w, "hello\n")
}

func a(w http.ResponseWriter, req *http.Request) {

	fmt.Fprintf(w, "a\n")
}

func e(w http.ResponseWriter, req *http.Request) {

	fmt.Fprintf(w, "e\n")
}

func main() {

	// http.HandleFunc("/hello", hello)
	// http.HandleFunc("/headers", headers)

	app := goapi.NewApp("MyApp")
	app.Get("/", hello)
	app.Get("/a", a)
	app.Get("/a/b", hello)
	app.Get("/c", hello)
	app.Get("/c/d/e", hello)
	app.Get("/c/d/e", e)

	http.Handle("/", app)

	http.ListenAndServe(":8090", nil)
}
