(defsystem #:io.github.diasbruno.ini.test
  :long-name "cl-ini test suite"
  :description "Tests for cl-ini."
  :long-description "FiveAM tests for the cl-ini project."
  :author "cl-sdk"
  :maintainer "cl-sdk"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-ini"
  :bug-tracker "https://github.com/cl-sdk/cl-ini/issues"
  :source-control (:git "https://github.com/cl-sdk/cl-ini.git")
  :encoding :utf-8
  :version "0.1.0"
  :depends-on (#:io.github.diasbruno.ini #:fiveam)
  :components ((:module "t"
                :components ((:file "package")
                             (:file "test" :depends-on ("package"))))))
