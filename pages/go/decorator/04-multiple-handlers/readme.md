all good but say we need more handlers, obviously

lets create our function type (sort of an interface) that we will follow for each handler we create (https://youtu.be/GipAZwKFgoA?t=753)

```
type httpFunc (db DB, w http.ResponseWriter, r *http.Request)
```

we say that all our handlers need a db, req and resp

now we have to modify our handler to take this type as an argument:

```
func handler(db DB, fn httpFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := fn(db, w, r); err != nil {
			// error handling here
		}
	}
}
```

now let's actually create our handler:

```
func homepageHandler(db DB, w http.ResponseWriter, r *http.Request) error {
	return nil
}
```

and in main: `http.HandleFunc("/", handler(store, homepageHandler))`
(https://youtu.be/GipAZwKFgoA?t=799)
