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

(eval-when (:compile-toplevel :load-toplevel :execute)
  (SETF *READTABLE* (COPY-READTABLE *READTABLE*))
  (SETF (READTABLE-CASE *READTABLE*) :PRESERVE)
  )

(IN-PACKAGE :JKIT.EMBED.CORE)

(SETQ *Failure* NIL)

(DEFUN compile (F X &OPTIONAL ERRORSTR)
  (LET ((O (FUNCALL F (LIST X NIL))))
    (IF (OR (failure? O) (NOT (NULL (CAR O))))
        (compile-error O ERRORSTR)
        (CADR O))))

(DEFUN compile-error (O ERRORSTR)
  (COND ((NULL ERRORSTR) 'fail!)
        ((CONSP (CAR O)) (ERROR ERRORSTR (first_n *first_n* (CAR O))))
        (T (ERROR "parse failure: ~A~%" ERRORSTR))))

(SETQ *first_n* 50)

(DEFUN first_n (N L)
  (COND ((ZEROP N) NIL)
        ((NULL L) NIL)
        (T (CONS (CAR L) (first_n (1- N) (CDR L))))))

(DEFMACRO defcc (Symbol &REST CC_stuff)
  (LIST 'compile_cc (LIST 'QUOTE Symbol) (LIST 'QUOTE CC_stuff)))

(DEFUN compile_cc (Symbol CC_Stuff)
  (COMPILE (EVAL (record_source Symbol
   (LIST 'DEFUN Symbol '(Stream)
    (CONS 'OR
      (MAPCAR 'cc_body
        (split_cc_rules CC_Stuff NIL))))))))

(SETQ *sources* NIL)

(DEFUN record_source (Symbol Source) 
  (PUSHNEW Symbol *sources*)
  (put-prop Symbol 'source Source))

(DEFUN put-prop (Ob Pointer Value) (SETF (GET Ob Pointer) Value))

(DEFUN get-prop (Ob Pointer Default) (GET Ob Pointer Default))

(DEFUN split_cc_rules (CCstuff RevRule)
  (COND ((NULL CCstuff)
         (IF (NULL RevRule)
             NIL
             (LIST (split_cc_rule (REVERSE RevRule) NIL))))
        ((EQ (FIRST CCstuff) (semi-colon))
         (CONS (split_cc_rule (REVERSE RevRule) NIL)
               (split_cc_rules (REST CCstuff) NIL)))
        (T (split_cc_rules (REST CCstuff) (CONS (FIRST CCstuff) RevRule)))))

(DEFUN split_cc_rule (Rule RevSyntax)
  (COND ((EQ (FIRST Rule) ':=)
         (IF (= (LENGTH (REST Rule)) 1)
             (LIST (REVERSE RevSyntax) (SECOND Rule))
             (LIST (REVERSE RevSyntax) (CONS 'LIST (REST Rule)))))
        ((NULL Rule)
         (warn (FORMAT NIL "~{ ~S~} has no semantics.~%" (REVERSE RevSyntax)))
         (split_cc_rule 
          (LIST ':= (default_semantics (REVERSE RevSyntax))) RevSyntax))
        (T (split_cc_rule (REST Rule) (CONS (FIRST Rule) RevSyntax)))))

(DEFUN default_semantics (Syntax)
  (COND ((NULL Syntax) Syntax)
        ((grammar_symbol? (CAR Syntax))
         (IF (NULL (CDR Syntax))
             (CAR Syntax)
             (LIST 'APPEND (CAR Syntax) (default_semantics (CDR Syntax)))))
        (T (LIST 'CONS (CAR Syntax) (default_semantics (CDR Syntax))))))

(DEFUN cc_body (Rule) 
  (LIST 'BLOCK 'localfailure (syntax (FIRST Rule) 'Stream (SECOND Rule))))

(DEFUN syntax (Syntax Stream Semantics)
  (COND ((NULL Syntax)
         (IF (AND (EQ Stream Semantics) (grammar_symbol? Stream))
             Stream
            `(LIST (FIRST ,Stream) ,(semantics Semantics))))
        ((grammar_symbol? (FIRST Syntax))
         (recursive_descent Syntax Stream Semantics))
        ((terminal? (FIRST Syntax))
         (check_stream Syntax Stream Semantics))
        ((jump_stream? (FIRST Syntax))
         (jump_stream Syntax Stream Semantics))
        ((checkf? (FIRST Syntax))
         (checkf_stream Syntax Stream Semantics))
        ((list_call? (FIRST Syntax))
         (list_stream (FIRST Syntax) (REST Syntax) Stream Semantics))  
        (T (ERROR "~S is not legal syntax.~%" (FIRST Syntax)))))

(DEFUN list_call? (Fragment) 
   (AND (CONSP Fragment)
        (EQ (FIRST Fragment) 'cons)
        (= (LIST-LENGTH Fragment) 3)
        (OR (ATOM (SECOND Fragment)) (list_call? (SECOND Fragment)))
        (OR (ATOM (THIRD Fragment)) (list_call? (THIRD Fragment)))))

(DEFUN list_stream (FSyntax RSyntax Stream Semantics)
  (LET ((Flat (CONS '<start_of_list> (decons FSyntax)))
        (NRSyntax (CONS '<end_of_list> RSyntax)))
       (syntax (APPEND Flat NRSyntax) Stream Semantics)))

(DEFUN <start_of_list> (Stream)
  (IF (AND (CONSP (FIRST Stream))
           (CONSP (FIRST (FIRST Stream))))
      (LIST (APPEND (FIRST (FIRST Stream)) (CONS '-end-of-list- (REST (FIRST Stream))))
            (SECOND Stream))
      NIL))

(DEFUN <end_of_list> (Stream)
  (IF (AND (CONSP (FIRST Stream))
           (EQ (FIRST (FIRST Stream)) '-end-of-list-))
      (LIST (REST (FIRST Stream)) (SECOND Stream))
      NIL))   

(DEFUN decons (X)
  (IF (CONSP X)
      (CONS (SECOND X) (decons (THIRD X)))
      X))

(DEFUN checkf? (Fragment)
  (AND (CONSP Fragment) 
       (SYMBOLP (CAR Fragment))
       (EQ '-*- (CADR Fragment))
       (NULL (CDDDR Fragment))))

(DEFUN checkf_stream (Syntax Stream Semantics)
  (LET* ((F (FIRST (FIRST Syntax)))
         (Test `(AND (CONSP (FIRST ,Stream))
                   (wrapper (,F (FIRST (FIRST ,Stream))))))
         (Action (syntax (REST Syntax)
                        `(LIST (REST (FIRST ,Stream)) (SECOND ,Stream))
                        Semantics))
        (Else *Failure*)) 
        (LIST 'IF Test Action Else)))

(DEFUN wrapper (X)
  (COND ((EQ X 'true) T)
        ((EQ X 'false) NIL)
        (T (ERROR "~S: non-boolean value returned~%" X))))

(DEFUN grammar_symbol? (Fragment)
  (AND (SYMBOLP Fragment)
       (LET* ((CHARS (COERCE (FORMAT NIL "~A" Fragment) 'LIST))
              (FCHAR (FIRST CHARS))
              (LCHAR (FIRST (LAST CHARS))))
              (AND (CHAR-EQUAL #\< FCHAR) (CHAR-EQUAL #\> LCHAR)))))

(DEFUN recursive_descent (Syntax Stream Semantics)
  (LET ((Test (LIST (FIRST Syntax) Stream))
        (Action (syntax (REST Syntax) (FIRST Syntax) Semantics))
        (Else *Failure*))
       `(LET ((,(FIRST Syntax) ,Test))
             (IF (NOT (failure? ,(FIRST Syntax)))
                 ,Action
                 ,Else))))

(DEFUN terminal? (Fragment)
  (AND (NOT (CONSP Fragment))
       (NOT (grammar_symbol? Fragment))
       (NOT (jump_stream? Fragment))
       (NOT (rest_stream? Fragment))
       (NOT (out_stream? Fragment))))

(DEFUN check_stream (Syntax Stream Semantics)
  (LET ((Test `(AND (CONSP (FIRST ,Stream))
                    (,(comparison_test (FIRST Syntax)) 
                      (FIRST (FIRST ,Stream))
                      ,(quote-me (FIRST Syntax)))))
        (Action (syntax (REST Syntax)
                        `(LIST (REST (FIRST ,Stream)) (SECOND ,Stream))
                        Semantics))
        (Else *Failure*)) 
        (LIST 'IF Test Action Else)))

(DEFUN comparison_test (Fragment)
  (COND ((SYMBOLP Fragment) 'EQ)
        ((NUMBERP Fragment) 'EQL)
        ((CHARACTERP Fragment) 'EQL)
        ((STRINGP Fragment) 'EQUAL)
        (T 'EQUAL)))

(DEFUN quote-me (Fragment)
  (IF (OR (NUMBERP Fragment)
          (STRINGP Fragment)
          (CHARACTERP Fragment)
          (NULL Fragment))
      Fragment
      (LIST 'QUOTE Fragment)))

(DEFUN eos? (Fragment) (EQ Fragment '!))

(DEFUN jump_stream? (Fragment) (EQ '-*- Fragment))

(DEFUN check_eos (Syntax Stream Semantics)
  (LET ((Test `(NULL (FIRST ,Stream)))
        (Action (syntax (REST Syntax)
                        `(LIST (REST (FIRST ,Stream)) (SECOND ,Stream))
                        Semantics))
        (Else *Failure*)) 
         (LIST 'IF Test Action Else)))  

(DEFUN jump_stream (Syntax Stream Semantics)
  (LET ((Test `(CONSP (FIRST ,Stream)))
        (Action (syntax (REST Syntax)
                        `(LIST (REST (FIRST ,Stream)) (SECOND ,Stream))
                        Semantics))
        (Else *Failure*)) 
        (LIST 'IF Test Action Else)))

(DEFUN semantics (Semantics)
  (COND ((NULL Semantics) NIL)
        ((EQ 'Stream Semantics) Semantics)
        ((throw_failure? Semantics) '(RETURN-FROM localfailure NIL))
        ((local? Semantics) (LIST (FIRST Semantics) 
                                  (SECOND Semantics) 
                                  (semantics (THIRD Semantics)) 
                                  (subst (SECOND Semantics)
                                         (LIST 'QUOTE (SECOND Semantics))
                                         (semantics (FOURTH Semantics)))))
        ((abs? Semantics) `(FUNCTION (LAMBDA (,(SECOND Semantics)) 
                                ,(SUBST (SECOND Semantics)
                                        (LIST 'QUOTE (SECOND Semantics))
                                        (semantics (THIRD Semantics))
                                        :TEST 'EQUAL)))) 
        ((terminal? Semantics) (IF (OR (STRINGP Semantics)
   				                       (NUMBERP Semantics)
  				                       (CHARACTERP Semantics)
   				                       (NULL Semantics))
                                   Semantics
			                       (LIST 'QUOTE Semantics)))
        ((grammar_symbol? Semantics) (LIST 'SECOND Semantics))
        ((out_stream? Semantics) '(CADR Stream))
        ((jump_stream? Semantics) '(CAAR Stream))
        ((rest_stream? Semantics) '(CAR Stream))
        ((CONSP Semantics)
         (IF (OR (CONSP (CAR Semantics)) 
                 (grammar_symbol? (CAR Semantics)))
              (CONS 'FUNCALL (MAPCAR 'semantics Semantics))
              (CONS (FIRST Semantics) 
                         (MAPCAR 'semantics (REST Semantics)))))))

(DEFUN local? (Semantics) 
 (AND (CONSP Semantics) (EQ (CAR Semantics) 'let) (= (LENGTH Semantics) 4)))

(DEFUN abs? (Semantics) 
 (AND (CONSP Semantics) (EQ (CAR Semantics) '/.) (= (LENGTH Semantics) 3)))

(DEFUN throw_failure? (Semantics) (EQL Semantics #\Escape))

(DEFUN rest_stream? (Semantics) (EQ Semantics '-s-))

(DEFUN out_stream? (Semantics) (EQ Semantics '-o-))

(DEFUN <e> (Stream) Stream)

(DEFUN failure? (X) (OR (NULL X) (EQL (CADR X) #\Escape)))
