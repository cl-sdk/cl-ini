(in-package :cl-ini)

;;; Conditions

(define-condition ini-schema-error (error)
  ((message :initarg :message :reader ini-schema-error-message))
  (:report (lambda (c s)
             (format s "INI schema error: ~a" (ini-schema-error-message c)))))

;;; Key-spec accessors
;;;
;;; A key spec is either a simple dotted pair:
;;;   ("key" . :type)
;;; or a list with a property list as its tail:
;;;   ("key" :type :integer :default 0 :required t)

(defun key-spec-name (spec)
  (car spec))

(defun key-spec-type (spec)
  (let ((rest (cdr spec)))
    (cond
      ((keywordp rest) rest)
      ((listp rest) (or (getf rest :type) :string))
      (t :string))))

(defun key-spec-default (spec)
  "Returns (values default foundp) for the spec's :default property."
  (let ((rest (cdr spec)))
    (if (and (listp rest) (not (null rest)))
        (let ((cell (member :default rest)))
          (if cell
              (values (cadr cell) t)
              (values nil nil)))
        (values nil nil))))

(defun key-spec-required-p (spec)
  (let ((rest (cdr spec)))
    (and (listp rest) (getf rest :required))))

;;; Type coercion

(defun coerce-ini-value (string type)
  "Coerce STRING to TYPE.

Supported types:
  :string  — return STRING unchanged (the default).
  :integer — parse as a decimal integer via PARSE-INTEGER.
  :float   — parse as a real number and convert to a single-float.
  :boolean — \"true\", \"yes\", \"on\", \"1\" => T;
             \"false\", \"no\", \"off\", \"0\" => NIL.

Signals INI-SCHEMA-ERROR when coercion fails."
  (ecase type
    (:string string)
    (:integer
     (handler-case (parse-integer string)
       (error ()
         (error 'ini-schema-error
                :message (format nil "cannot coerce ~s to integer" string)))))
    (:float
     (unless (and (plusp (length string))
                  (every (lambda (c)
                           (or (digit-char-p c)
                               (member c '(#\. #\e #\E #\+ #\-))))
                         string))
       (error 'ini-schema-error
              :message (format nil "cannot coerce ~s to float" string)))
     (let ((val (handler-case
                    (let ((*read-eval* nil))
                      (read-from-string string))
                  (error ()
                    (error 'ini-schema-error
                           :message (format nil "cannot coerce ~s to float" string))))))
       (if (realp val)
           (float val)
           (error 'ini-schema-error
                  :message (format nil "cannot coerce ~s to float" string)))))
    (:boolean
     (cond
       ((member string '("true" "yes" "on" "1") :test #'string-equal) t)
       ((member string '("false" "no" "off" "0") :test #'string-equal) nil)
       (t (error 'ini-schema-error
                 :message (format nil "cannot coerce ~s to boolean" string)))))))

;;; Schema application

(defun apply-section-schema (pairs key-specs)
  "Apply KEY-SPECS to a section's PAIRS alist.

For each key spec:
  - If the key is present in PAIRS, coerce its value to the declared type.
  - If the key is absent and has a :default, use the default value.
  - If the key is absent and is :required, signal INI-SCHEMA-ERROR.
  - If the key is absent and optional with no default, omit it from the result.

Keys present in PAIRS but not mentioned in KEY-SPECS are passed through
unchanged (as strings)."
  (let ((result '())
        (handled (make-hash-table :test #'equal)))
    (dolist (spec key-specs)
      (let* ((name (key-spec-name spec))
             (type (key-spec-type spec))
             (pair (assoc name pairs :test #'string=)))
        (cond
          (pair
           (push (cons name (coerce-ini-value (cdr pair) type)) result)
           (setf (gethash name handled) t))
          (t
           (multiple-value-bind (default default-p) (key-spec-default spec)
             (cond
               (default-p
                (push (cons name default) result)
                (setf (gethash name handled) t))
               ((key-spec-required-p spec)
                (error 'ini-schema-error
                       :message (format nil "required key ~s is missing" name)))))))))
    (dolist (pair pairs)
      (unless (gethash (car pair) handled)
        (push pair result)))
    (nreverse result)))

(defun apply-schema (ini schema)
  "Apply SCHEMA to already-parsed INI data and return a new alist.

INI is the alist returned by PARSE-INI.  SCHEMA has the same outer shape —
an alist of sections — but each section's \"values\" are key specifications
rather than key/value pairs:

  ((\"section-name\"
    (\"key\"   . :string)
    (\"count\" . :integer)
    (\"ratio\" :type :float :default 1.0)
    (\"flag\"  :type :boolean :required t))
   ...)

Sections absent from SCHEMA are passed through unchanged.
See COERCE-INI-VALUE for the supported types."
  (mapcar (lambda (section)
            (let* ((section-name (car section))
                   (pairs (cdr section))
                   (section-schema (assoc section-name schema :test #'equal))
                   (key-specs (when section-schema (cdr section-schema))))
              (if key-specs
                  (cons section-name (apply-section-schema pairs key-specs))
                  section)))
          ini))

;;; Public API

(defun parse-ini-with-schema (string schema)
  "Parse STRING as INI text and apply SCHEMA for type coercion and validation.

Equivalent to calling PARSE-INI with SCHEMA.

SCHEMA is an alist of sections.  Each section is a list whose first element
is the section name (a string) and whose remaining elements are key
specifications.  A key specification is either:

  (\"key\" . :type)
or
  (\"key\" :type :integer :default 0 :required t)

Supported types: :string (default), :integer, :float, :boolean.

Returns the same alist structure as PARSE-INI, but with values coerced to
their declared types.

Signals INI-SCHEMA-ERROR on type-coercion failure or a missing required key."
  (parse-ini string schema))

(defun read-ini-with-schema (pathname schema)
  "Read and parse an INI file at PATHNAME, applying SCHEMA.

Convenience wrapper around PARSE-INI-WITH-SCHEMA that reads the file first.
See PARSE-INI-WITH-SCHEMA for the SCHEMA format and error behaviour."
  (parse-ini-with-schema (uiop:read-file-string pathname) schema))
