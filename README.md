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

### Schema-based parsing

`parse-ini` accepts an optional *schema* as its second argument. The schema
declares the expected type of each key.  Values are coerced to their declared
type, required keys are enforced, and missing optional keys can be filled with
defaults.

```lisp
(cl-ini:parse-ini
  "[server]
host = localhost
port = 8080
debug = true"
  '(("server"
     ("host"  . :string)          ; simple type spec
     ("port"  . :integer)         ; coerced to integer
     ("debug" . :boolean)         ; coerced to boolean
     ("timeout" :type :integer    ; full plist spec
                :default 30
                :required nil))))
;; => (("server" ("host" . "localhost") ("port" . 8080) ("debug" . T) ("timeout" . 30)))
```

`parse-ini-with-schema` and `read-ini-with-schema` are convenience wrappers.

#### Key specification formats

| Format | Example |
|--------|---------|
| Simple dotted pair | `("key" . :integer)` |
| Full property list | `("key" :type :integer :default 0 :required t)` |

#### Supported types

| Type | Description |
|------|-------------|
| `:string` | Leave the value as a string (the default) |
| `:integer` | Parse as a decimal integer |
| `:float` | Parse as a floating-point number |
| `:boolean` | `"true"`, `"yes"`, `"on"`, `"1"` → `T`; `"false"`, `"no"`, `"off"`, `"0"` → `NIL` |

#### Error handling

`cl-ini:ini-schema-error` is signalled when:
- A value cannot be coerced to its declared type.
- A key marked `:required t` is absent from the section.

```lisp
(handler-case
    (cl-ini:parse-ini-with-schema "[s]
n = not-a-number" '(("s" ("n" . :integer))))
  (cl-ini:ini-schema-error (e)
    (format t "Schema error: ~a~%" (cl-ini:ini-schema-error-message e))))
;; => Schema error: cannot coerce "not-a-number" to integer
```

#### Applying a schema to already-parsed data

`cl-ini:apply-schema` accepts the alist returned by `parse-ini` directly,
which is convenient when you want to parse once and validate later:

```lisp
(let ((ini (cl-ini:parse-ini "[section]
n = 42")))
  (cl-ini:apply-schema ini '(("section" ("n" . :integer)))))
;; => (("section" ("n" . 42)))
```

### Writing an INI file

```lisp
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
