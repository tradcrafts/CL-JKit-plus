;; -*- coding: utf-8 -*-
;; This file is part of JKIT.
;; Copyright (c) 2018-2021 tradcrafts tradcrafts
;;
;; -------------------------------------------------
;; --------------ORIGINAL Qi LICENSE ---------------
;; -------------------------------------------------
;;
; Beginning of Licence
;
; This software is licensed only for personal and educational use and
; not for the production of commercial software.  Modifications to this
; program are allowed but the resulting source must be annotated to
; indicate the nature of and the author of these changes.  
;
; Any modified source is bound by this licence and must remain available 
; as open source under the same conditions it was supplied and with this 
; licence at the top.

; This software is supplied AS IS without any warranty.  In no way shall 
; Mark Tarver or Lambda Associates be held liable for any damages resulting 
; from the use of this program.

; The terms of these conditions remain binding unless the individual 
; holds a valid license to use Qi commercially.  This license is found 
; in the final page of 'Functional Programming in Qi'.  In that event 
; the terms of that license apply to the license holder. 
;
; (c) copyright Mark Tarver, 2008
; End of Licence

(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (SETF *READTABLE* (COPY-READTABLE *READTABLE*))
  (SETF (READTABLE-CASE *READTABLE*) :PRESERVE)
  )

(IN-PACKAGE :JKIT.EMBED.CORE)

