(defsystem "cl-ini"
  :long-name "cl-ini — Common Lisp INI reader and writer"
  :description "A Common Lisp INI file reader and writer."
  :long-description
  #.(uiop:read-file-string
     (uiop:subpathname *load-pathname* "README.md"))
  :author "cl-sdk"
  :maintainer "cl-sdk"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-ini"
  :bug-tracker "https://github.com/cl-sdk/cl-ini/issues"
  :source-control (:git "https://github.com/cl-sdk/cl-ini.git")
  :encoding :utf-8
  :version "0.1.0"
  :in-order-to ((test-op (test-op "cl-ini.test")))
  :components ((:file "package")
               (:file "reader" :depends-on ("package"))
               (:file "writer" :depends-on ("package"))))
