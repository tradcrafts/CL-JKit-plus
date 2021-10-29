<!--dd -*- coding: utf-8 -*- -->  
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
