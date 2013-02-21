;;;; -*- Mode: LISP; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; ======================================================================
;;;; File:       amuse-interface.lisp
;;;; Author:     Marcus Pearce <m.pearce@gold.ac.uk>
;;;; Created:    <2008-09-30 17:25:38 marcusp>
;;;; Time-stamp: <2013-02-21 16:47:47 jeremy>
;;;; ======================================================================

(cl:in-package #:music-data)

(defun get-event-sequence (dataset-id composition-id)
  (amuse:monody
   (amuse:get-composition 
    (amuse-mtp:make-mtp-composition-identifier dataset-id composition-id))))

(defun get-event-sequences (&rest dataset-ids)
  (let ((compositions '()))
    (dolist (dataset-id dataset-ids (nreverse compositions))
      (let ((d (amuse-mtp:get-dataset 
                (amuse-mtp:make-mtp-dataset-identifier dataset-id))))
        (sequence:dosequence (c d)
          (push (amuse:monody c) compositions))))))

(defun composition-viewpoint (dataset-id composition-id viewpoint)
  "Show viewpoint sequence for composition."
  (viewpoints:viewpoint-sequence 
   (viewpoints:get-viewpoint viewpoint)
   (get-event-sequence dataset-id composition-id)))

(defun dataset-viewpoint (dataset-id viewpoint)
  "Show viewpoint sequences for dataset."
  (viewpoints:viewpoint-sequences
   (viewpoints:get-viewpoint viewpoint)
   (get-event-sequences dataset-id)))

(defgeneric get-attribute (event attribute))
(defmethod get-attribute ((e amuse-mtp:mtp-event) attribute)
  "Returns the value for slot <attribute> in event object <e>."
  (let* ((attribute 
          (case attribute
            ((:onset viewpoints::onset) 'amuse::time)
            ((:dur viewpoints::dur) 'amuse::interval)
            (t 
             (find-symbol (string-upcase (symbol-name attribute)) 
                          (find-package :amuse-mtp))))))
    (slot-value e attribute)))

(defgeneric set-attribute (event attribute value))
(defmethod set-attribute ((e amuse-mtp:mtp-event) attribute value)
  (let* ((attribute 
          (case attribute
            ((:onset viewpoints::onset) 'amuse::time)
            ((:dur viewpoints::dur) 'amuse::interval)
            (t 
             (find-symbol (string-upcase (symbol-name attribute)) 
                          (find-package :amuse-mtp))))))
    (setf (slot-value e attribute) value)))

#.(clsql:locally-enable-sql-reader-syntax)
(defun get-alphabet (attribute &rest dataset-ids)
  (clsql:select attribute :from 'mtp-event
                :where [in [slot-value 'mtp-event 'dataset-id] dataset-ids]
                :order-by attribute
                :flatp t 
                :field-names nil 
                :distinct t))
#.(clsql:restore-sql-reader-syntax-state)

(defgeneric copy-event (event))
(defmethod copy-event ((l list))
  (make-instance 'amuse-mtp:mtp-event))

;; TODO: these should be replaced with a new amuse generic: 
;; (defgeneric get-identifier (object))
(defun dataset-id (event) (amuse-mtp::dataset-id event))
(defun composition-id (event) (amuse-mtp::composition-id event))
(defun event-id (event) (amuse-mtp::event-id event))

;;; These should be moved to amuse-mtp in due course
;(defmethod amuse::composition-id ((e amuse-mtp:mtp-event))
;  (amuse-mtp::composition-id e))

;(defmethod amuse::event-id ((e amuse-mtp:mtp-event))
;  (amuse-mtp::event-id e))

(defmethod copy-event ((e amuse-mtp:mtp-event))
  (make-instance 'amuse-mtp:mtp-event
                 :dataset-id (amuse-mtp::dataset-id e)
                 :composition-id (amuse-mtp::composition-id e)
                 :event-id (amuse-mtp::event-id e)
                 :time (amuse:timepoint e)
                 :deltast (amuse-mtp::%mtp-deltast e)
                 :bioi (amuse-mtp::%mtp-bioi e)
                 :cpitch (amuse-mtp::%mtp-cpitch e)
                 :mpitch (amuse-mtp::%mtp-mpitch e)
                 :interval (amuse:duration e)
                 :keysig (amuse-mtp::%mtp-keysig e)
                 :accidental (amuse-mtp::%mtp-accidental e)
                 :mode (amuse-mtp::%mtp-mode e)
                 :barlength (amuse-mtp::%mtp-barlength e)
                 :pulses (amuse-mtp::%mtp-pulses e)
                 :phrase (amuse-mtp::%mtp-phrase e)
                 :dyn (amuse-mtp::%mtp-dyn e)
                 :tempo (amuse-mtp::%mtp-tempo e)
                 :ornament (amuse-mtp::%mtp-ornament e)
                 :comma (amuse-mtp::%mtp-comma e)
                 :articulation (amuse-mtp::%mtp-articulation e)
                 :voice (amuse-mtp::%mtp-voice e)))

(defun count-compositions (dataset-id)
  (length (amuse-mtp:get-dataset 
           (amuse-mtp:make-mtp-dataset-identifier dataset-id))))
