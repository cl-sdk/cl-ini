(in-package :io.github.cl-sdk.ini)

(defun trim (string)
  (string-trim '(#\Space #\Tab) string))

(defun comment-line-p (line)
  (let ((trimmed (trim line)))
    (and (plusp (length trimmed))
         (or (char= (char trimmed 0) #\;)
             (char= (char trimmed 0) #\#)))))

(defun section-line-p (line)
  (let ((trimmed (trim line)))
    (and (plusp (length trimmed))
         (char= (char trimmed 0) #\[)
         (char= (char trimmed (1- (length trimmed))) #\]))))

(defun parse-section-name (line)
  (let ((trimmed (trim line)))
    (trim (subseq trimmed 1 (1- (length trimmed))))))

(defun parse-key-value (line)
  "Parse a key=value or key: value line. Returns (key . value) or NIL."
  (let ((sep (or (position #\= line) (position #\: line))))
    (when sep
      (cons (trim (subseq line 0 sep))
            (trim (subseq line (1+ sep)))))))

(defclass default-ini-parser (ini-parser)
  ((sections        :initform '()  :accessor default-ini-parser-sections)
   (current-section :initform nil  :accessor default-ini-parser-current-section)
   (current-pairs   :initform '()  :accessor default-ini-parser-current-pairs))
  (:documentation "Default parser implementation used by PARSE-INI and READ-INI."))

(defun %flush-default-ini-parser-section (parser)
  (let ((current-section (default-ini-parser-current-section parser))
        (current-pairs (default-ini-parser-current-pairs parser)))
    (when (or current-section current-pairs)
      (push (cons current-section (nreverse current-pairs))
            (default-ini-parser-sections parser))
      (setf (default-ini-parser-current-pairs parser) '()))))

(defmethod ini-parser-begin-document ((parser default-ini-parser))
  (setf (default-ini-parser-sections parser) '()
        (default-ini-parser-current-section parser) nil
        (default-ini-parser-current-pairs parser) '()))

(defmethod ini-parser-section ((parser default-ini-parser) section-name)
  (%flush-default-ini-parser-section parser)
  (setf (default-ini-parser-current-section parser) section-name))

(defmethod ini-parser-pair ((parser default-ini-parser) pair)
  (push pair (default-ini-parser-current-pairs parser)))

(defmethod ini-parser-end-document ((parser default-ini-parser))
  (%flush-default-ini-parser-section parser))

(defmethod ini-parser-result ((parser default-ini-parser))
  (nreverse (default-ini-parser-sections parser)))

(defun parse-ini (input &key parser)
  "Parse INI INPUT and return PARSER's result.

INPUT may be a string or a character stream.

The default parser returns an alist of sections where each section has the
form:
  (\"section-name\" (\"key1\" . \"value1\") (\"key2\" . \"value2\") ...)."
  (let ((parser (or parser (make-instance 'default-ini-parser))))
    (flet ((do-parse (stream)
             (ini-parser-begin-document parser)
             (loop for line = (read-line stream nil nil)
                   while line do
                     (cond
                       ((or (zerop (length (trim line)))
                            (comment-line-p line)))
                       ((section-line-p line)
                        (ini-parser-section parser (parse-section-name line)))
                       (t
                        (let ((pair (parse-key-value line)))
                          (when pair
                            (ini-parser-pair parser pair))))))
             (ini-parser-end-document parser)
             parser))
      (etypecase input
        (stream
         (ini-parser-result (do-parse input)))
        (string
         (with-input-from-string (stream input)
           (ini-parser-result (do-parse stream))))))))

(defun read-ini (pathname &key parser)
  "Read and parse an INI file at PATHNAME and return PARSER's result."
  (parse-ini (uiop:read-file-string pathname) :parser parser))
