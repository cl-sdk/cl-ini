(defsystem "cl-ini.test"
  :description "Tests for cl-ini."
  :author "cl-sdk"
  :license "Unlicense"
  :version "0.1.0"
  :depends-on ("cl-ini" "fiveam")
  :components ((:module "t"
                :components ((:file "package")
                             (:file "test" :depends-on ("package"))))))
