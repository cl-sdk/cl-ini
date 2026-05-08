(in-package :cl-ini)

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

(defun parse-ini (string)
  "Parse an INI-formatted STRING and return an alist of sections.

Each section is a list of the form:
  (\"section-name\" (\"key1\" . \"value1\") (\"key2\" . \"value2\") ...)

Returns a list of such section lists."
  (let ((sections '())
        (current-section nil)
        (current-pairs '()))
    (with-input-from-string (stream string)
      (loop for line = (read-line stream nil nil)
            while line do
              (cond
                ((or (zerop (length (trim line)))
                     (comment-line-p line))
                 ;; skip blank lines and comments
                 )
                ((section-line-p line)
                 (when (or current-section current-pairs)
                   (push (cons current-section (nreverse current-pairs))
                         sections))
                 (setf current-section (parse-section-name line))
                 (setf current-pairs '()))
                (t
                 (let ((pair (parse-key-value line)))
                   (when pair
                     (push pair current-pairs)))))))
    (when (or current-section current-pairs)
      (push (cons current-section (nreverse current-pairs)) sections))
    (nreverse sections)))

(defun read-ini (pathname)
  "Read and parse an INI file at PATHNAME. Returns the same format as PARSE-INI."
  (parse-ini (uiop:read-file-string pathname)))
