# An example implementation of functional, lazy
# sequences, as in clojure. The lazy seq is essentially
# A lazy linked list, where the next value is a function
# that must be called (realizing it), and the memoized.
# Use with (import "./path/to/this/file" :prefix "seq.")

(defmacro delay [& forms]
  "Lazily evaluate a series of expressions. Returns a function that
  returns the result of the last expression. Will only evaluate the
  body once, and then memoizes the result."
  (def $state (gensym))
  (def $loaded (gensym))
  (tuple 'do
         (tuple 'var $state nil)
         (tuple 'var $loaded nil)
         (tuple 'fn (array)
                (tuple 'if $loaded
                       $state
                       (tuple 'do
                              (tuple ':= $loaded true)
                              (tuple ':= $state (tuple.prepend forms 'do)))))))

# Use tuples instead of structs to save memory
(def HEAD :private 0)
(def TAIL :private 1)

(defn empty-seq
  "The empty sequence."
  [] nil)

(defmacro cons
  "Create a new sequence by prepending a value to the original sequence."
  [h t]
  (def x (tuple h t))
  (fn [] x))

(defn empty?
  "Check if a sequence is empty."
  [s]
  (not (s)))

(defn head
  "Get the next value of the sequence."
  [s]
  (get (s) HEAD))

(defn tail
  "Get the rest of a sequence"
  [s]
  (get (s) TAIL))

(defn range2
  "Return a sequence of integers [start, end)."
  [start end]
  (if (< start end)
    (delay (tuple start (range2 (+ 1 start) end)))
    empty-seq))

(defn range
  "Return a sequence of integers [0, end)."
  [end]
  (range2 0 end))

(defn map
  "Return a sequence that is the result of applying f to each value in s."
  [f s]
  (delay
    (def x (s))
    (if x (tuple (f (get x HEAD)) (map f (get x TAIL))))))

(defn realize
  "Force evaluation of a lazy sequence."
  [s]
  (when (s) (realize (tail s))))

(defn realize-map [f s]
  "Evaluate f on each member of the sequence. Forces evaluation."
  (when (s) (f (head s)) (realize-map f (tail s))))

(defn drop
  "Ignores the first n values of the sequence and returns the rest."
  [n s]
  (delay
    (def x (s))
    (if (and x (pos? n)) ((drop (- n 1) (get x TAIL))))))

(defn take
  "Returns at most the first n values of s."
  [n s]
  (delay
    (def x (s))
    (if (and x (pos? n))
      (tuple (get x HEAD) (take (- n 1) (get x TAIL))))))

(defn randseq
  "Return a sequence of random numbers."
  []
  (delay (tuple (random) (randseq))))

(defn take-while
  "Returns a sequence of values until the predicate is false."
  [pred s]
  (delay
    (def x (s))
    (when x
      (def thehead (get HEAD x))
      (if thehead (tuple thehead (take-while pred (get TAIL x)))))))