(defpackage :io.github.diasbruno.ini
  (:use :cl)
  (:export
   #:parse-ini
   #:read-ini
   #:ini-parser
   #:ini-parser-begin-document
   #:ini-parser-end-document
   #:ini-parser-section
   #:ini-parser-pair
   #:ini-parser-result
   #:write-ini-to-string
   #:write-ini))
