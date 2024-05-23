package goapi

import "regexp"

type routeRegexp struct {
	// The unmodified template.
	template string
	// Expanded regexp.
	regexp *regexp.Regexp
	// Reverse template.
	reverse string
	// Variable names.
	varsN []string
	// Variable regexps (validators).
	varsR []*regexp.Regexp
}
