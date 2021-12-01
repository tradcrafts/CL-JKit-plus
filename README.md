<!--dd -*- coding: utf-8 -*- -->  

CLPGKから実験的に分割移譲されたものです。 本リポジトリは凍結し、今後の開発は https://github.com/lisp3dev/lisp3adv/ で行います。

# CL-JKit-plus

SBCL. CCL, CMUCL

-- **roswell** --

$ ros install tradcrafts/cl-jkit

$ ros install tradcrafts/cl-jkit-plus

-- **git** --

$ cd quicklisp/local-projects

$ git clone https://github.com/tradcrafts/cl-jkit

$ git clone https://github.com/tradcrafts/cl-jkit-plus

CL> (ql:register-local-projects)


-- **load** --

CL> (ql:quickload :jkit+)
