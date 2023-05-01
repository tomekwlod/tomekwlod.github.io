package main

import "fmt"

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

func main() {
	store := &Store{}

	Execute(myOwnFn(store))
}

// this is a 3rd party lib for example
type ExecuteFn func(string)

func Execute(fn ExecuteFn) {
	fn("something")
}
