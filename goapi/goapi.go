package goapi

import (
	"errors"
	"net/http"
	"strings"
)

var (
	ErrInvalidRouteToAddEmpty  = errors.New("route must not be empty or start with  \"/\"")
	ErrInvalidRouteToAddPrefix = errors.New("route must start with  \"/\"")
	ErrInvalidRouteToAddSuffix = errors.New("route must not end with  \"/\"")
)

type CustomHandler func(http.ResponseWriter, *http.Request, ...any)

type Route struct {
	partName string
	// Children are the next parts of the route
	// For example, if the part is hello
	// The children of hello can be world forming path hello/world
	children []*Route
	// The method strings should be smeller in smaller case like get, post, put, delete
	handlers map[string]CustomHandler
}

type App struct {
	Name   string
	route  *Route
	Server *http.Server
}

func (a *App) Get(path string, handler func(w http.ResponseWriter, req *http.Request, params ...any)) {

	if len(path) > 1 && strings.HasSuffix(path, "/") {
		panic(ErrInvalidRouteToAddSuffix)
	}

	var currentRoute *Route
	for _, part := range strings.Split(path, "/") {
		if part == "" {
			// Starting from root path
			if a.route == nil {
				a.route = &Route{
					partName: "",
				}
			}
			currentRoute = a.route
			continue
		} else {
			if currentRoute.children == nil {
				currentRoute.children = make([]*Route, 0)
				newPart := Route{
					partName: part,
				}
				currentRoute.children = append(currentRoute.children, &newPart)
				currentRoute = &newPart
				continue
			}

			for _, child := range currentRoute.children {
				if child.partName == part {
					currentRoute = child
					break
				}
			}

			if !(currentRoute.partName == part) {
				newPart := Route{
					partName: part,
				}
				currentRoute.children = append(currentRoute.children, &newPart)
				currentRoute = &newPart
			}
		}

	}

	if currentRoute.handlers == nil {
		currentRoute.handlers = make(map[string]CustomHandler)
	}
	currentRoute.handlers["get"] = handler

}

func (a *App) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if len(path) > 1 && strings.HasSuffix(path, "/") {
		panic(ErrInvalidRouteToAddSuffix)
	}

	var currentRoute *Route
	for _, part := range strings.Split(path, "/") {
		if part == "" {
			// Starting from root path
			if a.route == nil {
				break
			}
			currentRoute = a.route
			continue
		} else {
			if currentRoute.children != nil {
				for _, child := range currentRoute.children {
					if child.partName == part {
						currentRoute = child
						break
					}
				}
			} else {
				NotFound(w, r)
				return
			}

			if currentRoute.partName != part {
				NotFound(w, r)
				return
			}
		}

	}

	if currentRoute.handlers == nil {
		NotFound(w, r)
		return
	}

	handler, ok := currentRoute.handlers["get"]
	if ok {
		handler(w, r)
	} else {
		// Requested method not there for route
		NotFound(w, r)
		return
	}
}

func NotFound(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("404 Not Found"))
}

func NewApp(name string) *App {
	return &App{Name: name}
}
