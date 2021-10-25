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

(PROCLAIM '(SPECIAL *multi* *strong-warning* *currfunc* *sysfuncs* *speed*
                    *alist* *exempted-macro* *history* *qi_home_directory*
					*version* *tempsigs* *assoctypes* *maxcomplexity*
                    *backtrack* *occurs* *inferences* *syntax-in* *syntax-out*
                    *special* *extraspecial* *alldatatypes* *datatypes*
                    *synonyms* *maxinferences* *spy* *call* *tc* *step*
                    *Failure* *first_n* *sources* *failure-object* *alphabet*
                    *signatures* *arity* *allsynonyms*))


#-(OR SBCL CMU)
  (DEFCONSTANT *alphabet* '(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z))

;; SBCL compilation of DEFCONSTANT is a bit screwed
#+(OR SBCL CMU) (SETQ *alphabet* '(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z))

(DEFPARAMETER *sysfuncs* 
  '(#:<e> #:and #:append #:apply #:assoc #:assoc-type #:boolean? #:cd #:character? #:compile #:complex? #:concat #:congruent? #:cons? #:cons #:datatype #:declare #:define #:defcc #:delete-file #:destroy #:difference #:do #:dump #:echo #:element? #:empty? #:error #:eval #:explode #:fail-if #:findall #:fix #:float? #:freeze #:fst #:gensym #:get-array #:get-prop #:head #:identical #:if #:if-with-checking #:if-without-checking #:include #:include-all-but #:input #:input+ #:integer? #:inferences #:intersection #:length #:let #:lineread #:list #:load #:m-prolog #:make-array #:make-string #:map #:mapcan #:maxinferences #:multi #:not #:nth #:number? #:occurrences #:occurs-check #:or #:opaque #:output #:print #:profile #:preclude #:preclude-all-but #:profile-results #:prolog? #:put-array #:put-prop #:quit #:random #:rational? #:read-char #:read-file-as-charlist #:read-file #:read-chars-as-stringlist #:real? #:remove #:reverse #:round #:rule #:s-prolog #:save #:set #:snd #:specialise #:speed #:spy #:sqrt #:step #:string? #:strong-warning #:sugarlist #:sugar #:subst #:symbol? #:synonyms #:tail #:tc #:thaw #:time #:track #:transparent #:tuple? #:type #:typecheck #:unassoc-type  #:union #:unprofile #:unsugar #:untrack #:value #:unspecialise #:variable?  #:warn #:write-to-file #:y-or-n? #:qi_> #:qi_< #:qi_>= #:qi_<= #:qi_= #:+ #:* #:/ #:/. #:- #:qi_= #:qi_/= #:|@p| #:|@c| #:|@sv| #:svlen #:svref #:when #:is #:bind #:return #:call #:none #:only
    #:delay #:force #:& #:! #:promise? #:wrap #:unwrap #:zip #:unzip
    #:regex #:$ #:$? ;; <- 正規表現関係
    #:closure? #:function? #:callable? #:list? #:&cons! #:&cons
     ;;
     #:def #:compose #:flip
     #:unsafeCast #:<<xi-simple-fail>> #:unsafeFail #:failed? #:fork
     ))





(DEFUN <intern> (tmpsym)
  (LET ((name (SYMBOL-NAME tmpsym))
        (mpkg (MEMOIZED (FIND-PACKAGE :JKIT.MSPACE))))
    (AIF (FIND-SYMBOL name)
         (PROGN (IMPORT IT mpkg)
                IT)
         (INTERN name mpkg))))

(SETQ *sysfuncs* (MAPCAR #'<intern> *sysfuncs*))
(IMPORT *sysfuncs*)

(MAPC (LAMBDA (sym) (IMPORT (<intern> sym)))
      '(#:true #:false #:|{| #:|}| #:-> #:<- #:--> #:_ #:|:| #:where #:variable #:boolean #:symbol #:string 
        #:character #:list #:number #:array #:|;| #:|,| #:&& #:mode #:name #:>> #:yes #:no #:typecheck 
        #:wff #:verified #:call #:when #:-*- #:-s- #:cut #:-*- #:! #:loaded #:lazy #:in #:out #:fail! #:=!
        #:profiled
        
        #:def #:decl #:type #:|@where| #:|@satisfied| #:where* #:cl #:cl*
        #:loop #:while #:until #:break #:BREAK #:provide #:provide* #:for #:count
        #:case #:xi_lambda #:lambda #:fork #:=> #:view #:|@sv*| #:|@| #:unless #:== #:!= #:=== #:!== 
        
        #:let* #:compose #:flip
        ;; &で始まるシンボルはQSPACEにインターンされるため、特にグローバルなシンボルについてはエクスポートしておく
        #:&CONS #:&CONS! #:&LIST #:&LIST*))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Added by JUN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 構文解析器からは文字列として認識される `fake-string'
(DEFUN make-fake-string (info)
  (VECTOR '<fake-string-tag> info))
(DEFUN fake-string? (x)
  (AND (SIMPLE-VECTOR-P x)
       (EQL 2 (LENGTH x))
       (EQL '<fake-string-tag> (SVREF x 1))))
(DEFUN fake-string-info (fs)
  (SVREF fs 1))

  


