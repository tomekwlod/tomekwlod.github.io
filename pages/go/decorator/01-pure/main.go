package main

import "fmt"

func myOwnFn(s string) {
	fmt.Println("myOwnFn", s)
}

func main() {
	Execute(myOwnFn)
}

// this is a 3rd party lib for example
type ExecuteFn func(string)

func Execute(fn ExecuteFn) {
	fn("something")
}
