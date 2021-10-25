;; -*- coding: utf-8 -*-
;; This file is part of CL-JKit-plus.
;; Copyright (c) 2018-2021 tradcrafts tradcrafts

(jkit:define-package :jkit+ ()
  (:use :cl)
  (:nicknames :jk+)
  (:import-from :jkit #:full-mode)
  (:import/export :jkit.embed)

  (:export  #:lang-mode #:full-mode)

  )

(in-package :jkit+)

(defmacro lang-mode (&rest other-modes)
  `(jkit.base:jkit-base-header :embed :lpar :mspace ,@other-modes))







