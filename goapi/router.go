package goapi

// import "net/http"

// type Router struct {
// 	// Configurable Handler to be used when no route matches.
// 	// This can be used to render your own 404 Not Found errors.
// 	NotFoundHandler http.Handler

// 	// Configurable Handler to be used when the request method does not match the route.
// 	// This can be used to render your own 405 Method Not Allowed errors.
// 	MethodNotAllowedHandler http.Handler

// 	// Routes to be matched, in order.
// 	routes []*Route

// 	// Routes by name for URL building.
// 	namedRoutes map[string]*Route

// 	// Slice of middlewares to be called after a match is found
// 	// middlewares []middleware
// }

// func (r *Router) NewRoute() *Route {
// 	// initialize a route with a copy of the parent router's configuration
// 	route := &Route{namedRoutes: r.namedRoutes}
// 	r.routes = append(r.routes, route)
// 	return route
// }

// type Route struct {
// 	// Request handler for the route.
// 	handler    func(w http.ResponseWriter, req *http.Request)
// 	getHandler func(w http.ResponseWriter, req *http.Request)
// 	// If true, this route never matches: it is only used to build URLs.
// 	buildOnly bool
// 	// The name used to build URLs.
// 	name string
// 	// Error resulted from building a route.
// 	err error

// 	// "global" reference to all named routes
// 	namedRoutes map[string]*Route

// 	matcher string
// }
