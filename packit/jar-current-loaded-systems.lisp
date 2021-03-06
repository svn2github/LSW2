;0. load stuff
;1. (jar-current-loaded-systems "/Users/alanr/Desktop/jar2go/")
;2. (setq asdf::*defined-systems* (make-hash-table :test 'equal)) 
;3. (load-jarred-asds "/Users/alanr/Desktop/jar2go/*/")
;3'  (setq asdf::*central-registry* (mapcar (lambda(e) (make-pathname :directory e)) (mapcar 'pathname-directory (directory "/Users/alanr/Desktop/jar2go/*/*.asd"))))
;4. (compile-for-jar 'ido)

; (setq asdf::*defined-systems* (make-hash-table :test 'equal)) 
;5. (setq asdf::*central-registry* (mapcar (lambda(e) (make-pathname :directory e :device (pathname-device "jar:file:/Users/alanr/Desktop/jar2go.jar!/*/*.asd"))) (mapcar 'pathname-directory (directory "jar:file:/Users/alanr/Desktop/jar2go.jar!/*/*.asd"))))
;5. (load-from-jar 'ido "jar:file:/Users/alanr/Desktop/jar2go.jar!/")

(require 'asdf)

(defun jar-current-loaded-systems (destdir destjar topdir module-file)
  (ensure-directories-exist destdir)
  (setq topdir (cdr (pathname-directory topdir)))
  (flet ((trim-trailing-slash  (e)
	   (jcall "replaceFirst"  (namestring (truename e)) "(.*)/" "$1")))
    (maphash (lambda(k time.system)
	       (declare (ignorable k))
	       (let* ((source-asdf (slot-value (cdr time.system) 'asdf::source-file))
		      (where-is-binary (make-pathname
					:directory (pathname-directory (asdf::apply-output-translations source-asdf))))
		      (where-is-source (make-pathname :directory (pathname-directory source-asdf)))
		      (trimmed-sourcedir (make-pathname :directory `(:relative ,@(subseq (pathname-directory where-is-source)
											 (+ (search topdir (pathname-directory where-is-source) :test 'equalp)
											    (length topdir))))))
		      (asdf-dest (merge-pathnames (merge-pathnames trimmed-sourcedir destdir) source-asdf))
		      (trimmed-binary-dir 
		       (make-pathname :directory `(:absolute ,@(subseq (pathname-directory where-is-binary)
								       1
								       (1+ (+ (search topdir (pathname-directory where-is-binary) :test 'equalp)
									      (length topdir))))))
			)
		      (cp-asdf-cmd (format nil "rsync ~a ~a"
					   (namestring source-asdf)
					   (namestring asdf-dest)))
		      (cp-binary-cmd (and (probe-file trimmed-binary-dir)
					  (format nil "rsync -r ~a ~a"
						  (trim-trailing-slash trimmed-binary-dir)
						  (namestring destdir)))))
		 '(print-db topdir trimmed-sourcedir source-asdf asdf-dest trimmed-binary-dir
		   cp-asdf-cmd
		   cp-binary-cmd)
		 (ensure-directories-exist asdf-dest)
		 (and cp-binary-cmd
		      (print cp-binary-cmd)
		      (run-shell-command cp-binary-cmd))
		 (print cp-asdf-cmd)
		 (run-shell-command cp-asdf-cmd)))
	     asdf::*defined-systems*)

	
    (let ((jar-cmd
	   (if (probe-file (make-pathname :directory (pathname-directory (pathname destdir)) :name (pathname-name module-file) :type (pathname-type module-file)))
	       (format nil "cd ~a; jar cf ~a ." (namestring (truename destdir)) destjar)
	       (format nil "cd ~a; jar cf ~a . -C ~a ~a" (namestring (truename destdir)) destjar
			   (namestring (truename (make-pathname :directory (pathname-directory module-file))))
			   (make-pathname :name (pathname-name module-file) :type (pathname-type module-file))
			   ))))
      (print jar-cmd)
      (run-shell-command jar-cmd)
      )))

;(jar-current-loaded-systems "/Users/alanr/Desktop/jar2go/"  "/Users/alanr/Desktop/owltool.jar" "/Users/alanr/repos/" "/Users/alanr/lsw/owl2/abcl-module-owltool.lisp")

#|
(defun copy-current-loaded-systems (dest)
  (ensure-directories-exist dest)
  (flet ((trim-trailing-slash  (e)
	   (jcall "replaceFirst"  (namestring (truename e)) "(.*)/" "$1")))
    (maphash (lambda(k time.system)
	       (declare (ignorable k))
	       (let* ((source-asdf (slot-value (cdr time.system) 'asdf::source-file))
		      (where-is-binary (make-pathname
					:directory (pathname-directory (asdf::apply-output-translations source-asdf))))
		      (where-is-source (make-pathname :directory (pathname-directory source-asdf)))
		      (cp-binary-cmd (and (probe-file where-is-binary)
					  (format nil "cp -r ~a ~a"
						  (trim-trailing-slash  where-is-binary)
						  (namestring (truename dest)))))
		      (cp-src-cmd (and (probe-file where-is-source)
				       (format nil "rsync -r --exclude '*.svn/*' --exclude '*.abcl' --exclude '*treeml.xml' ~a ~a"
					       (trim-trailing-slash  where-is-source)
					       (namestring (truename dest))))))
		 (and cp-src-cmd (print cp-src-cmd))
		 (and cp-src-cmd (run-shell-command cp-src-cmd))
		 ))
	     asdf::*defined-systems*)))



(defun compile-for-jar (system)
  (let ((asdf::*output-translations* 
	 `(((t ,(lambda(path wha) 
		       (let* ((dir (pathname-directory path))
			      (new (append (subseq dir 0 5) (list "bin") (subseq dir 5))))
			 (print new)
			 (merge-pathnames (make-pathname :directory new) path))))))))
    (asdf::oos 'asdf::load-op system)))

(defun load-from-jar (system jarfile)
  (let ((*inhibit-add-to-classpath* t))
    (let ((asdf::*output-translations* 
	   `(((t ,(lambda(path wha) 
			 (let* ((dir (pathname-directory path))
				(new (append '(:absolute) (list "bin") (cdr dir))))
			   (print (list dir new))
			   (merge-pathnames (merge-pathnames (make-pathname :directory new)
							     (pathname jarfile)) path))))))))
      ;;(asdf::apply-output-translations "jar:file:/Users/alanr/Desktop/jar2go.jar!/xmls-1.2/xmls.lisp"))
      (asdf::oos 'asdf::load-op system))))

(defun load-jarred-asds (root)
  (let ((asds (directory (print (merge-pathnames "*.asd" root)))))
    (let ((*load-verbose* t))
      (loop for asd in asds do (load asd)))))
|#

#|
(setq jvm::*suppress-compiler-warnings* t)
(setq *load-verbose* nil)
(require 'asdf)
(setq *inhibit-add-to-classpath* t)
;(setq *load-verbose* t)

(setq *PELLET-DIR* "")

(loop for asd in 
     '("/lsw/ext-asdf/cl-xptest-1.2.3/xptest.asd"
       "/lsw/ext-asdf/xmls-1.2/xmls.asd"
       "/lsw/inspect/inspect.asd"
       "/lsw/patches/patches.asd"
       "/lsw/jss/jss.asd")
     do
     (load (merge-pathnames asd *abcl-jar*)))

(asdf::oos 'asdf::load-op 'asdf-binary-locations)
(asdf::oos 'asdf::load-op 'jss)
(asdf::oos 'asdf::load-op 'patches)

(loop for asd in 
     '("/lsw/obi/obi.asd"
       "/lsw/owl/owl.asd"
       "/lsw/read-ms-docs/read-ms-docs.asd"
       "/lsw/ido/ido.asd"
       "/lsw/util/util.asd"
       )
     do
     (load (merge-pathnames asd *abcl-jar*)))

(asdf::oos 'asdf::load-op 'ido)

(when (equal (car *command-line-argument-list*) "-check")
    (check-pathway-spreadsheet-syntax :path (second *command-line-argument-list*))
    (quit))


(let ((asdf::*output-translations* 
		`(((t ,(lambda(path wha) 
			      (let* ((dir (pathname-directory path))
				     (new (append (butlast dir) (list "bin") (last dir))))
				(merge-pathnames (make-pathname :directory new) path))))))))
	   (asdf::oos 'asdf::load-op 'fma2))


(defun load-from-jar (system jarfile)
  (let ((*inhibit-add-to-classpath* t))
    (let ((asdf::*output-translations* 
	   `(((t ,(lambda(path wha) 
			 (let* ((dir (pathname-directory path))
				(new (append '(:absolute) (list "bin") (cdr dir))))
			   (merge-pathnames (merge-pathnames (make-pathname :directory new)
							     (pathname jarfile)) path))))))))
      (asdf::oos 'asdf::load-op system))))
(defun load-from-jar (system jarfile)
  (let ((*inhibit-add-to-classpath* t))
    (let ((asdf::*output-translations* 
	   `(((t ,(lambda(path wha) 
			 (let* ((dir (pathname-directory path))
				(new (append '(:absolute) (list "bin") (cdr dir))))
			   (merge-pathnames (merge-pathnames (pathname jarfile)) path))))))))
      (asdf::oos 'asdf::load-op system))))

|#