# cl-ini

A Common Lisp INI file reader and writer.

> Note: `cl-ini` is a temporary name because it is already taken on Quicklisp.

## Installation

Clone the repository into your local Quicklisp projects directory, then load with ASDF or Quicklisp:

```lisp
(ql:quickload :io.github.diasbruno.ini)
```

## Usage

### Reading an INI file

```lisp
;; Parse an INI string
(io.github.diasbruno.ini:parse-ini "[section]
key = value
other = 42")
;; => (("section" ("key" . "value") ("other" . "42")))

;; Read from a file
(io.github.diasbruno.ini:read-ini #p"config.ini")
;; => (("section" ("key" . "value")))

;; You can also pass :parser to parse-ini/read-ini for custom event handling.
```

### Event-driven parser

`parse-ini` accepts a custom parser instance that subclasses `io.github.diasbruno.ini:ini-parser`.

```lisp
(defclass recording-parser (io.github.diasbruno.ini:ini-parser)
  ((events :initform '() :accessor events)))

(defmethod io.github.diasbruno.ini:ini-parser-begin-document ((parser recording-parser))
  (push '(:begin-document nil) (events parser)))

(defmethod io.github.diasbruno.ini:ini-parser-section ((parser recording-parser) section-name)
  (push (list :section section-name) (events parser)))

(defmethod io.github.diasbruno.ini:ini-parser-pair ((parser recording-parser) pair)
  (push (list :pair pair) (events parser)))

(defmethod io.github.diasbruno.ini:ini-parser-end-document ((parser recording-parser))
  (push '(:end-document nil) (events parser)))

(defmethod io.github.diasbruno.ini:ini-parser-result ((parser recording-parser))
  (nreverse (events parser)))

(io.github.diasbruno.ini:parse-ini "[section]
key = value"
                  :parser (make-instance 'recording-parser))
;; => ((:BEGIN-DOCUMENT NIL)
;;     (:SECTION "section")
;;     (:PAIR ("key" . "value"))
;;     (:END-DOCUMENT NIL))
```

### Writing an INI file

```lisp
;; Write INI data to a string
(io.github.diasbruno.ini:write-ini-to-string '(("section" ("key" . "value") ("other" . "42"))))
;; => "[section]
;; key = value
;; other = 42
;; "

;; Write to a file
(io.github.diasbruno.ini:write-ini '(("section" ("key" . "value"))) #p"config.ini")
```

## Data Format

INI data is represented as an association list of sections. Each section is a list whose first element is the section name (a string) and whose remaining elements are `(key . value)` cons pairs:

```lisp
(("section-name" ("key1" . "value1")
                 ("key2" . "value2"))
 ("other-section" ("foo" . "bar")))
```

## INI Format Support

- Sections: `[section-name]`
- Key/value pairs: `key = value` or `key: value`
- Comments: lines starting with `;` or `#` are ignored
- Whitespace around keys and values is trimmed

## Running Tests

```lisp
(ql:quickload :io.github.diasbruno.ini.test)
(fiveam:run! :io.github.diasbruno.ini)
```

## License

This software is released into the public domain. See [LICENSE](LICENSE) for details.