(DEFUN load (V1)
 (TIME (load-help *tc* (THE LIST (read-file V1))))
  (IF (EQ *tc* 'true) 
      (output "~%~%typechecked in ~A inferences" (THE NUMBER (inferences '_))))
  (TERPRI)
  'loaded)

;; (DEFUN load-help (V8 V9)
;;  (COND ((EQ 'false V8) (MAPC #'(LAMBDA (X) (output "~S~%" (eval X))) V9))
;;        (T
;;          (LET ((File-S (extract-synonyms V9)))
;;            (LET ((File-S-D (extract-datatypes File-S)))
;;              (LET ((Signatures (extract-signatures File-S-D)))
;;                (LET ((RecordFs (record-Fs Signatures)))
;;                  (LET ((AssertSignatures (assert-signatures Signatures)))
;;                    (LET ((Evaluate (evaluate-file-contents File-S-D)))
;;                      (SETQ *tempsigs* NIL))))))))))

;; 2015-8-29 JUN Hacked
(DEFUN load-help (V8 V9)
  ;;(FORMAT T "DEBUG load-help: ~W~%" V9)
 (COND ((EQ 'false V8) (MAPCAR #'(LAMBDA (X) (CONS NIL  (eval X))) V9))
       (T
         (LET ((File-S (extract-synonyms V9)))
           (LET ((File-S-D (extract-datatypes File-S)))
                       (FORMAT T "DEBUG load-help: ~W~%" File-S-D)
             (LET ((Signatures (extract-signatures File-S-D)))
               (LET ((RecordFs (record-Fs Signatures)))
                 (DECLARE (IGNORABLE RecordFs))
                 (LET ((AssertSignatures (assert-signatures Signatures)))
                   (DECLARE (IGNORABLE AssertSignatures))
                   ;; HACKED by JUN
                   (LET ((*load-eval-type-pairs* NIL))
                     (LET ((Evaluate (evaluate-file-contents File-S-D)))
                       (DECLARE (IGNORABLE Evaluate))
                       (FORMAT T "DEBUG load-help: ~W~%" File-S-D)
                       (SETQ *tempsigs* NIL)
                       (NREVERSE *load-eval-type-pairs*)
                       ))))))))))

(DEFUN extract-synonyms (V10)
 (COND ((NULL V10) NIL)
  ((AND (CONSP V10) (CONSP (CAR V10)) (EQ 'synonyms (CAR (CAR V10))))
   (output "~A~%" (eval (CAR V10))) (extract-synonyms (CDR V10)))
  ((CONSP V10) (cons (CAR V10) (extract-synonyms (CDR V10))))
  (T (implementation_error 'extract-synonyms))))

(DEFUN extract-datatypes (V11)
 (COND ((NULL V11) NIL)
  ((AND (CONSP V11) (CONSP (CAR V11)) (EQ 'datatype (CAR (CAR V11))))
   (output "~A~%" (eval (CAR V11))) (extract-datatypes (CDR V11)))
  ((CONSP V11) (CONS (CAR V11) (extract-datatypes (CDR V11))))
  (T (implementation_error 'extract-datatypes))))

(DEFUN extract-signatures (V16)
 (COND ((NULL V16) NIL)
  ((AND (CONSP V16) (CONSP (CAR V16)) (EQ 'define (CAR (CAR V16)))
    (CONSP (CDR (CAR V16))) (CONSP (CDR (CDR (CAR V16))))
    (EQ '{ (CAR (CDR (CDR (CAR V16))))))
   (LET* ((V17 (CAR V16)) (V18 (CDR V17)))
    (LET
     ((Signature
       (normalise-type (curry-type (collect-signature (CDR (CDR V18)))))))
     (CONS (LIST (CAR V18) Signature) (extract-signatures (CDR V16))))))
  ((CONSP V16) (extract-signatures (CDR V16)))
  (T (implementation_error 'extract-signatures))))

(DEFUN record-Fs (V19) (SETQ *tempsigs* (MAPCAR 'head V19)))

(DEFUN assert-signatures (V20)
 (COND ((NULL V20) NIL)
  ((AND (CONSP V20) (CONSP (CAR V20)) (CONSP (CDR (CAR V20)))
    (NULL (CDR (CDR (CAR V20)))))
   (LET* ((V21 (CAR V20)))
    (declare (CAR V21) (CAR (CDR V21))) (assert-signatures (CDR V20))))
  (T (implementation_error 'assert-signatures))))

; 2015-8-29 JUN hacked
(DEFUN evaluate-file-contents (V20)
 (COND ((NULL V20) NIL)
  ((CONSP V20)
   ;(output "~%") ;JUN Hacked
   (toplevel_evaluate (LIST (CAR V20)) 'true)
   (evaluate-file-contents (CDR V20)))
  (T (implementation_error 'evaluate-file-contents))))

(DEFUN echo (File) (IF (EQUAL File "") (DRIBBLE) (DRIBBLE File)) File)

(DEFUN dump (File)
  (LET* ((Out (make-string "~A.lsp" File))
         (Load (load File))
         (Defs (FORMAT NIL "~{~S~%~%~}" (find-defs (read-file File)))))
    (DECLARE (IGNORE Load))
    (write-to-file Out Defs)))

(DEFUN find-defs (V7)
 (COND ((NULL V7) NIL)
  ((AND (CONSP V7) (CONSP (CAR V7)) (MEMBER (CAR (CAR V7)) '(define defcc))
    (CONSP (CDR (CAR V7))))
   (CONS (source_code (CAR (CDR (CAR V7)))) (find-defs (CDR V7))))
  (T (find-defs (CDR V7)))))

(DEFUN read-chars-as-stringlist (Chars F)
  (read-chars-as-stringlist* Chars NIL NIL F))

(DEFUN read-chars-as-stringlist* (V3 V4 V5 V6)
 (COND ((NULL V3) (reverse (CONS (COERCE (reverse V4) 'STRING) V5)))
  ((CONSP V3)
   (if (apply V6 (CAR V3))
    (IF (NULL V4) (read-chars-as-stringlist* (CDR V3) NIL V5 V6)
     (read-chars-as-stringlist* (CDR V3) NIL
      (CONS (COERCE (reverse V4) 'STRING) V5) V6))
    (read-chars-as-stringlist* (CDR V3) (CONS (CAR V3) V4) V5 V6)))
  (T (implementation_error 'read-chars-as-stringlist*))))

(DEFUN delete-file (X) (IF (PROBE-FILE X) (DELETE-FILE X)) X)

