now let's say we want to inject something to our myOwnFn. We could use a global but it's not ideal.

- so we define our DB interface and implement it with our Store

```
type DB interface {
  Save(string) error
}

type Store struct{}

func (s *Store) Save(str string) error {
  fmt.Println("Saving " + str + " to the DB")
  return nil
}
```

- next we can modify our myOwnFn so it takes the db interface. It has to return the type of the 3rd party function in order to satisfy this type

```
func myOwnFn(db DB) ExecuteFn {
	return func(s string) {
		fmt.Println("myOwnFn", s)

		// now we can access the db like so
		db.Save(s)
	}
}
```

- then in a main function we can initialize our store and pass it to the modified own function:

```
func main() {
	store := &Store{}

	Execute(myOwnFn(store))
}
```
