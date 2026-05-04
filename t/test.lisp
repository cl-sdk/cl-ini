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
