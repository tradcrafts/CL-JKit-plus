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

'(DEFVAR *signatures*
 (MAKE-HASH-TABLE :SIZE 300 :REHASH-SIZE 2 :REHASH-THRESHOLD 0.8))

'(DEFUN setup-base-types ()
 (setup-signatures
  '(and (boolean --> (boolean --> boolean)) 
    append ((list A) --> ((list A) --> (list A))) 
    apply ((A --> B) --> (A --> B))
    assoc (A --> ((list (list A)) --> (list A))) 
    assoc-type (symbol --> (variable --> symbol))
    boolean? (A --> boolean)
    cd (string --> string) 
    character? (A --> boolean) 
    complex? (A --> boolean) 
    concat (symbol --> (symbol --> symbol)) 
    congruent? (A --> (A --> boolean)) 
    cons? (A --> boolean)
    list? (A --> boolean)

    closure? (A --> boolean)
    function? (A --> boolean)
    callable? (A --> boolean)    

    debug (A --> string)
    delete-file (string --> string) 
    difference ((list A) --> ((list A) --> (list A))) 
    dump (string --> string)
    echo (string --> string)
    element? (A --> ((list A) --> boolean)) 
    empty? (A --> boolean) 
    explode (A --> (list character)) 
    fail-if ((character --> boolean) --> (character --> character)) 
    fix ((A --> A) --> (A --> A)) 
    float? (A --> boolean) 
    freeze (A --> (lazy A))
    fst ((A * B) --> A)
    get-array ((array A) --> ((list number) --> (A --> A))) 
    head ((list A) --> A)
    if (boolean --> (A --> (A --> A)))
    if-with-checking (string --> (list A))
    if-without-checking (string --> (list A))
    include ((list symbol) --> (list symbol))
    include-all-but ((list symbol) --> (list symbol))    
    inferences (A --> number) 
    integer? (A --> boolean) 
    intersection ((list A) --> ((list A) --> (list A)))
    length ((list A) --> number) 
    load (string --> symbol) 
    make-array ((list number) --> (array A))
    maxinferences (number --> number) 
    map ((A --> B) --> ((list A) --> (list B))) 
    mapcan ((A --> (list B)) --> ((list A) --> (list B)))
    not (boolean --> boolean) 
    new-assoc-type ((A --> boolean) --> (symbol --> symbol))
    newsym (symbol --> symbol)
    newvar (variable --> variable)
    nth (number --> ((list A) --> A)) 
    number? (A --> boolean) 
    occurs-check (symbol --> boolean) 
    occurrences (A --> (B --> number)) 
    opaque (symbol --> symbol)
    or (boolean --> (boolean --> boolean)) 
    preclude ((list symbol) --> (list symbol))
    preclude-all-but ((list symbol) --> (list symbol))
    print (A --> A) 
    profile ((A --> B) --> (A --> B)) 
    profile-results (A --> symbol) 
    ps (symbol --> (list A))
    put-array ((array A) --> ((list number) --> (A --> A))) 
    random (number --> number)
    rational? (A --> boolean) 
    read-char (A --> character) 
    read-file (string --> (list unit))
    read-file-as-charlist  (string --> (list character)) 
    read-chars-as-stringlist 
       ((list character) --> ((character --> boolean) --> (list string))) 
    rational? (A --> boolean) 
    real? (A --> boolean)
    remove (A --> ((list A) --> (list A))) 
    reverse ((list A) --> (list A)) 
    round (number --> number) 
    snd ((A * B) --> B) 
    specialise (symbol --> symbol)
    speed (number --> number)
    sqrt (number --> number) 
    spy (symbol --> boolean) 
    step (symbol --> boolean) 
    string? (A --> boolean) 
    strong-warning (symbol --> boolean)
    sugar (symbol --> ((A --> B) --> (number --> (A --> B))))
    sugarlist (symbol --> (list symbol))
    symbol? (A --> boolean) 
    tail ((list A) --> (list A)) 
    tc (symbol --> boolean) 
    thaw ((lazy A) --> A)
    time (A --> A) 
    track (symbol --> symbol) 
    transparent (symbol --> symbol)
    tuple? (A --> boolean) 
    unassoc-type (symbol --> symbol)
    undebug (A --> string)
    unprofile ((A --> B) --> (A --> B)) 
    untrack (symbol --> symbol) 
    union ((list A) --> ((list A) --> (list A))) 
    unspecialise (symbol --> symbol)
    unsugar (symbol --> ((A --> B) --> (A --> B)))
    variable? (A --> boolean)
    version (string --> string) 
    warn (string --> string)
    write-to-file (string --> (A --> string)) 
    y-or-n? (string --> boolean) 
    qi_> (number --> (number --> boolean)) 
    qi_< (number --> (number --> boolean))
    qi_>= (number --> (number --> boolean)) 
    qi_<= (number --> (number --> boolean)) 
    + (number --> (number --> number)) 
    * (number --> (number --> number)) 
    - (number --> (number --> number)) 
    / (number --> (number --> number)) 
    ;== (A --> (B --> boolean))
    qi_= (A --> (A --> boolean))

    ;; ADDED by JUN
    qi_/= (A --> (A --> boolean))
    unsafeCast (A --> B)
    <<case>> (string --> A)
    <<case/where>> (string --> A)
    <<tests/case/where>> (string --> boolean)
    <<check/case/where>> (string --> boolean)
    <<lisp-code>> (string --> A)
    <<lisp-code-with-xi-vars>> (string --> (C --> A))
    <<native-lisp-call>> (string --> (C --> A))
    <<native-lisp-apply>> (string --> (C --> A))
    <<xi-simple-fail>> (boolean --> A)

    <<id>> (A --> A)
    
    <<case-where-test>>  (boolean --> (number --> boolean))
    <<case-where-check>> ((list boolean) --> boolean)
    
    unsafeFail (B --> A)
    failed?  (A --> boolean)
    fork (A --> ((A --> C) --> ((B --> C) --> C)))

    )))

