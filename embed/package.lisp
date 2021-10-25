;; -*- coding: utf-8 -*-
;; This file is part of JKIT.
;; Copyright (c) 2018-2021 tradcrafts tradcrafts

(jkit:define-package :jkit.embed ()
  (:use :cl :jkit.base :jkit.prolog :jkit.embed.core)
  
  (:export
    ;; #:TUPLE #:TUPLE-P #:MAKE-TUPLE #:TUPLE-FST #:TUPLE-SND
   ))

(jkit:define-package :jkit.embed.test ()
  (:use :cl :jkit.base :jkit.algebraic :jkit.embed))
  

(jkit:define-package :jkit.embed.devel ()
  (:use :cl :jkit.base :jkit.algebraic :jkit.embed))

