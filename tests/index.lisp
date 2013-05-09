;;; -*- Mode: Lisp; Syntax: COMMON-LISP; Base: 10 -*-

;; cl-git an Common Lisp interface to git repositories.
;; Copyright (C) 2011-2013 Russell Sim <russell.sim@gmail.com>
;;
;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

(in-package #:cl-git-tests)

(in-suite :cl-git)

(def-fixture index-with-file (filename filetext)
  (with-test-repository ()
    (let ((filename (if (functionp filename)
                        (funcall filename)
                        filename)))
      (with-repository-index
        (write-string-to-file filename filetext)
        (&body)))))


(defun plist-equal (a b)
  "Compare an plist, if the plist contains a function then use that as
  a predicate."
  (loop :for (key value) :on b :by #'cddr
        :if (functionp value)
          :do (is (funcall value (getf a key)))
        :else
          :do (is (equal (getf a key) value))))

(defun approximately-now-p (a)
  (< (timestamp-difference a (now)) 5))

(defun index-path-test (filename filetext)
  (git-add filename)
  (git-write *git-repository-index*)
  (mapcar #'plist-equal
          (git-entries *git-repository-index*)
          `((:C-TIME ,#'approximately-now-p
             :M-TIME ,#'approximately-now-p
             :FILE-SIZE ,(length filetext)
             :OID 475587057170892494251873940086020553338329808131
             :FLAGS ,(length (namestring filename))
             :FLAGS-EXTENDED 0
             :PATH ,(namestring filename))))  )

(def-test index-add-pathname (:fixture (index-with-file #P"test-file" "foo blah."))
  (index-path-test filename filetext))


(def-test index-add-string (:fixture (index-with-file "test-file" "foo blah."))
  (index-path-test filename filetext))

(def-test index-add-abspathname (:fixture (index-with-file
                                           (lambda ()
                                             (merge-pathnames (make-pathname :name "test-file")
                                                              *repository-path*))
                                           "foo blah."))
  (let ((filename (enough-namestring filename *repository-path*)))
    (index-path-test filename filetext)))

(def-test index-has-conflicts (:fixture repository)
  (let ((filename "test-file"))
    (with-index (index *git-repository*)
      (write-string-to-file filename "foo")
      (git-add filename :index index)
      (is (eq (git-index-has-conflicts index)
              nil)))))
