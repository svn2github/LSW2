(let ((*load-verbose* nil)
      (*compile-verbose* nil)
      (*suppress-compiler-warnings* (not *load-verbose*)))
  (asdf::oos 'asdf::load-op 'owl2 :verbose nil)
  (asdf::oos 'asdf::load-op 'inspect :verbose nil))
