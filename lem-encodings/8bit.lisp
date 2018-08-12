(uiop/package:define-package :lem-encodings/8bit (:use :cl :lem-base :lem-encodings/table))
(in-package :lem-encodings/8bit)
;;;don't edit above

(defmacro def-8bit-encoding (name)
  `(let* ((path (asdf:system-relative-pathname :lem-encodings ,(format nil "~(~A~).table" name)))
          (data (lem-encodings/table:read-table path))
          (from (loop with result = (make-array 256)
                       for line in data                       
                       do (setf (svref result (first line)) (second line))
                       finally (return result)))
          (to (loop with result = (make-hash-table)
                    for line in data                       
                    do (setf (gethash (second line) result) (or (third line) (first line)))
                    finally (return result))))
     (setf data nil)
     (defclass ,name (encoding) ())
     (defmethod encoding-read ((encoding ,name) input output-char)
       (let (cr)
         (labels ((commit (c)
                    (setf cr (funcall output-char c cr encoding))))
           (loop
             :with buffer-size := 8192
             :with buffer := (make-array (list buffer-size) :element-type '(unsigned-byte 8))
             :for end := (read-sequence buffer input)
             :until (zerop end)
             :do (loop :for i :from 0 :below end
                       :do (commit (svref from (aref buffer i))))
                 (when (< end buffer-size)
                   (return))
             :finally (commit nil)))))
     (defmethod encoding-write ((encoding ,name) out)
       (lambda (c)
         (when c
           (write-byte (gethash c to) out))))
     (defmethod encoding-check ((encoding ,name))
       (lambda (string eof-p)
         (unless eof-p
           (loop :for c :across string
                 :unless (gethash c to)
                 :do (error "~A is not acceptable for ~S" c encoding)))))
     ',name))

(def-8bit-encoding koi8-u)

 