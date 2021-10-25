;; -*- coding: utf-8 -*-
;; This file is part of CL-JKit-plus.
;; Copyright (c) 2018-2021 tradcrafts

(asdf:defsystem :jkit+
    :version "0.9"
    :description "CL-JKit-plus: CL-JKit with Qi-based embedded functional language imprementation."
    :author "tradcrafts"
    :depends-on (:jkit :jkit.embed)
    :license "Qi"
    :serial t
    :components ((:file "package")))

