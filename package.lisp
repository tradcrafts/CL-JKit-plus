;; -*- coding: utf-8 -*-
;; This file is part of CL-JKit+.
;; Copyright (c) 2019-2021 tradcrafts tradcrafts

(jkit:define-package :jkit+ ()
  (:use :cl)
  (:nicknames :jk+)
;  (:import/export :jkit.base :jkit.algebraic.core :jkit.embed :jkit.prolog)
;  (:import/export :jkit :jkit.embed)
  (:import-from :jkit #:full-mode)
  (:import/export :jkit.embed)

  (:export  #:lang-mode #:full-mode)
;  (:unexport   #:jkit-base-header)

  )

(in-package :jkit+)

(defmacro lang-mode (&rest other-modes)
  `(jkit.base:jkit-base-header :embed :lpar :mspace ,@other-modes))







