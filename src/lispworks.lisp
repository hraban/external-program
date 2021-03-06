;;; Copyright 2006-2008 Greg Pfeil
;;; Distributed under the LLGPL (see LICENSE file)

(in-package :external-program)

;;; Documentation at http://www.lispworks.com/documentation/lwl42/LWRM-U/html/lwref-u-421.htm
;;; The docs say that :ENVIRONMENT should be an alist, but it should actually be
;;; a list of proper lists.

(defstruct external-process
  process-id
  inputp
  outputp
  stream
  error-stream)

(defun convert-rest (rest)
  (setf (getf rest :error-output) (getf rest :error))
  (remf rest :error)
  (remf rest :replace-environment-p)
  (setf (getf rest :environment)
        (mapcar (lambda (var) (list (car var) (cdr var)))
                (getf rest :environment)))
  rest)

(defmethod run
    (program args &rest rest &key replace-environment-p &allow-other-keys)
  (values :exited
          (apply #'sys:run-shell-command
                 (make-shell-string program args nil replace-environment-p)
                 :wait t
                 (convert-rest rest))))

(defmethod start
    (program args
     &rest rest &key input output replace-environment-p &allow-other-keys)
  (multiple-value-bind (stream error-stream process-id)
      (apply #'sys:run-shell-command
                 (make-shell-string program args nil replace-environment-p)
                 :wait t
                 (convert-rest rest))
    (make-external-process :process-id process-id
                           :inputp (eq input :stream)
                           :outputp (eq output :stream)
                           :stream stream
                           :error-stream error-stream)))

(defmethod process-input-stream (process)
  (if (external-process-inputp process)
      (external-process-stream process)))

(defmethod process-output-stream (process)
  (if (external-process-outputp process)
      (external-process-stream process)))

(defmethod process-error-stream (process)
  (external-process-error-stream process))

(defmethod process-status (process)
  (let ((status-code (sys:pid-exit-status (external-process-process-id
                                           process))))
    (values (if status-code :exited :running) status-code)))

(defmethod process-p (process)
  (typep process 'external-process))
