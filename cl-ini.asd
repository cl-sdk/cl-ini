(defsystem "cl-ini"
  :description "A Common Lisp INI file reader and writer."
  :author "cl-sdk"
  :license "Unlicense"
  :version "0.1.0"
  :components ((:file "package")
               (:file "reader" :depends-on ("package"))
               (:file "writer" :depends-on ("package"))))
