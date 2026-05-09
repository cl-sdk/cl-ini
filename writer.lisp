(in-package :io.github.diasbruno.ini)

(defun write-ini-to-string (ini-data)
  "Serialize INI-DATA to a string.

INI-DATA should be a list of sections as returned by PARSE-INI:
  ((\"section-name\" (\"key\" . \"value\") ...) ...)

Returns a string in INI format."
  (with-output-to-string (stream)
    (loop for (section . rest) on ini-data
          for section-name = (car section)
          for pairs = (cdr section) do
            (format stream "[~a]~%" section-name)
            (loop for (key . value) in pairs do
              (format stream "~a = ~a~%" key value))
            (when rest
              (terpri stream)))))

(defun write-ini (ini-data pathname)
  "Write INI-DATA to a file at PATHNAME.

INI-DATA should be a list of sections as returned by PARSE-INI."
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-string (write-ini-to-string ini-data) stream)))
