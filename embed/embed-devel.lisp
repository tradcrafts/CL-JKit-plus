;; -*- coding: utf-8 -*-
;; This file is part of JKIT.
;; Copyright (c) 2018-2021 tradcrafts tradcrafts

(jkit.base:jkit-base-header)
(in-package :jkit.embed.devel)


#Comment

(do-unify :and #`:and)
(do-unify 2 (:or (:call var) 3) :define ((var (:-> :type symbol))))


(<verify-let-if-src> '(:complex a ))

(<verify-let-if-dst> '(:match 2 3 4))
(<verify-let-if-dst> '(not a))

(defun <verify-dst> (x)
  (do-unify x
    (:OR (:CALL var)
         T
         NIL
         (#`:not (:CALL var))
         (:AND ((:-> :EQ :AND :OR :NONE) . ?r)
               (:FOR r (:EACH+ (:CALL var))))
         (:AND ((:-> :EQ :unify :match) ? . ?r)
               (:HERE (proper-list-p r))))
    :define
    ((var (:-> :view (x) (and (symbolp x)
                              (not (keywordp x))
                              (not (null x))
                              (not (eq T x))))))))

(defun <complex-src?> (x)
  (and (consp x) (eq :complex (first x))))

(defun <verify-src> (x)
  (cond ((<complex-src?> x)
          (and (proper-list-p x)
               (<= 3 (list-length x))))
        (t t)))

(defmacro let-if (&whole definition
                  dst src &body then-and-else)
  (unless (and (<verify-dst> dst)
               (<verify-src> src)
               then-and-else
               (<= (list-length then-and-else) 2))
    (error "LET-IF: syntax error: ~W" definition))

  
  (let* ((then (first then-and-else))
         (else (second then-and-else))
         (xs (if (<complex-src?> src)
               (cdr src)
               (list src)))
         (src-arity (list-length xs)))
      
          
    (if (symbolp dst)
      (cond ((eq T dst) `(progn ,@xs ,then))
            ((null dst) `(progn ,@xs ,else))
            ((< 1 src-arity) (error "too many sources"))
            (t  (let ((tmp (gensym)))
                  ;; AIFに近い挙動だが、else節からはdstは見えない
                  `(let ((,tmp ,src))
                     (if ,tmp
                       (let ((,dst ,tmp)) ,then)
                       ,else)))))
      ;; 
      (let* ((dst-arity (list-length (cdr dst)))
             (cmd (first dst))
             (operator (case cmd
                         (:unify 'do-unify-if) (:match 'do-match-if)
                         (:and 'and) (:or 'or) (:none 'none) (:not 'not))))
        
        (unless (eql src-arity dst-arity)
          (error "arity err"))
        (case cmd
          ((:unify :match)
            (if (eql 1 src-arity)
              `(,operator (,src ,(second dst)) ,then ,else)
              `(,operator (,xs ,(cdr dst) :enumerated t) ,then ,else)))
          
          ((:and :or :none) (let* ((vars (cdr dst))
                                   (tmps (freplicate (list-length vars) #'gensym)))
                              `(let ,(mapcar #'list tmps xs)
                                 (if (,operator ,@tmps)
                                   (let ,(mapcar #'list vars tmps)
                                     ,then)
                                   ,else))))
          )))))

(defmacro let-when (dst src &body body)
  `(let-if ,dst ,src (progn ,@body)))

(defmacro let-case (&whole definition
                    src &body dst-and-body-clauses)
  (flet ((verify-clauses (cs)
           (do-unify cs
             (:EACH (:AND ((:-> :view (x) (<verify-dst> x)) . ?r)
                          (:HERE (proper-list-p r)))))))
    (unless (and (<verify-src> src)
                 (verify-clauses dst-and-body-clauses))
      (error "LET-CASE: syntax error: ~W" definition))

    (let* ((tmp-src (if (<complex-src?> src)
                      (cons :complex (freplicate (list-length (cdr src)) #'gensym))
                      (gensym)))
           (bindings (if (atom tmp-src)
                       `((,tmp-src ,src))
                       (mapcar #'list (cdr tmp-src) (cdr src))))
           )

      `(let ,bindings
         ,(reduce (lambda (clause else) `(let-if ,(first clause) ,tmp-src
                                           (progn ,@(rest clause))  ,else))
                  dst-and-body-clauses
                  :initial-value nil :from-end t)))
    ))

(defmacro let-cond (&whole definition
                    &body dst-src-and-body-clauses)
  (flet ((verify-clauses (cs)
           (do-unify cs
             (:EACH (:AND ((:-> :view (x) (<verify-dst> x)) (:-> :view (x) (<verify-src> x)) . ?r)
                          (:HERE (proper-list-p r)))))))
    (unless (verify-clauses dst-src-and-body-clauses)
      (error "LET-COND: syntax error: ~W" definition))

    (reduce (lambda (clause else) `(let-if ,(first clause) ,(second clause)
                                     (progn ,@(cddr clause))  ,else))
            dst-src-and-body-clauses
            :initial-value nil :from-end t)))


(defmacro let-while (dst src &body body)
  `(while t
     (let-if ,dst ,src
       (progn ,@body)
       (return))))


(defun <split-lambdalist> (params)
  (let ((pos (position-if (lambda (x) (member x '(&OPTIONAL &REST &KEY &AUX)))
                          params)))
    (if pos
      (list (subseq params 0 pos) (subseq params pos))
      (list params nil))))

(defmacro let-lambda ((&rest params) &body body)
  (bind (all-vars
         srcs
         ((dsts rest-params) (<split-lambdalist> params)))
    (dolist (d dsts)
      (unless (<verify-dst> d)
        (error ""))
      (let* ((arity (if (consp d)  (list-length (cdr d))  1))
             (vars (freplicate arity #'gensym)))
        (setf all-vars (nconc all-vars vars))
        (if (eql 1 arity)
          (setf srcs (nconc srcs (list (first vars))))
          (setf srcs (nconc srcs `((:complex ,@(copy-list vars))))))))

    `(lambda (,@all-vars ,@rest-params)
       ,(reduce (lambda (dst-src rest)
                  `(let-if ,(first dst-src) ,(second dst-src) ,rest (values nil |let-failed|)))
                (mapcar #'list dsts srcs)
                :from-end t :initial-value `(progn ,@body)))))
    
      
        
      
(let-lambda (x (:unify y z)) (list x y))
(let ((x '(1 2 3 4 2 5 1)))
  (let-while (:unify (:and (?a ?b . ?) (:here (< a b))))
      x
    (print x)
    (setf x (cdr x))))
    
(cond (t 3))
(let ((foo 3)))
(let-if nil (:complex a b) 'ok 'ng)
(let-cond ((:unify ?x (?y)) (:complex 1 '(2)) (list x y))
          (T nil 'ng))
(let-case (:complex t 4) ((:and x y) (list 'a x y)) ((:or x y) (list 'b x y)) (t err))

(let-if (:and a) 100 (list 'and a) 'ng)
(let-if (:none a b) (:complex nil nil) (list 'and a b))
(let-if (:unify (?a ?b)) '(1 2) (list 'unify b a) 'ng)
(let-if (:match (list a b)) '(1 2) (list 'match b a) 'ng)
(let-if (:unify (?a ?b) (?c ?a)) (:complex '(1 2) '(3 1)) (list a b c) 'ng)
(labels ((aa (x) 1)
       (bb (x) (+ 100 (aa x))))
  (bb 30))
        
        
      
      
    (aif a b c)
(let-if foo bar
  baz
  boz)
    bar
  c
  d)

(in-package :xi-user)
(common-header :xi)

(xi.core::|lisp-form| nil '(|cons| |bar| (|cons| |foo| NIL)))
(xi.core::|wrapper| (xi.core::|symbol?| '|foo|))

(bind (((a _) '(1 2)) (b a)) a)

(\xdef tes
      [_ [X]] Y -> [X '(let Y X
                           X Y
                           [X Y])])

;(~tes 1 2)

(\xdef (t-test1:number->number)
       ;; 型チェックを働かせるにはlet*を使う
       X -> (let* A X
                  B (+ X 1)
                  (* A B)))
(\xdef t-test2
       ;; 複数バインドのlet構文は型チェックが効かない
       X -> (let A X
                 B X
                 (+ A B)))

(~t-test1 3)
(\xdef letTest
       X -> #{let*
                [A B] X
                [C] A
                [D] B
                `(:bind (e f . r)) X
                `(:bind #(g h)) `(:with (x (a-c c)) (vector x c))
                `(:unify (?x ?x . ?y)) [ A A B E F R G H]
                `(:match (LIST p1 p2)) [foo 1000]
                [Q1 Q2'Q3] [X A B C D]
                [C D E F R G H X Y P1 P2 done Q1 Q2 Q3])

(\xdef ttest; (ttest:number->number->number)
       X Y -> (where 0 X 1 Y (let* A X B Y (+ A B)))
       _ _ -> -1)

(\xdef ttest2; (ttest2:number->number->number)
       X Y -> (where
               0 X
               1 Y
               #{case (+ X Y)
               2 -> -2
               1 -> -1
               _ -> 0)
       _ _ -> 100)

(\xdef tes X <- `(+ 1 X),number?)

(\xdef tes2 X -> (let* A (+ X 1)
                       B (+ A 2)
                       [`(LIST A B)])
       )

(\xdef tes3 X Y -> (let X Y
                        Y X
                        [X Y]))

(\xdef c2
       X Y -> (case (X,Y)
                0 1 -> ptn1
                A B,(> A B) -> ptn2
                _ _ -> ptn3))


(\xi (cl PRINT (c2 0 1))
     (cl PRINT (c2 100 200))
     (cl PRINT (c2 200 100)))

(defun add (a)
  (\xlambda X,(number? X) -> (case where
                               (< X 100) -> (+ X `a)
                               true -> (* X `a))
            X,true->[add X and `a]))

(\xdef g1
       X Z -> (where
               [_ Y] X
               [_'R] Z
               (case [Y'R]
                 [1 2'_] -> 12
                 [2 3 4'_] -> 234
                 [3'Z] -> [rest Z]
                 _ -> other))
       _ _ -> ng)

(\xdef g2
       X Y->(where 
             0 X
             1 Y
             first)
       X Y->(where
             0 Y
             (+ X Y))
       _ _->ng)

(\xdef g3
       X->(where
              0 X
              30)
       _->-10)

(\xi (g3 0))

(\xi
 (cl PRINT (g1 1 2))
 (cl PRINT (g1 [0 1] [a 2 3]))
 (cl PRINT (g1 [0 2] [a 3 4]))
 (cl PRINT (g1 [1 2] [3]))
 (cl PRINT (g1 [2 3] [4 5])))
 

(\xdef f2
         X -> (case where
                (number? X) <- (if (> X 100) bignum @failure)
                (number? X) -> (case X
                                 Y,(and (< Y 1000) (do (print [y ys Y]) true)) -> num)
                (symbol? X) -> sym)
         _ -> other)

(\xi
 (cl PRINT (f2 3))
 (cl PRINT (f2 300))
 (cl PRINT (f2 hello))
 (cl PRINT (f2 [foo])))

;(~ps '~f2)

(\xi (def f1
         X <- (case 0
                N,(number? X) -> num
                N,(symbol? X) -> sym
                _->@failure)
         _ -> ng)

     (cl PRINT (f1 -1))
     (cl PRINT (f1 10))
     (cl PRINT (f1 100))
     (cl PRINT (f1 foo))
     (cl PRINT (f1 [foo]))

     (f1 3))


#Comment

#Comment

(DEFUN <transform-case-where-syntax> (clauses)
  (LET (test-exps
        main-exps
        (index 0)
        (tmpvar (GENSYM "X")))
    (DO ((xs clauses (CDDDR xs)))
        ((NULL xs))

      (PUSH (FIRST xs) test-exps)
      (UNLESS (MEMBER (SECOND xs) '(-> <-))
        (ERROR "SYNTAX ERROR: (case where ...)"))
      (COND ((EQL '|,| (FOURTH xs))
              (PUSH (SUBSEQ (CDR xs) 0 4) main-exps)
              (SETF xs (CDDR xs)))
            (T (PUSH (SUBSEQ (CDR xs) 0 2) main-exps)))
      )

    (SETF test-exps (nreverse test-exps)
          main-exps (nreverse main-exps))
    ;;
    `((|/.| true 
            (case (0)
              ,@(MAPCAN (LAMBDA (test main) (LIST* tmpvar '|,| (LIST '<check-for-case-where-syntax> test) main))
                        test-exps
                        main-exps)))
            (<tests-for-case-where-syntax> ,@test-exps))
    
    ;(LIST test-exps main-exps)
    ))

(<transform-case-where-syntax> '(a1 -> b1 |,| c1
                                 a2 -> b2
                                 a3 -> b3
                                 a4 <- b4 |,| c4
                                 )
                               )
    




(\xi (def f1
         X -> (where
               true (number? X)
               _ X
               true (> X 0)
               (if (< X 100) small big))
         _ -> ng)

     (cl PRINT (f1 -1))
     (cl PRINT (f1 10))
     (cl PRINT (f1 100))
     #)

(~ps '~f1)
#Comment

;(\xDef (foo:number->number)
; X->

(\xi (def bar
         0 -> ok
         X <- (if (> X 100) (+ X X) @failure)
         _ -> failed!)
     (cl PRINT (bar 20))
     #)


(\Xi (def foo
         X Y ,(number? X)
         <- (case (X Y)
              0 _ -> Y
              _ [A B] -> (case (A)
                           0->[A B]
                           1,(number? B) <- (if (> B A) [B A] @failure)
                           _ -> [A B B A])
              _ _ -> @failure
              )
         ;A B <- (if (and (number? A) (number? B)) (* A B) @failure)

         A B , (and (number? A) (number? B))
         <- (- A B) , (> 10000)
         
         A B
         <- (case (A)
              [X] -> (#ab,X)
              [X Y] -> (#ab,Y,X)
              _ -> @failure)
         _ B -> (#doyanen,B)
         )

     (cl PRINT (foo 0 ok))
     (cl PRINT (foo 1 [100 200]))
     (cl PRINT (foo 1 [0 200]))
     (cl PRINT (foo 1 [1 200]))
     (cl PRINT (foo 1 [1 -10]))
     (cl PRINT (foo 1 [1 sym]))
     (cl PRINT (foo [30] ng))
     (cl PRINT (foo [30 40] good))
     (cl PRINT (foo [300 400 500] good))
     (cl PRINT (foo 1000 1))
     (cl PRINT (foo 10000000 100))
     #)


;(print (~ps '~foo))
#Comment
 
(~number? 3)

(\Xi (def testestes
         (#just#,X) -> X
         (#nothing#) -> 

(\Xi (def tes
         X Y ->(where
                [A] X
                [B C] (view Y)
                (where
                 true (or (= B 0) (= B 1))
                 [first-rule A B C]))
         ;;@satisfied true
         ;;#t #f
         
         _ _ -> second-rule)
     (def view
         0 -> [0 a]
         1 -> [1 b]
         2 -> [q z]
         _ -> other)

     (def bar
         X Y @where (/= X Y)
         <-(where*
                [A B] X
                [C D E] B
                [A B C D E Y])
         _ _ ->failed!)

     (cl PRINT (tes [1] 0))
     #)

#Comment



(~tes '(1) 0)
(symbol-package '~case)
(\xi (def foo
         XS YS ->(bind [X] XS
                         [_ X Y] YS
                         (+ X Y X Y)))
     (def bar
         1 2 X-> (bind foo X the-first-rule)
         X _ _ -> (((\[0 Y] [Z 1] Q->hello) X) X)
         _ _ [X]-> (+ X X X)
         _ _ _ -> other)
     ;;(cl PRINT (foo [10] [0 20]))
                                        ;(cl PRINT ((\(0)->3000) ar))
     (cl PRINT (bar [0 1] [2] [300]))
     (cl PRINT (bar 1 2 foo))
     #)


#Comment

(DEFUN expand-bind-syntax (V)
  (LET ((main-exp (CAR (LAST V)))
        (pair-stream (BUTLAST V))
        params
        patterns)
    (DO ((xs pair-stream (CDDR xs)))
        ((NULL xs))
      (PUSH (FIRST xs) patterns)
      (PUSH (SECOND xs) params))

    (LET ((nested-lambdas
            (REDUCE (LAMBDA (ptn exp) `(L ,ptn ,exp))
                    (nreverse patterns)
                    :INITIAL-VALUE main-exp :FROM-END T)))
      (REDUCE #'LIST
              (nreverse params)
              :INITIAL-VALUE nested-lambdas))))
      
              

(reduce 'list '(a b c) :initial-value 'init)
(expand-bind-syntax '(a b c d e f g h exp))
(expand-bind-syntax '(a b exp))


(\xi
 (def (<anyType>:datatype)
     X:A.<=>X:any.)
 #)

(defmacro ~unsafeTyping (x &rest rest)
  (declare (ignore rest))
  (if (and (symbolp x)
           (not (upper-case-p (char (symbol-name x) 0))))
    (list 'quote x)
    x))

(\xi
                                        ;(def idnt X _ -> X)
 (def (<testDatat>:datatype)
     ==> (unsafeTyping X A) : A.
     ==> (unsafeTyping X A B) : (A B).
     ==> (unsafeTyping X A B C) : (A B C).
     ==> (unsafeTyping X A B C D) : (A B C D).
     ==> (unsafeTyping X A B C D E) : (A B C D E).)

 (decl (type anylist:[any]))
 (def (tes:number->string)
     X->(unsafeTyping X string))
 (def (tes:number->[number])
     _->(unsafeTyping a (list number)))


 (print (tes 100))
 #)


(\xi
 (def (tes:number->number)
     0-> (unsafeCast [`(symbol-package 'foo) `(sqrt 100)])
     1->  |comment)))...| `(print 'hello!)
     X @where false -> `(progn
                             (print 'yah!)
                             (list 'doyanen 'X 'X 'ok))
     Var @where false
     -> `(:with
             (|Var|)
           #{let ((v |Var|))
           (* 10000 (+ v (sqrt v))))

     X @where (= X 12345) -> (cl LIST 1 2 doya (#[X X],X) [X X X doya X])
     X @where (= X 23456) -> (cl* LIST 1 2 doya (@p [X X] X) [X [X [X]] foobar X])
     X->(cl VECTOR a b c 0.0 X)
     X -> (unsafeCast [X okokok 1]))
 
 ;;_->(unsafeTyping '(sqrt 10) number))
 (cl PRINT (tes 0))
 (cl PRINT (tes 1))
 (cl PRINT (tes 2))
 (cl PRINT (tes 200))
 (cl PRINT (tes -3))
 (cl PRINT (tes 12345))
 (cl PRINT (tes 23456))
 ;(print (unsafeTyping foo number))
 #)

#Comment 

(print '(\xi
         ''hello
         (print  "foooo")
                                        ;(print  (foo bar baz))
         'world
         '#(hello world ~c ~man)
          (def (tes:number->number)
     _->'(sqrt 10))

         #))

#Comment




(\xi
 (def (triple:any->any->any->[any])
     A B C->[A B C])
 (def (tes:number->[any])
     X @where (number? X) ->(triple X a 3)
     X->(triple X X (triple a b X)))
 (def (tes2:[any]->number)
     [1 a] -> 0
     [_ 100`_] -> 1
     _ -> 2)
 (tes x)
 (print (tes2 [0 100]))
 #)

#Comment


(\xi
 (def add-nt A B -> (+ A B))
 (decl (add-nt:number->number->number)
       (type price:number))
 (def (test:number->price)
     X->(- 100 (add-nt X X)))
 (print (test 10))
 #)

'(print '(\Xi
         (print [a])
         (+ 1 2)
         (+ 3 2)
         (def add-nt A B -> (+ A B))
         (def (add-t:number->number->number) A B -> (+ A B))
         (decl (my:integer->integer))
         (decl (type price:number))
         (decl
          (my:integer->integer)
          (type price:number)
          (type adding:number->number->number))
         #))




(\Xi+
 (define idnt {A-->[[A]]}
         X->[[X X] [X] []])
 #)

(define-data md (ju t) (jo t t) noth)
(define-internal-data md# (ju# t) (jo# t t) noth)

(\Xi+
 (datatype mdDataDecl
           X:A.<=>(@p ju X):(md A).
           X:A.Y:A.<=>(@p jo [X Y]):(md A).)
 (define ge {(md A)-->A}
         (@p ju X)->X
         (@p jo [_ X])->X)
 #)

(\Xi (define tak
         (@p ju X) -> [X X])
     (define tes2
         [X Y] -> (+ X Y))
     #)

(\Xi+
 (def (integerDataType:datatype)
     if(integer? A)==>A:integer.
     A:integer.==>A:number.
     A:integer.B:integer.<=>(+ A B): integer.)

 (def (integer/DataRule:datatype)
     if(element? OP [* / -])
     A:integer.B:integer.
     <=>
     (OP A B): integer.)

 (def (any/dataType:datatype)
     ==>X:any.)

 (def (foo:integer->(integer->(integer,boolean,any)))
     0->(\A->(#(- A 1000),true,a))
     X->(\A->(#(- A X 30000),false,-21.3)))

 (def (bar:(number,symbol)->symbol)
     (#0,X)->X
     (#1,_)->hello)

 (datatype foobar
                                        ;A:number.B:number.<=>(@p A B):nums.
           A:(number,number).<=>A:nums.
           )
 (def (tes:nums->number)
     (#0,_) -> -1
     (#X,0) -> X)
 #)

(print (funcall (~foo 1) 3))
(print (~bar (xtuple 0 'world)))
(print (~bar (xtuple 1 'world)))

(\Xi
 (def bar 
     0 B->[B a a B]
     1 B->[a B B a]
     _ B->[B B B B])
 #)

(print (~bar 0 'x))
(print (~bar 1 'x))
(print (~bar 2 'x))


(\Xi
 (def unlift X->X)
 (declare unlift [[either A] --> A ])
 (def lift X->X)
 (declare lift [A --> [either A]])
 (def cast X->X)
 (declare cast [any --> A])
 (def check failed->true _->false)
 (declare check [any --> boolean])
 (def put -> okok)
 (declare put [symbol])
 #)


(\Xi+
 (def (either:datatype)
     ==> failed:e-failed.
     X:e-failed. ==> X:(either A).
     X:A. ==> X:(either A).
     ;let A (newsym a) ==> failed:(either A).
     ;X:A. <=> X:(either A).
     )
 ;    let A(gensym a)==>failed:(either A).
 ;    let A (gensym a) X:A.<=>X:(either A).)
 (def (id1:A->A)
     X->X)
 (def (f1:number->number)
     X->(id1 X))
 ;(id1 (\X->2))

 (def (ide:(either A)->(either A))
     failed -> failed
     X -> X)

 (def (foo1:number->number)
     X->(unlift (lift X)))
 ;;(lift 3)

 ;;(f1 (cast ok))

 (def (foo2:number->number)
     X<-(if (> 0 X) @failure X)
     X @where (< X -10) ->10000
     _->(cast man))

 ;(define cnst {number} ->3)
 #)


(~foo2 -300000)

(\Xi+
 (def (bar2:number->number)
     X->(unsafeCast foo))

 (failed? 3)
 (bar2 (unsafeFail true))

 (def (foo3:number->number)
     X <- (if (> 0 X) @failure X)
     X @where (< X -10) <- (+ X 10000) @satisfied (/= 9000)
     ;X  <- (+ X 10000) @satisfied (/= 9000)
     _->(unsafeCast man))

 #)

(print (~foo3 -2))
(print (~foo3 20))
(print (~foo3 -200))
(~foo3 -1001)
;;;;;;
#Comment

(def (foo:integer->integer)
x    BODY)

(integer,integer)

(@p just# X) <-> (just#*X)

(position-if (lambda (x) (not (numberp x))) '(1 2 3))
(subseq '(q 1 2 3) 0 nil)

;;CL
(defun ochinchin (xs)
  (mapcon (lambda (xs &aux (head (first xs)) (tail (rest xs)))
            (when (symbolp head)
              (list (subseq xs 0 (position-if (lambda (x) (not (numberp x))) tail)))))
          xs))

(ochinchin '(A 1 2 3 B 1 2 C 1 2 3 4))
==> ((A 1 2) (B 1) (C 1 2 3 4))




(remove 'a '(a b c d a))


(~integer? 3)

'(\Xi X<--->Y--> A#)


(~element? 3 '(13 3 2))
(funcall (~foo 0)100)

(\Xi (define tolis
         {A-->[(@p A integer)]}
         X->[(@p X 0)(@p X 1)(@p X 3)])
     (define fromlis
         {[(@p A integer)]-->[A]}
         []->[]
         [(@p X 0)`XS]->(fromlis XS)
         [(@p X _)`_]->[X X])
     #)

(~tolis )
(~fromlis (list (xtuple 10 0) (xtuple 1 1)) )

(symbol-function '~/.)

(~@c 3 2)
(\Xi (define bar
         X->(\A B->[A X B]))
     (define baz
         A B->((bar 0) B A))
     #)
(funcall (funcall (~bar 1) 3) 4)
(~baz 1 2)
         
'(\Xi #\Space #\Tab (\ (X) X)#)
'~a
A:B. A:mytype.
(/ (* 300000 1000 100) (* 1000 1000 1000 1000.0))


[A'B] -> 

(characterp #\')
(quote (\Xi a'a b `c .))
(quote (\Xi A:B'..:D E:=====: {[a b]} =# -# .# .))

(~difference (xtuple 1 2) (xtuple 1 3))

(~tuple? (xtuple 1 2))

'~tak
(~tak (ju 30))

(defun tes (x) (~ge x))

CLAP.QSPACE


(q::|ge| (jo 'a 3))
(tes (jo 'a 10))
(q::|ge| (ju 3))
(q::|idnt| 3)
(symbol-package 'q::|idnt|)
(== (ju 3) (ju 2))
(== 
