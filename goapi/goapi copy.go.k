package goapi

import (
	"bytes"
	"errors"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"strings"
)

var (
	ErrInvalidRouteToAddEmpty  = errors.New("route must not be empty or start with  \"/\"")
	ErrInvalidRouteToAddPrefix = errors.New("route must start with  \"/\"")
	ErrInvalidRouteToAddSuffix = errors.New("route must not start with  \"/\"")
)

type App struct {
	Name   string
	routes []*Route
	Server *http.Server
}

func (a *App) ServeHTTP(w http.ResponseWriter, r *http.Request) {

}

func (a *App) HandleFunc(path string, f func(http.ResponseWriter, *http.Request)) *Route {
	return a.router.NewRoute().Path(path).HandlerFunc(f)
}

func (a *App) AddRouter(path string, handler http.HandlerFunc) error {

	currentRoot := a.RootPath
	paths := strings.Split(path, "/")
	for _, path := range paths {
		if path == "" {
			if a.RootPath == nil {
				a.RootPath = &Route{
					name: "",
				}
				currentRoot = a.RootPath
			}
		} else {
			if currentRoot.childRoutes == nil {
				currentRoot.childRoutes = make(map[string]*Route)
			}
			childRoute, ok := currentRoot.childRoutes[path]
			if ok {
				currentRoot = childRoute
				continue
			} else {
				currentRoot.childRoutes[path] = &Route{
					name: path,
				}
				currentRoot = currentRoot.childRoutes[path]
			}

		}

		if currentRoot != nil {
			currentRoot.handler = handler
		}
	}

	return nil
}

func newRouteRegexp(tpl string) (*routeRegexp, error) {
	// Check if it is well-formed.
	idxs, errBraces := braceIndices(tpl)
	if errBraces != nil {
		return nil, errBraces
	}
	// Backup the original.
	template := tpl
	// Now let's parse it.
	defaultPattern := "[^/]+"
	// if typ == regexpTypeQuery {
	// 	defaultPattern = ".*"
	// } else if typ == regexpTypeHost {
	// 	defaultPattern = "[^.]+"
	// }
	// Only match strict slash if not matching
	// if typ != regexpTypePath {
	// 	options.strictSlash = false
	// }
	// Set a flag for strictSlash.
	// endSlash := false
	// if options.strictSlash && strings.HasSuffix(tpl, "/") {
	// 	tpl = tpl[:len(tpl)-1]
	// 	endSlash = true
	// }
	varsN := make([]string, len(idxs)/2)
	varsR := make([]*regexp.Regexp, len(idxs)/2)
	pattern := bytes.NewBufferString("")
	pattern.WriteByte('^')
	reverse := bytes.NewBufferString("")
	var end int
	var err error
	for i := 0; i < len(idxs); i += 2 {
		// Set all values we are interested in.
		raw := tpl[end:idxs[i]]
		end = idxs[i+1]

		name := tpl[idxs[i]+1 : end-1]
		// Name or pattern can't be empty.
		if name == "" {
			return nil, fmt.Errorf("goapi: missing name in %q",
				tpl[idxs[i]:end])
		}
		// Build the regexp pattern.
		fmt.Fprintf(pattern, "%s(?P<%s>)", regexp.QuoteMeta(raw), varGroupName(i/2), defaultPattern)

		// Build the reverse template.
		fmt.Fprintf(reverse, "%s%%s", raw)

		// Append variable name and compiled pattern.
		varsN[i/2] = name
		varsR[i/2], err = regexp.Compile(fmt.Sprintf("^%s$", defaultPattern))
		if err != nil {
			return nil, err
		}
	}
	// Add the remaining.
	raw := tpl[end:]
	pattern.WriteString(regexp.QuoteMeta(raw))
	// if options.strictSlash {
	pattern.WriteString("[/]?")
	// }

	// if typ == regexpTypeQuery {
	// 	// Add the default pattern if the query value is empty
	// 	if queryVal := strings.SplitN(template, "=", 2)[1]; queryVal == "" {
	// 		pattern.WriteString(defaultPattern)
	// 	}
	// }
	// if typ != regexpTypePrefix {
	// 	pattern.WriteByte('$')
	// }

	// var wildcardHostPort bool
	// if typ == regexpTypeHost {
	// 	if !strings.Contains(pattern.String(), ":") {
	// 		wildcardHostPort = true
	// 	}
	// }
	// reverse.WriteString(raw)
	// if endSlash {
	// 	reverse.WriteByte('/')
	// }
	// Compile full regexp.
	reg, errCompile := regexp.Compile(pattern.String())
	if errCompile != nil {
		return nil, errCompile
	}

	// Check for capturing groups which used to work in older versions
	if reg.NumSubexp() != len(idxs)/2 {
		panic(fmt.Sprintf("route %s contains capture groups in its regexp. ", template) +
			"Only non-capturing groups are accepted: e.g. (?:pattern) instead of (pattern)")
	}

	// Done!
	return &routeRegexp{
		template: template,
		regexp:   reg,
		reverse:  reverse.String(),
		varsN:    varsN,
		varsR:    varsR,
	}, nil
}
func varGroupName(idx int) string {
	return "v" + strconv.Itoa(idx)
}
func braceIndices(s string) ([]int, error) {
	var level, idx int
	var idxs []int
	for i := 0; i < len(s); i++ {
		switch s[i] {
		case '{':
			if level++; level == 1 {
				idx = i
			}
		case '}':
			if level--; level == 0 {
				idxs = append(idxs, idx, i+1)
			} else if level < 0 {
				return nil, fmt.Errorf("mux: unbalanced braces in %q", s)
			}
		}
	}
	if level != 0 {
		return nil, fmt.Errorf("mux: unbalanced braces in %q", s)
	}
	return idxs, nil
}
func NewApp(name string) *App {
	return &App{
		Name: name,
	}
}
