now, say we want to have a handler but with the db support

normally our handler may look like:
```
func handler(w http.ResponseWriter, r *http.Request) {
	// we want a db here
}
```

and in main `http.HandleFunc("/", handler)`

In order to inject our DB interface to the handler we should modify it to something like:
```
func handler(db DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		db.Save("saved")
	}
}
```

where in main: `http.HandleFunc("/", handler(store))`