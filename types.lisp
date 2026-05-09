(in-package :io.github.cl-sdk.ini)

(defclass ini-parser ()
  ()
  (:documentation "Base class for event-driven INI parser implementations."))

(defgeneric ini-parser-begin-document (parser)
  (:documentation "Handle the start of an INI document."))

(defgeneric ini-parser-end-document (parser)
  (:documentation "Handle the end of an INI document."))

(defgeneric ini-parser-section (parser section-name)
  (:documentation "Handle a section declaration."))

(defgeneric ini-parser-pair (parser pair)
  (:documentation "Handle a parsed key/value pair."))

(defgeneric ini-parser-result (parser)
  (:documentation "Return the final result produced by PARSER."))
