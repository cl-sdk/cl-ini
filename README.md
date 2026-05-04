# cl-ini

A Common Lisp INI file reader and writer.

> Note: `cl-ini` is a temporary name because it is already taken on Quicklisp.

## Installation

Clone the repository into your local Quicklisp projects directory, then load with ASDF or Quicklisp:

```lisp
(ql:quickload :cl-ini)
```

## Usage

### Reading an INI file

```lisp
;; Parse an INI string
(cl-ini:parse-ini "[section]
key = value
other = 42")
;; => (("section" ("key" . "value") ("other" . "42")))

;; Read from a file
(cl-ini:read-ini #p"config.ini")
;; => (("section" ("key" . "value")))
```

### Writing an INI file

```lisp
;; Write INI data to a string
(cl-ini:write-ini-to-string '(("section" ("key" . "value") ("other" . "42"))))
;; => "[section]
;; key = value
;; other = 42
;; "

;; Write to a file
(cl-ini:write-ini '(("section" ("key" . "value"))) #p"config.ini")
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
(ql:quickload :cl-ini.test)
(fiveam:run! :cl-ini)
```

## License

This software is released into the public domain. See [LICENSE](LICENSE) for details.
