;;;; ======================================================================
;;;; File:       descriptives.lisp
;;;; Author:     Peter Harrison <p.m.c.harrison@qmul.ac.uk>
;;;; Created:    <2017-07-23 12:30:38 peter>                          
;;;; Time-stamp: <2017-12-04 10:59:18 peter>                           
;;;; ======================================================================
;;;;
;;;; DESCRIPTION 
;;;;
;;;;   Utility functions for computing descriptive statistics for a
;;;;   given musical dataset.
;;;;
;;;; ======================================================================

(cl:in-package #:descriptives)

;;;; Counting utilities

(defclass count-table ()
  ((data :accessor %data :initform (make-hash-table :test 'equal)
	 :documentation "Stores counts of objects with equality test #'equal.")))

(defmethod print-object ((object count-table) stream)
  (let* ((output (loop
		    for object being each hash-key of (%data object)
		    using (hash-value count)
		    collect (cons (princ-to-string object) count)))
	 (output (sort output #'string< :key #'car))
	 (num-objects (length output)))
    (format stream "<COUNT-TABLE (UNIQUE OBJECT COUNT = ~A)>" num-objects)
    (dolist (x output)
      (format stream "~%~A - ~A" (car x) (cdr x)))))

(defgeneric add-count (object count count-table)
  (:documentation "Increments the counter for <object> in <count-table> by <count>,
adding a new entry for <object> if it does not exist in <count-table>.
<count-table> is destructively updated and returned."))

(defmethod add-count (object (count number) (count-table count-table))
  (let ((prev-count (gethash object (%data count-table))))
    (setf (gethash object (%data count-table))
	  (if (null prev-count)
	      count
	      (+ prev-count count)))
    count-table))

(defgeneric get-count (object count-table)
  (:documentation "Gets the count for <object> in <count-table>."))
(defmethod get-count (object (count-table count-table))
  (let ((entry (gethash object (%data count-table))))
    (if (null entry) 0 entry)))

(defgeneric combine (x y)
  (:documentation "Combines two objects <x> and <y>, possibly destructively."))

(defmethod combine ((x count-table) (y count-table))
  (loop for object being each hash-key of (%data y)
       using (hash-value added-count)
       do (add-count object added-count x)
       finally (return x)))

;;;; Counting n grams

(defgeneric count-n-grams (data n)
  (:documentation "Counts <n>-grams in <data>.
Counting is done using the #'equal predicate (or whatever is implemented 
in the count-table methods). Final n-gram counts are returned as a count-table
object."))

(defmethod count-n-grams ((data list) (n integer))
  (assert (> n 0))
  (labels ((recursive-count (remainder n running-count)
	     (if (< (length remainder) n)
		 running-count
		 (recursive-count (cdr remainder) n
				  (add-count (subseq remainder 0 n)
					     1 running-count)))))
    (recursive-count data n (make-instance 'count-table))))

;;;; Counting n-grams of viewpoint elements

(defgeneric count-viewpoint-n-grams
    (data n viewpoint)
  (:documentation "Counts <n>-grams of viewpoint-elements in <data>.
Counting is done using the #'equal predicate (or whatever is implemented 
in the count-table methods). Final n-gram counts are returned as a count-table
object."))

(defmethod count-viewpoint-n-grams
    (data n (viewpoint symbol))
  (count-viewpoint-n-grams data n (viewpoints:get-viewpoint viewpoint)))

(defmethod count-viewpoint-n-grams
    (data n (viewpoint list))
  (count-viewpoint-n-grams data n (viewpoints:get-viewpoint viewpoint)))

(defmethod count-viewpoint-n-grams
    ((data md:music-sequence) n (viewpoint viewpoints:viewpoint))
  (count-n-grams (viewpoints:viewpoint-sequence viewpoint data) n))

(defmethod count-viewpoint-n-grams
    ((data list) n (viewpoint viewpoints:viewpoint))
  (reduce #'combine
	  (mapcar #'(lambda (composition)
		      (count-n-grams (viewpoints:viewpoint-sequence viewpoint
								    composition)
				     n))
		  data)))

;;;; Converting n-grams to transition probabilities

(defclass transition-probabilities ()
  ((data :accessor data :initarg :data
	:documentation "Object storing transition probabilities.
Transition probabilities are stored in the <data> slot. This slot 
should be occupied by a list each element of which corresponds
to a unique transition. These elements should themselves be lists,
the first element of which gives the context, the second giving 
the continuation, the third giving the context count, the fourth giving 
the continuation count, and the fifth giving the resulting MLE probability.")))

(defgeneric as-data-frame (object))
(defmethod as-data-frame ((object transition-probabilities))
  (let ((df (make-instance 'utils::dataframe)))
    (loop for row in (data object)
       do (let ((ht (make-hash-table)))
	    (setf (gethash :context ht) (first row))
	    (setf (gethash :continuation ht) (second row))
	    (setf (gethash :context-count ht) (third row))
	    (setf (gethash :continuation-count ht) (fourth row))
	    (setf (gethash :probability ht) (fifth row))
	    (utils:add-row ht df))
       finally (return df))))


(defgeneric as-assoc-list (object))
(defmethod as-assoc-list ((object transition-probabilities))
    (loop for row in (data object)
       collect (list (cons :context (first row))
		     (cons :continuation (second row))
		     (cons :context-count (third row))
		     (cons :continuation-count (fourth row))
		     (cons :probability (fifth row)))))

(defgeneric as-hash-table (object))
(defmethod as-hash-table ((object count-table))
  (%data object))

(defgeneric write-csv (object path))
(defmethod write-csv ((object transition-probabilities) path)
  (let* ((data (sort (copy-list (data object))
		     #'string<
		     :key #'(lambda (x) (princ-to-string (second x)))))
	 (data (sort data
		     #'string<
		     :key #'(lambda (x) (princ-to-string (first x)))))
	 (contexts (loop for x in data collect (first x)))
	 (continuations (loop for x in data collect (second x)))
	 (context-counts (loop for x in data collect (third x)))
	 (continuation-counts (loop for x in data collect (fourth x)))
	 (probabilities (loop for x in data collect (fifth x)))
	 (data (loop
		  for context in contexts
		  for continuation in continuations
		  for context-count in context-counts
		  for continuation-count in continuation-counts
		  for probability in probabilities
		  collect (list context continuation
				context-count continuation-count
				probability)))
	 (output (cons (list "context" "continuation"
			     "context_count" "continuation_count"
			     "probability")
		       data)))
    (with-open-file (stream path :direction :output :if-exists :supersede)
      (cl-csv:write-csv output :stream stream))))

(defmethod print-object ((object transition-probabilities) stream)
  (let* ((data (data object))
	 (num-transitions (length data)))
    (format stream "<TRANSITION PROBABILITIES (COUNT = ~A)>" num-transitions)
    (when (> num-transitions 0)
      (let* ((contexts (loop for x in (data object) collect (first x)))
	     (continuations (loop for x in (data object) collect (second x)))
	     (context-counts (loop for x in (data object) collect (third x)))
	     (continuation-counts (loop for x in (data object) collect (fourth x)))
	     (probabilities (loop for x in (data object) collect (fifth x))))
	(flet ((max-string-width (string-list)
		 (apply #'max (mapcar #'(lambda (x) (length (princ-to-string x)))
				      string-list))))
	  (let* ((context-col-width (max 10 (1+ (max-string-width contexts))))
		 (continuation-col-width (max 15 (1+ (max-string-width continuations))))
		 (context-count-col-width (max 15 (1+ (max-string-width context-counts))))
		 (continuation-count-col-width (max 18 (1+ (max-string-width
							    continuation-counts))))
		 (probability-col-width 9)
		 (total-width (+ context-col-width continuation-col-width
				 probability-col-width)))
	    (flet ((print-separator ()
		     (format stream "~%~A"
			     (make-sequence 'string total-width :initial-element #\-)))
		   (print-header ()
		     (format stream "~%~vA~vA~vA~vA~vA"
			     context-col-width "Context"
			     continuation-col-width "Continuation"
			     context-count-col-width "Context (N)"
			     continuation-count-col-width "Continuation (N)"
			     probability-col-width "Probability"))
		   (print-data ()
		     (loop
			for context in contexts
			for continuation in continuations
			for context-count in context-counts
			for continuation-count in continuation-counts
			for probability in probabilities
			do (format stream
				   "~%~vA~vA~vA~vA~v$"
				   context-col-width context
				   continuation-col-width continuation
				   context-count-col-width context-count
				   continuation-count-col-width continuation-count
				   probability-col-width probability))))
	      (print-separator)
	      (print-header)
	      (print-data))))))))
	       
(defgeneric n-grams->transition-probabilities (n-grams)
  (:documentation "Converts n-grams to transition probabilities using
maximum-likelihood estimation (i.e. no escape probabilities)."))

(defmethod n-grams->transition-probabilities ((n-grams count-table))
  (let* ((context-counts
	  (loop with context-counts = (make-instance 'count-table)
	     for n-gram being each hash-key of (%data n-grams)
	     using (hash-value count)
	     do (add-count (butlast n-gram) count context-counts)
	     finally (return context-counts))))
    (make-instance
     'transition-probabilities
     :data (loop
	      for n-gram being each hash-key of (%data n-grams)
	      using (hash-value continuation-count)
	      collect (let* ((context (butlast n-gram))
			     (continuation (car (last n-gram)))
			     (context-count (get-count context context-counts))
			     (probability (coerce (/ continuation-count context-count)
						  'double-float)))
			(list context continuation
			      context-count continuation-count
			      probability))))))

(defun get-viewpoint-transition-probabilities (data n viewpoint)
  (n-grams->transition-probabilities (count-viewpoint-n-grams data (1+ n) viewpoint)))

(defun get-h-cpitch-0-order-tps-with-roughness (data &optional output-path)
  "For each unique <h-cpitch> in <data>, get 0th-order
transition probabilities and roughness estimates."
  (let* ((tps (as-assoc-list (get-viewpoint-transition-probabilities
			      data 0 'h-cpitch)))
	 (res
	  (loop for elt in tps
	     collect (acons :roughness
			    (hutch-knopoff (cdr (assoc :continuation elt)))
			    elt))))
    (when output-path
      (utils:write-csv (utils:as-dataframe res)
		       (pathname output-path)))
    res))

(defun get-h-cpitch-1-order-tps-with-dissonance (data &optional output-path)
  "For each unique <h-cpitch> in <data>, get 1st-order
transition probabilities and sequential dissonance estimates.
Sequential dissonance is estimated as Milne's spectral distance."
  (let* ((tps (as-assoc-list (get-viewpoint-transition-probabilities
			      data 1 'h-cpitch)))
	 (res 
	  (loop for elt in tps
	     collect (acons :sequential-dissonance
			    (milne-sd (car (cdr (assoc :context elt)))
				      (cdr (assoc :continuation elt)))
			    elt))))
    (when output-path
      (utils:write-csv (utils:as-dataframe res)
		       (pathname output-path)))
    res))

;;;; Calculating dissonance for chords

(defun milne-sd (chord-1 chord-2)
  "Computes Milne's spectral distance between <chord-1> and <chord-2>.
<chord-1> and <chord-2> should each be lists of MIDI note numbers."
  (assert (listp chord-1))
  (assert (listp chord-2))
  (assert (every #'numberp chord-1))
  (assert (every #'numberp chord-2))
  (let ((seq (viewpoints:harm-seq (list chord-1 chord-2)))
	(viewpoint (viewpoints:get-viewpoint 'h-cpc-milne-sd-cont=min)))
    (car (viewpoints:viewpoint-sequence viewpoint seq))))

(defun hutch-knopoff (chord)
  "Computes roughness of a single chord according
to the model of Hutchinson & Knopoff (1978, 1979)."
  (assert (listp chord))
  (assert (every #'numberp chord))
  (let ((seq (viewpoints:harm-seq (list chord)))
	(viewpoint (viewpoints:get-viewpoint 'h-hutch-rough)))
    (car (viewpoints:viewpoint-sequence viewpoint seq))))
    