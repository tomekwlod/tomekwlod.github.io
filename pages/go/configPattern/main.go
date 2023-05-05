// https://www.youtube.com/watch?v=MDy7JQN5MN4

package main

import "fmt"

type OptFunc func(*Opts)

type Opts struct {
	maxConn int
	id      string
	tls     bool
}

func withTLS(opts *Opts) {
	fmt.Println("tls exec")
	opts.tls = true
}
func withMaxConn(n int) OptFunc {
	fmt.Println("maxconn init")
	return func(opts *Opts) {
		fmt.Println("maxconn exec")
		opts.maxConn = n
	}
}

func defaultOpts() Opts {
	return Opts{
		maxConn: 10,
		id:      "default",
		tls:     false,
	}
}

type Server struct {
	Opts
}

func newServer(opts ...OptFunc) *Server {
	o := defaultOpts()

	for _, fn := range opts {
		fn(&o)
	}

	return &Server{
		Opts: o,
	}
}

func main() {
	s := newServer(withTLS, withMaxConn(99))

	fmt.Printf("%+v\n", s)
}

// note that you will see 'maxconn init' string printed before 'tls exec' and 'maxconn exec'
// because we initialize withMaxConn() function straight in line 52 whereas
// tls&maxconn functions will be EXECUTED in line 43
