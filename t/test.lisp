(in-package :cl-ini.test)

(def-suite :cl-ini
  :description "Tests for the cl-ini INI reader and writer.")

(in-suite :cl-ini)

;;; Reader tests

(test parse-empty-string
  (is (null (parse-ini ""))))

(test parse-section-only
  (let ((result (parse-ini "[section]")))
    (is (= 1 (length result)))
    (is (string= "section" (caar result)))
    (is (null (cdar result)))))

(test parse-section-with-pairs
  (let ((result (parse-ini "[section]
key = value
other = 42")))
    (is (= 1 (length result)))
    (let ((section (first result)))
      (is (string= "section" (car section)))
      (is (string= "value" (cdr (assoc "key" (cdr section) :test #'string=))))
      (is (string= "42" (cdr (assoc "other" (cdr section) :test #'string=)))))))

(test parse-multiple-sections
  (let ((result (parse-ini "[alpha]
a = 1
[beta]
b = 2")))
    (is (= 2 (length result)))
    (is (string= "alpha" (car (first result))))
    (is (string= "beta" (car (second result))))))

(test parse-ignores-comments
  (let ((result (parse-ini "; this is a comment
[section]
# another comment
key = value")))
    (is (= 1 (length result)))
    (let ((section (first result)))
      (is (= 1 (length (cdr section)))))))

(test parse-ignores-blank-lines
  (let ((result (parse-ini "

[section]

key = value

")))
    (is (= 1 (length result)))
    (is (string= "value" (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test parse-colon-separator
  (let ((result (parse-ini "[section]
key: value")))
    (is (string= "value"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test parse-trims-whitespace
  (let ((result (parse-ini "[section]
  key  =  value  ")))
    (let ((section (first result)))
      (is (string= "value"
                   (cdr (assoc "key" (cdr section) :test #'string=)))))))

(test parse-section-name-with-whitespace
  "Section names are trimmed of surrounding whitespace."
  (let ((result (parse-ini "[ section ]")))
    (is (= 1 (length result)))
    (is (string= "section" (caar result)))))

(test parse-empty-section-name
  "An empty section header '[]' produces a section with an empty-string name."
  (let ((result (parse-ini "[]")))
    (is (= 1 (length result)))
    (is (string= "" (caar result)))))

(test parse-section-with-trailing-content-not-recognised
  "A section header followed by extra content on the same line is not
recognised as a section header, and the line is silently dropped."
  (let ((result (parse-ini "[section] ; inline comment")))
    (is (null result))))

(test parse-colon-separator-trims-whitespace
  "The colon separator also trims surrounding whitespace from key and value."
  ;; Trailing spaces after "value" are intentional – they should be trimmed.
  (let ((result (parse-ini "[section]
  key  :  value  ")))
    (let ((section (first result)))
      (is (string= "value"
                   (cdr (assoc "key" (cdr section) :test #'string=)))))))

(test parse-value-with-equals
  "A value that itself contains '=' is kept intact."
  (let ((result (parse-ini "[section]
key = a=b")))
    (is (string= "a=b"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test parse-colon-separator-value-with-colon
  "When using the colon separator, subsequent colons inside the value are kept."
  (let ((result (parse-ini "[section]
key: http://example.com")))
    (is (string= "http://example.com"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test parse-line-without-separator
  "A line with no '=' or ':' separator is silently ignored."
  (let ((result (parse-ini "[section]
no-separator-here")))
    (let ((section (first result)))
      (is (null (cdr section))))))

(test parse-duplicate-keys
  "When a key appears more than once in a section, all entries are kept and
ASSOC returns the first one."
  (let* ((result (parse-ini "[section]
key = first
key = second"))
         (section (first result)))
    (is (= 2 (length (cdr section))))
    (is (string= "first"
                 (cdr (assoc "key" (cdr section) :test #'string=))))))

(test parse-only-keys-no-section
  "When the input contains only key-value pairs and no section header, the
pairs are collected under a NIL section key."
  (let ((result (parse-ini "key = value
other = 42")))
    (is (= 1 (length result)))
    (is (null (caar result)))
    (is (string= "value"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))
    (is (string= "42"
                 (cdr (assoc "other" (cdr (first result)) :test #'string=))))))

(test parse-pairs-before-section
  "Key-value lines before any section header are collected under a NIL section
key; subsequently named sections follow as normal."
  (let ((result (parse-ini "orphan = value
[section]
key = val")))
    (is (= 2 (length result)))
    (let ((global (first result))
          (named  (second result)))
      (is (null (car global)))
      (is (string= "value"
                   (cdr (assoc "orphan" (cdr global) :test #'string=))))
      (is (string= "section" (car named)))
      (is (string= "val"
                   (cdr (assoc "key" (cdr named) :test #'string=)))))))

(test parse-indented-comment
  "A comment line preceded by whitespace is still recognised as a comment."
  (let ((result (parse-ini "[section]
  ; indented comment
key = value")))
    (let ((section (first result)))
      (is (= 1 (length (cdr section)))))))

(test parse-inline-comment-not-stripped
  "Trailing inline comments are not stripped; they become part of the value."
  (let ((result (parse-ini "[section]
key = value ; inline comment")))
    (is (string= "value ; inline comment"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test parse-duplicate-sections
  "When the same section name appears twice, both are kept as separate entries."
  (let ((result (parse-ini "[section]
key = first
[section]
key = second")))
    (is (= 2 (length result)))
    (is (string= "section" (car (first result))))
    (is (string= "section" (car (second result))))))

(test read-ini-from-file
  "READ-INI reads and parses an INI file from disk."
  (uiop:with-temporary-file (:pathname path :type "ini" :keep nil)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string "[section]
key = value" stream))
    (let ((result (read-ini path)))
      (is (= 1 (length result)))
      (is (string= "section" (caar result)))
      (is (string= "value"
                   (cdr (assoc "key" (cdr (first result)) :test #'string=)))))))

;;; Writer tests

(test write-empty-data
  (is (string= "" (write-ini-to-string '()))))

(test write-single-section
  (let ((output (write-ini-to-string '(("section" ("key" . "value"))))))
    (is (search "[section]" output))
    (is (search "key = value" output))))

(test write-multiple-sections
  (let ((output (write-ini-to-string '(("alpha" ("a" . "1"))
                                       ("beta" ("b" . "2"))))))
    (is (search "[alpha]" output))
    (is (search "[beta]" output))
    (is (< (search "[alpha]" output) (search "[beta]" output)))))

;;; Round-trip tests

(test round-trip
  (let* ((original '(("section" ("key" . "value") ("other" . "42"))))
         (serialized (write-ini-to-string original))
         (parsed (parse-ini serialized)))
    (is (string= "section" (car (first parsed))))
    (is (string= "value"
                 (cdr (assoc "key" (cdr (first parsed)) :test #'string=))))
    (is (string= "42"
                 (cdr (assoc "other" (cdr (first parsed)) :test #'string=))))))

;;; Schema tests

(test schema-string-type
  "The :string type leaves a value unchanged."
  (let* ((schema '(("section" ("key" . :string))))
         (result (parse-ini-with-schema "[section]
key = hello" schema)))
    (is (string= "hello"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test schema-integer-type
  "The :integer type coerces the value to an integer."
  (let* ((schema '(("section" ("count" . :integer))))
         (result (parse-ini-with-schema "[section]
count = 42" schema)))
    (is (= 42 (cdr (assoc "count" (cdr (first result)) :test #'string=))))))

(test schema-float-type
  "The :float type coerces the value to a float."
  (let* ((schema '(("section" ("ratio" . :float))))
         (result (parse-ini-with-schema "[section]
ratio = 3.14" schema)))
    (is (typep (cdr (assoc "ratio" (cdr (first result)) :test #'string=)) 'float))
    (is (< (abs (- 3.14 (cdr (assoc "ratio" (cdr (first result)) :test #'string=)))) 1e-5))))

(test schema-boolean-true-values
  "The :boolean type recognises all truthy string forms."
  (dolist (s '("true" "yes" "on" "1" "True" "YES" "ON"))
    (let* ((schema '(("s" ("f" . :boolean))))
           (result (parse-ini-with-schema (format nil "[s]~%f = ~a" s) schema)))
      (is (eq t (cdr (assoc "f" (cdr (first result)) :test #'string=)))
          (format nil "~s should be truthy" s)))))

(test schema-boolean-false-values
  "The :boolean type recognises all falsy string forms."
  (dolist (s '("false" "no" "off" "0" "False" "NO" "OFF"))
    (let* ((schema '(("s" ("f" . :boolean))))
           (result (parse-ini-with-schema (format nil "[s]~%f = ~a" s) schema)))
      (is (eq nil (cdr (assoc "f" (cdr (first result)) :test #'string=)))
          (format nil "~s should be falsy" s)))))

(test schema-full-plist-type
  "A full plist key spec honours :type."
  (let* ((schema '(("section" ("port" :type :integer))))
         (result (parse-ini-with-schema "[section]
port = 8080" schema)))
    (is (= 8080 (cdr (assoc "port" (cdr (first result)) :test #'string=))))))

(test schema-default-value-used-when-key-absent
  "When a key is absent its :default value is inserted."
  (let* ((schema '(("section" ("port" :type :integer :default 8080))))
         (result (parse-ini-with-schema "[section]" schema)))
    (is (= 8080 (cdr (assoc "port" (cdr (first result)) :test #'string=))))))

(test schema-default-nil-used-when-key-absent
  "A :default of NIL is honoured even though NIL is the zero value."
  (let* ((schema '(("section" ("flag" :type :boolean :default nil))))
         (result (parse-ini-with-schema "[section]" schema))
         (pair (assoc "flag" (cdr (first result)) :test #'string=)))
    (is (not (null pair)))         ; key is present in output
    (is (null (cdr pair)))))

(test schema-required-key-missing-signals-error
  "A missing :required key signals INI-SCHEMA-ERROR."
  (let ((schema '(("section" ("must-exist" :type :string :required t)))))
    (signals ini-schema-error
      (parse-ini-with-schema "[section]" schema))))

(test schema-unknown-key-passed-through
  "Keys not mentioned in the schema are passed through as strings."
  (let* ((schema '(("section" ("typed" . :integer))))
         (result (parse-ini-with-schema "[section]
typed = 1
extra = hello" schema)))
    (is (= 1 (cdr (assoc "typed" (cdr (first result)) :test #'string=))))
    (is (string= "hello" (cdr (assoc "extra" (cdr (first result)) :test #'string=))))))

(test schema-section-not-in-schema-passed-through
  "Sections absent from the schema are returned unmodified."
  (let* ((schema '(("other" ("x" . :integer))))
         (result (parse-ini-with-schema "[section]
key = value" schema)))
    (is (string= "value"
                 (cdr (assoc "key" (cdr (first result)) :test #'string=))))))

(test schema-invalid-integer-signals-error
  "A non-numeric string coerced to :integer signals INI-SCHEMA-ERROR."
  (let ((schema '(("section" ("n" . :integer)))))
    (signals ini-schema-error
      (parse-ini-with-schema "[section]
n = not-a-number" schema))))

(test schema-invalid-float-signals-error
  "A non-numeric string coerced to :float signals INI-SCHEMA-ERROR."
  (let ((schema '(("section" ("f" . :float)))))
    (signals ini-schema-error
      (parse-ini-with-schema "[section]
f = not-a-float" schema))))

(test schema-invalid-boolean-signals-error
  "An unrecognised string coerced to :boolean signals INI-SCHEMA-ERROR."
  (let ((schema '(("section" ("b" . :boolean)))))
    (signals ini-schema-error
      (parse-ini-with-schema "[section]
b = maybe" schema))))

(test schema-coerce-ini-value-standalone
  "COERCE-INI-VALUE works as a standalone function."
  (is (string= "hello" (coerce-ini-value "hello" :string)))
  (is (= 7 (coerce-ini-value "7" :integer)))
  (is (typep (coerce-ini-value "2.5" :float) 'float))
  (is (eq t (coerce-ini-value "yes" :boolean)))
  (is (eq nil (coerce-ini-value "off" :boolean))))

(test schema-apply-schema-on-parsed-data
  "APPLY-SCHEMA operates on already-parsed INI data."
  (let* ((ini (parse-ini "[section]
n = 10"))
         (schema '(("section" ("n" . :integer))))
         (result (apply-schema ini schema)))
    (is (= 10 (cdr (assoc "n" (cdr (first result)) :test #'string=))))))

(test read-ini-with-schema-from-file
  "READ-INI-WITH-SCHEMA reads a file and applies the schema."
  (uiop:with-temporary-file (:pathname path :type "ini" :keep nil)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string "[db]
port = 5432
debug = false" stream))
    (let* ((schema '(("db" ("port" . :integer) ("debug" . :boolean))))
           (result (read-ini-with-schema path schema))
           (section (cdr (first result))))
      (is (= 5432 (cdr (assoc "port" section :test #'string=))))
      (is (eq nil (cdr (assoc "debug" section :test #'string=)))))))