;; Added by JUN
(DEFUN unsafeCast (a) a)
;; (DEFMACRO <<lisp-code>> (sym)
;;   (LET ((code (GET sym 'lisp-code)))
;;     (PRINT (LIST sym (SYMBOL-PLIST sym)))
;;     code))
(DEFMACRO <<lisp-code>> (fake-string)
  (SVREF fake-string 1))

  
(DEFMACRO <<lisp-code-with-xi-vars>> (fake-string consed-exps)
  ;;(PRINT (LIST fake-string consed-exps))
  (LET* ((source (SVREF fake-string 1))
         (lisp-side-vars (MAPCAR (LAMBDA (c) (IF (LISTP c) (FIRST c) c))
                                 (SECOND source)))
         (xi-side-exps (<from-consing> consed-exps)))
    `(LET ,(MAPCAR (LAMBDA (v e) (LIST v (lisp-form NIL e)))
                         lisp-side-vars
                         xi-side-exps)
       ,@(CDDR source))))

(DEFUN <escape-xi-value-for-lisp> (x)
  (COND ((AND (SYMBOLP x) (NOT (UPPER-CASE-P (CHAR (SYMBOL-NAME x) 0))))
          (LIST 'QUOTE x))
        (T x)))
              

(DEFMACRO <<native-lisp-call>> (fake-string consed-vars)
  (LIST* (SVREF fake-string 1)
         (<from-consing> consed-vars)))

(DEFMACRO <<native-lisp-apply>> (fake-string consed-vars)
  `(APPLY ',(SVREF fake-string 1)
          ,@(<from-consing> consed-vars)))

(DEFMACRO <<external-bind>> (fake-string)
  (ERROR "Xi: Misplaced ~W" (SVREF fake-string 1)))

(DEFMACRO <<lisp/bind>> (fake-string src main)
  (LET ((dst (SECOND (SVREF fake-string 1))))
    `(BIND ((,dst ,(lisp-form NIL src))) ,(lisp-form NIL main))))

(DEFMACRO <<lisp/unify>> (fake-string src main)
  (LET ((dst (SECOND (SVREF fake-string 1))))
    `(DO-UNIFY-IF (,(lisp-form NIL src) ,dst)
       ,(lisp-form NIL main)
       (ERROR "JKIT.LE: JKIT:UNIFY FAILED: ~W" ',dst))))

(DEFMACRO <<lisp/match>> (fake-string src main)
  (LET ((dst (SECOND (SVREF fake-string 1))))
    `(DO-MATCH-IF (,(lisp-form NIL src) ,dst)
       ,(lisp-form NIL main)
       (ERROR "JKIT.LE: JKIT:MATCH FAILED: ~W" ',dst))))

;(DEFMACRO <<lisp-code-with-xi-vars>> (fake-string consed-vars)
;  `'(,fake-string ,consed-vars ,(<from-consing> consed-vars)))

;; Added by JUN
(DEFUN <<xi-simple-fail>> (a) (DECLARE (IGNORE A)) '|<failure value>|)
(DEFSTRUCT <failureObject> VALUE)
(DEFUN unsafeFail (value)
  (MAKE-<failureObject> :VALUE value))
(DEFUN failed? (a)
  (IF (OR (EQL a '|<failure value>|)
          (<failureObject>-P a))
    'true
    'false))

(DEFUN fork (x f g)
  (COND ((EQL x '|<failure value>|)
          (FUNCALL g nil))        
        ((<failureObject>-P x)
          (FUNCALL g (<failureObject>-VALUE x)))
        (t (FUNCALL f x))))

(EXPORT '(unsafeCast failed? unsafeFail |@failure| fork))


(DEFUN setup-signatures (L)
   (COND ((NULL L) NIL)
         (T (add-to-type-discipline (CAR L) (CADR L)) (setup-signatures (CDDR L)))))

(DEFUN declare (F Type) 
  (record_type F (curry-type Type)) 
  F)

(DEFUN record_type (FUNC TYPE)
  (warn-type-clash FUNC (normalise-type TYPE) (normalise-type (signature FUNC)))
  (add-to-type-discipline FUNC TYPE))

;; (DEFUN warn-type-clash (FUNC NEW OLD)
;;   (COND ((AND (NOT (NULL OLD)) (NOT (variant? NEW OLD)))
;;          (warn (FORMAT NIL "~A already has a type inconsistent with this declaration." FUNC))
;;          (FORMAT T "Proceeding may make your program type insecure.~%~%")
;;          (IF (NOT (Y-OR-N-P "proceed anyway? ")) (ERROR "aborted~%")))))      

;; 2015-8-29 JUN hacked
(DEFUN warn-type-clash (FUNC NEW OLD)
  (COND ((AND (NOT (NULL OLD)) (NOT (variant? NEW OLD)))
         (warn (FORMAT NIL "~A already has a type inconsistent with this declaration." FUNC))        
          )))

(DEFUN signature (FUNC) 
  (LET ((SignatureCode (GETHASH FUNC *signatures*)))
       (IF (NULL SignatureCode)
           NIL
           (FUNCALL SignatureCode)))) 

(DEFUN variant? (NEW OLD)
  (COND ((EQUAL NEW OLD))
        ((EQUAL (CAR OLD) (CAR NEW)) (variant? (CDR OLD) (CDR NEW)))
        ((AND (EQ 'true (variable? (CAR OLD)))  (EQ 'true (variable? (CAR NEW))))
         (variant? (SUBST 'a (CAR OLD) (CDR OLD)) (SUBST 'a (CAR NEW) (CDR NEW))))  
        ((AND (CONSP (CAR OLD)) (CONSP (CAR NEW)))
         (variant? (APPEND (CAR OLD) (CDR OLD)) (APPEND (CAR NEW) (CDR NEW))))
	  (T NIL)))

(DEFUN add-to-type-discipline (FUNC TYPE)
    (SETF (GETHASH FUNC *signatures*)
          (COMPILE NIL (LIST 'LAMBDA () (st_code TYPE))))) 

(DEFUN st_code (Type)
  (LET ((Vs (extract-vars Type)))
       (st_code* Vs (bld_st_code Vs Type))))

(DEFUN bld_st_code (Vs Type)
  (COND ((NULL Type) NIL)
        ((CONSP Type)
         (LIST 'CONS (bld_st_code Vs (CAR Type))
                     (bld_st_code Vs (CDR Type))))
        ((MEMBER Type Vs) Type)
        (T (LIST 'QUOTE Type))))

(DEFUN st_code* (Variables Type)
  (IF (NULL Variables)
      Type
      (LIST 'LET
        (MAPCAR (FUNCTION (LAMBDA (X) (LIST X (LIST 'GENSYM "A"))))
                Variables)
        Type)))

;(setup-base-types)

'(DEFUN destroy (Func)
  (REMHASH Func *signatures*)
  (REMHASH Func *arity*)
  (FMAKUNBOUND Func))
