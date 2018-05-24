(cl:in-package #:viewpoints)

;;; Viewpoint Definitions

(defmacro define-viewpoint ((name superclass typeset) 
                            ((events class) element)
                            &key function function* alphabet)
  (let ((f* function*))
    `(progn 
      (defclass ,name (,superclass)
        ((alphabet :allocation :class 
                   :initform ,(when (eql superclass 'test) ''(0 1)))
         (typeset :initform ',typeset :allocation :class)))
      (defgeneric ,name (,events))
      (defmethod ,name ((,events ,class))
        (declare (ignorable ,events))
        (let ((events (coerce ,events 'list)))
          ,function))
      (defmethod ,name ((,events list))
        (declare (ignorable ,events))
        ,function)
      ,(when alphabet
	     `(defmethod viewpoint-alphabet ((v , name)) ,alphabet))
      ,(when f*
             (let ((fname `,(intern (concatenate 'string (symbol-name name) "*"))))
               `(progn
                  (defgeneric ,fname (,element ,events))
                  (defmethod ,fname (,element ,events)
                    (declare (ignorable events element))
                    ,f*)))))))

(defmacro define-abstract-viewpoint ((name typeset event-attributes
					   additional-attributes training-viewpoint) 
                            ((events class) element)
				     &key function function* alphabet)
  (let ((abstract-args `(loop for p in
			    (list ,@event-attributes ,@additional-attributes)
			  collect (lv:get-latent-state-value p)))
	(training-args `(loop for p in (list ,@event-attributes) collect
			      (apply (intern (symbol-name p) (find-package :viewpoints))
				     (list events)))))
    (let ((function `(apply #',function ,abstract-args))
	  (function* (if (null function*) nil
			 `(apply #',function* ,abstract-args)))
	  (training-function `(apply #',function ,training-args))
	  (training-function* (if (null function*) nil
				  `(apply #',function* ,training-args)))
	  (alphabet-function (if (null alphabet) nil
				 `(apply #',alphabet ,abstract-args))))
      `(progn
	 (define-viewpoint (,name abstract ,typeset)
	     ((,events ,class) ,element)
	   :function ,function :function* ,function* :alphabet ,alphabet-function)
	 (define-viewpoint (,training-viewpoint derived ,typeset)
	     ((,events ,class) ,element)
	   :function ,training-function :function* ,training-function*)
	 (defmethod training-viewpoint ((v ,name)) (get-viewpoint ',training-viewpoint))
	 (defmethod latent-attributes ((v ,name)) '(,@event-attributes
						    ,@additional-attributes))))))

(defmacro define-basic-viewpoint (name ((events class)) function)
  `(progn 
     (register-basic-type ',name '(elt ,events 0))
     (define-viewpoint (,name basic (,name))
         ((,events ,class) element)
       :function ,function
       :function* (list element))))

(defmacro define-threaded-viewpoint (name base-viewpoint test-viewpoint class)
  (let* ((base-viewpoint `(get-viewpoint ',base-viewpoint))
         (test-viewpoint `(get-viewpoint ',test-viewpoint))
         (typeset `(append (viewpoint-typeset ,base-viewpoint) (viewpoint-typeset ,test-viewpoint))))
    `(define-viewpoint (,name threaded ,(eval typeset))
         ((events ,class) element)
       :function (let ((e (last-element events)))
                   (if (null e)
                       +undefined+
                       (let ((f (viewpoint-element ,test-viewpoint events)))
                         (if (zerop f)
                             +undefined+
                             (viewpoint-element ,base-viewpoint (filter ,test-viewpoint events))))))
       :function* (let ((base-function (inverse-viewpoint-function ,base-viewpoint)))
                    (when base-function 
                      (let ((e (append (strip-until-true ,test-viewpoint (butlast events))
                                       (last events))))
                        (funcall base-function element e)))))))  

