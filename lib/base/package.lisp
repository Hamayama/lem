(defpackage :lem-base
  (:use :cl
        :lem-base/string-width-utils
        :lem-base/file-utils
        :lem-base/errors
        :lem-base/hooks
        :lem-base/line)
  #+sbcl
  (:lock t)
  (:export . #.(loop :for sym :being :the :external-symbols :of (find-package :lem-base/string-width-utils)
                     :collect (make-symbol (string sym))))
  (:export . #.(loop :for sym :being :the :external-symbols :of (find-package :lem-base/file-utils)
                     :collect (make-symbol (string sym))))
  (:export . #.(loop :for sym :being :the :external-symbols :of (find-package :lem-base/errors)
                     :collect (make-symbol (string sym))))
  (:export . #.(loop :for sym :being :the :external-symbols :of (find-package :lem-base/hooks)
                     :collect (make-symbol (string sym)))))
