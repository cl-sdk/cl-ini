(in-package :io.github.diasbruno.ini.test)

(def-suite :io.github.diasbruno.ini
  :description "Tests for the cl-ini INI reader and writer.")

(in-suite :io.github.diasbruno.ini)

(defclass recording-ini-parser (ini-parser)
  ((events :initform '() :accessor recording-ini-parser-events)))

(defmethod ini-parser-begin-document ((parser recording-ini-parser))
  (push '(:begin-document nil) (recording-ini-parser-events parser)))

(defmethod ini-parser-end-document ((parser recording-ini-parser))
  (push '(:end-document nil) (recording-ini-parser-events parser)))

(defmethod ini-parser-section ((parser recording-ini-parser) section-name)
  (push (list :section section-name) (recording-ini-parser-events parser)))

(defmethod ini-parser-pair ((parser recording-ini-parser) pair)
  (push (list :pair pair) (recording-ini-parser-events parser)))

(defmethod ini-parser-result ((parser recording-ini-parser))
  (nreverse (recording-ini-parser-events parser)))

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

(test parse-ini-custom-parser-events
  "PARSE-INI emits parser callbacks in document order."
  (is (equal '((:begin-document nil)
               (:section "section")
               (:pair ("key" . "value"))
               (:end-document nil))
             (parse-ini "[section]
key = value"
                        :parser (make-instance 'recording-ini-parser)))))

(test parse-ini-custom-parser-with-global-pairs
  "PARSE-INI emits pair events before any section for global key/value lines."
  (is (equal '((:begin-document nil)
               (:pair ("global" . "42"))
               (:section "section")
               (:pair ("key" . "value"))
               (:end-document nil))
             (parse-ini "global = 42
[section]
key = value"
                        :parser (make-instance 'recording-ini-parser)))))

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
