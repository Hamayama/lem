(defpackage :lem-lsp-mode/json-lsp-utils
  (:use :cl
        :lem-lsp-mode/json
        :lem-lsp-mode/type)
  (:export :json-type-error
           :coerce-json))
(in-package :lem-lsp-mode/json-lsp-utils)

(cl-package-locks:lock-package :lem-lsp-mode/json-lsp-utils)

(define-condition json-type-error ()
  ((type :initarg :type)
   (value :initarg :value))
  (:report (lambda (c s)
             (with-slots (value type) c
               (format s "~S is not a ~S" value type)))))

(defun assert-type (value type)
  (unless (typep value type)
    (error 'json-type-error :value value :type type))
  (values))

(defun exist-hash-table-key-p (hash-table key)
  (let ((default '#:default))
    (not (eq default (gethash key hash-table default)))))

;; TODO: yasonに依存しているのを直す
(defun coerce-json (value type)
  (trivia:match type
    ((list 'ts-array item-type)
     (assert-type value 'list)
     (map 'vector
          (lambda (item)
            (coerce-json item item-type))
          value))
    ((cons 'ts-interface elements)
     (assert-type value 'hash-table)
     (let ((new-hash-table (make-hash-table :test 'equal)))
       (dolist (element elements)
         (destructuring-bind (name &key type optional-p) element
           (cond ((exist-hash-table-key-p value name)
                  (setf (gethash name new-hash-table)
                        (coerce-json (gethash name value) type)))
                 ((not optional-p)
                  ;; 必須要素が入っていない場合エラーを出すべきか?
                  ))))
       new-hash-table))
    ((list 'ts-equal-specializer value-spec)
     (unless (equal value value-spec)
       (error 'json-type-error :type type :value value))
     value)
    ((list 'ts-object key-type value-type)
     (assert-type value 'hash-table)
     (let ((new-hash-table (make-hash-table :test 'equal)))
       (maphash (lambda (key value)
                  (setf (gethash (coerce-json key key-type) new-hash-table)
                        (coerce-json value value-type)))
                value)
       new-hash-table))
    ((cons 'ts-tuple types)
     (assert-type value 'list)
     (unless (alexandria:length= value types)
       (error 'json-type-error :type type :value value))
     (loop :for type :in types
           :for item :in value
           :collect (coerce-json item type)))
    ((cons 'or types)
     (dolist (type1 types (error 'json-type-error :type type :value value))
       (handler-case (coerce-json value type1)
         (json-type-error ())
         (:no-error (result)
           (return result)))))
    (otherwise
     (let ((class (and (symbolp type)
                       (find-class type nil))))
       (if (and class (object-class-p class))
           (coerce-json-object-class value class)
           (multiple-value-bind (type expanded)
               (typexpand type)
             (if expanded
                 (coerce-json value type)
                 (progn
                   (assert-type value type)
                   value))))))))

(defun coerce-json-object-class (json json-class-name)
  (let ((object (make-instance json-class-name :dont-check-required-initarg t)))
    (loop :for slot :in (closer-mop:class-slots (class-of object))
          :for slot-name := (closer-mop:slot-definition-name slot)
          :do (setf (slot-value object slot-name)
                    (coerce-json (json-get json (cl-change-case:camel-case (string slot-name)))
                                 (closer-mop:slot-definition-type slot))))
    object))

(defun typexpand (type)
  #+sbcl
  (sb-ext:typexpand type)
  #+ccl
  (ccl::type-expand type))