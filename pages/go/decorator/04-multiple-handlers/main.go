package main

import (
	"fmt"
	"net/http"
)

type DB interface {
	Save(string) error
}

type Store struct{}

func (s *Store) Save(str string) error {
	fmt.Println("Saving " + str + " to the DB")
	return nil
}

func myOwnFn(db DB) ExecuteFn {
	return func(s string) {
		fmt.Println("myOwnFn", s)

		// now we can access the db like so
		db.Save(s)
	}
}

func handler(db DB, fn httpFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := fn(db, w, r); err != nil {
			// error handling here
		}
	}
}

func homepageHandler(db DB, w http.ResponseWriter, r *http.Request) error {
	return nil
}

type httpFunc func(db DB, w http.ResponseWriter, r *http.Request) error

func main() {
	store := &Store{}

	http.HandleFunc("/", handler(store, homepageHandler))

	Execute(myOwnFn(store))
}

// this is a 3rd party lib for example
type ExecuteFn func(string)

func Execute(fn ExecuteFn) {
	fn("something")
}
