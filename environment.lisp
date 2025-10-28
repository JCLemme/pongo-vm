
(defun number-to-chunks (num)
  (let* ((fat (logand num #xFFFF))           
         (out0 (logand (ash fat -12) #xF))    
         (out1 (logand (ash fat -6) #x3F))    
         (out2 (logand fat #x3F))           
         (is-negative (not (zerop (logand fat #x8000)))))

    (if is-negative
        (cond
          ((and (= out0 #xF) (= out1 #x3F) (not (zerop (logand out2 #x20))))
           (list out2))

          ((and (= out0 #xF) (= out1 #x3F) (zerop (logand out2 #x20)))
           (list #x3F out2))

          ((and (= out0 #xF) (not (zerop (logand out1 #x20))))
           (list out1 out2))

          (t (list out1 out0 out2)))

      (cond
        ((and (= out0 #x0) (= out1 #x00) (zerop (logand out2 #x20)))
         (list out2))

        ((and (= out0 #x0) (= out1 #x00) (not (zerop (logand out2 #x20))))
         (list 0 out2))

        ((and (= out0 #x0) (zerop (logand out1 #x20)))
         (list out1 out2))

        (t (list out1 out0 out2))))))

; Opcodes.
(defconstant opcode-a*>d #b00 "Move value in address a to d")
(defconstant opcode-a>d  #b01 "Move literal a to d")
(defconstant opcode-d>a* #b10 "Move d to address a")
(defconstant opcode-push #b11 "Push literal chunk to a")

; Objects need type information. These functions provide it.
; Types are :val (value), :ptr (pointer), :wid (wide pointer), :ind (indirect)
(defun no-type (val) (if (listp val) (car val) val))
(defun as-type (typ val) (list (no-type val) typ))
(defun extract-type (val) (if (listp val) (car (cdr val)) :val))
(defun is-type (typ val) (eq typ (extract-type val)))

; Stick a single raw instruction together.
(defun assemble-one-raw-instruction (opcode data)
  (logand #xFF (logior (ash (logand opcode #x3) 6) (logand data #x3F))))

; Stick several raw instructions together, autopushing values as necessary.
(defun build-raw-instructions (opcode data)
  (append
    (when (> (length data) 1) 
      ; Push high chunks first.
      (mapcar (lambda (d) (assemble-one-raw-instruction opcode-push d)) (reverse (cdr (reverse data))))
    )
    (list (assemble-one-raw-instruction opcode (car (last data))))
  )
)

; Primitive instruction types, including "push" for the deranged.
(defun a*>d (addr) (build-raw-instructions opcode-a*>d (number-to-chunks (no-type addr))))
(defun a>d (val) (build-raw-instructions opcode-a>d (number-to-chunks (no-type val))))
(defun d>a* (addr) (build-raw-instructions opcode-d>a* (number-to-chunks (no-type addr))))
(defun push-a (val) (assemble-one-raw-instruction opcode-push (no-type val)))

; Pseudoprimitives. Not instructions but similarly terminal nodes of the program.
(defun raw-data (val) (if (listp val) val (list val)))
(defun at-origin (val) nil)
(defun at-label (val) nil)

; And how to check for them.
(defun is-primitive (stm) (if (listp stm) (member (car stm) '(a*>d a>d d>a* push-a raw-data at-origin at-label)) nil))

; A special kind of primitive: the input sexp will execute during decomposition, but won't be included
; in the primitive list. Useful for defining constants, macros, etc.
(defun do-lisp (&rest v) nil)

; Flatten any node of a tree into primitives.
(defun decompose (stm) 
  ; Any decomposable function will come in as a (populated) list, so ignore nil and atoms.
  (if (and (not (eq stm nil)) (listp stm))
    (apply #'append (mapcar (lambda (substm) 
      (cond 
        ((is-primitive substm) (list substm))
        ((macro-function (car substm)) (decompose (macroexpand substm)))
        (t (decompose (eval substm)))
    )) stm))
    nil
  )
)


; Utility function to generate a unique string.
(defvar *unique-calls* 0)
(defun unique-id (prefix) (prog1 (concatenate 'string prefix (write-to-string *unique-calls*)) (setf *unique-calls* (+ *unique-calls* 1))))

; Machineland below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defconstant reg-iplo (as-type :ptr #x0) "Instruction pointer, low byte")
(defconstant reg-iphi (as-type :ptr #x1) "Instruction pointer, high byte")
(defconstant reg-looplo (as-type :ptr #x2) "Loop register, low byte")
(defconstant reg-loophi (as-type :ptr #x3) "Loop register, high byte")
(defconstant reg-indilo (as-type :ptr #x4) "Indirect register, low byte")
(defconstant reg-indihi (as-type :ptr #x5) "Indirect register, high byte")
(defconstant reg-nand (as-type :ptr #x6) "Bitwise NAND of IndiLo and IndiHi")
(defconstant reg-flow (as-type :ptr #x7) "Processor control flow bits")

(defconstant flow-sixteen-wide #x01 "")
(defconstant flow-inhibit-if-zero #x02 "")
(defconstant flow-loop-down #x04 "")
(defconstant flow-indirect-up #x08 "")
(defconstant flow-store-indirect #x10 "")
(defconstant flow-load-indirect #x20 "")
(defconstant flow-indirect-down #x40 "")
(defconstant flow-unused #x80 "")

(defconstant emureg-vram #x4000 "")
(defconstant emureg-paddle-a (as-type :ptr #x4400) "")
(defconstant emureg-buttons-a (as-type :ptr #x4401) "")
(defconstant emureg-paddle-b (as-type :ptr #x4402) "")
(defconstant emureg-buttons-b (as-type :ptr #x4403) "")
(defconstant emureg-random (as-type :ptr #x4404) "")
(defconstant emureg-flow (as-type :ptr #x4407) "")

(defconstant emuflow-wait-frame #x01 "")
(defconstant emuflow-pause #x80 "")

; Special registers. They carry some type information.
(defconstant reg-ip (as-type :wid reg-iplo))
(defconstant reg-loop (as-type :wid reg-looplo))
(defconstant reg-indi (as-type :wid reg-indilo))
(defconstant reg-opa (as-type :ptr #x8))
(defconstant reg-opb (as-type :ptr #x9))
(defconstant reg-add (as-type :ptr #xa))
(defconstant reg-tmpa (as-type :ptr #xb))
(defconstant reg-tmpb (as-type :ptr #xc))
(defconstant reg-tmpc (as-type :ptr #xd))
(defconstant reg-tmpd (as-type :ptr #xe))
(defconstant reg-tmpe (as-type :ptr #xf))

; Macroland below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Set flags.
(defmacro do-flow (mask) `((a>d ,mask) (d>a* ,(no-type reg-flow)))) ; a small lol here concering type constants
(defmacro do-emuflow (mask) `((a>d ,mask) (d>a* ,(no-type emureg-flow)))) ; a small lol here concering type constants

; Semi-primitive move operation.
(defmacro do-move (flags left right)
  ; Might need to set flags.
  (let* ((cflags flags)
         (exp-left (eval left))
         (exp-right (eval right)) ; A note: we need to predict the future and see what type the left is, so we can set appropriate flags.
                                  ; This naturally fails if the result of the expression at decomposition time is gibberish, but usually
                                  ; it's close enough (right type, wrong value).
                                  ; That said, it's still a macro because the returned primitive needs the correct value at assembly time,
                                  ; which means it needs the original expression.
         (cflags (if (is-type :ind exp-left) (logior cflags flow-load-indirect) cflags))
         (cflags (if (is-type :ind exp-right) (logior cflags flow-store-indirect) cflags))
         (cflags (if (is-type :wid exp-left) (logior cflags flow-sixteen-wide) cflags))
         (cflags (if (is-type :wid exp-right) (logior cflags flow-sixteen-wide) cflags)))

    ; Anatomy of a move: set flags, move into D, then move out of D.
    `(,(if (not (eq cflags 0)) `(do-flow ,cflags))
      (,(if (or (is-type :ptr exp-left) (is-type :wid exp-left) (is-type :ind exp-left)) 'a*>d 'a>d) ,left)
      (d>a* ,right)
      )
  )
)

; Basic "move number" instructions, conditional or not.
(defmacro move (left right) `(do-move 0 ,left ,right))
(defmacro move-if (left right) `(do-move ,flow-inhibit-if-zero ,left ,right))

; Jumping.
(defmacro jump-to (addr) `(move ,addr reg-ip))
(defmacro jump-if (addr) `(move-if ,addr reg-ip))

; Looping.
(defmacro loop-forever (body)
  (let* ((begl (unique-id "lfv-beg")) (endl (unique-id "lfv-end")))
    `( (at-label ,begl) ,@body (jump-to (label ,begl)) (at-label ,endl))
  )
)

(defmacro loop-for (len body)
  (let* ((begl (unique-id "lfr-beg")) (endl (unique-id "lfr-end")))
    `( (move ,len reg-loop) (at-label ,begl) ,@body (do-flow flow-loop-down) (jump-if (label ,begl)) (at-label ,endl))
  )
)

(defmacro loop-if (body)
  (let* ((begl (unique-id "lfv-beg")) (endl (unique-id "lfv-end")))
    `( (move #x0000 reg-loop) (at-label ,begl) ,@body (jump-if (label ,begl)) (at-label ,endl))
  )
)

; Conditionals.
; Note: the "yes" case triggers when loop is zero, which usually means "truthy"
(defmacro if-else (yes no)
  (let* ((elsel (unique-id "ife-els")) (endl (unique-id "ife-end")))
    `( (jump-if (label ,elsel)) ,@yes (jump-to (label ,endl)) (at-label ,elsel) ,@no (at-label ,endl) )
  )
)

; More convenient indirect addressing.
(defmacro store-indirect (left)
  `(move ,left (as-type :ind reg-indilo)))

(defmacro load-indirect (right)
  `(move (as-type :ind reg-indilo) ,right))

; More convenient register math.
; TODO: should be constants?
(defmacro indi++ () `(do-flow flow-indirect-up))
(defmacro indi-- () `(do-flow flow-indirect-down))
(defmacro loop-- () `(do-flow flow-loop-down))

; Utility macros that use loops.
(defmacro memset (addr len val)
  `( (move ,addr reg-indi) 
     (loop-for ,len (
       (store-indirect ,val) 
       (indi++)
     )) 
   )
)

; TODO: names are backwards dummy
(defmacro memcpy (src dest len)
  `( (move ,src (as-type :wid reg-tmpb))
     (move ,dest (as-type :wid reg-tmpd))
     (loop-for ,len (
        (move (as-type :wid reg-tmpd) reg-indi)
        (load-indirect reg-tmpa)
        (indi++)
        (move reg-indi (as-type :wid reg-tmpd))

        (move (as-type :wid reg-tmpb) reg-indi)
        (store-indirect reg-tmpa)
        (indi++)
        (move reg-indi (as-type :wid reg-tmpb))
     ))
   )
)


(defmacro do-add ()
  `((move reg-opa reg-indilo)
    (loop-for reg-opb (
      (indi++)
    ))
    (move reg-indilo reg-add)
   )
)

(defmacro halt () `(loop-forever ()))

; Subroutine calls.
; TODO: maybe same symbol-name trick as with variables
(defmacro call-routine (addr)
  (let ((retl (unique-id "cll-ret")))
    `( (move (label ,retl) (as-type :wid reg-tmpd)) (jump-to ,addr) (at-label ,retl) )
  )
)

(defmacro return-call ()
  `(jump-to (as-type :wid reg-tmpd)))

(defmacro def-subroutine (name body)
  `( (at-label ,name) ,@body (return-call) ))

; Autospaced variables.
; TODO: auto-align, wide pointer result for words
(defmacro def-variable (name &optional (size 1))
  `( (at-label ,(symbol-name name)) 
     (raw-data (make-list ,size :initial-element 0))
     (do-lisp (defconstant ,name (label ,(symbol-name name))))
   )
)

(defmacro constant-table (name data)
  `( (at-label ,(symbol-name name))
     (raw-data ,data)
     (do-lisp (defconstant ,name (label ,(symbol-name name))))
  )
)

; Emulator hardware functions.
(defmacro wait-for-frame () `(do-emuflow emuflow-wait-frame))
(defmacro pause-emulation () `(do-emuflow emuflow-pause))

; Assemblerland below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defparameter *label-mapping* (make-hash-table :test 'equalp))  ; this test func is a case-insensitive string comparison

(defun label (key) (gethash key *label-mapping*))
(defun label-set (key val) (setf (gethash key *label-mapping*) val))

; Label pass: run through a program and determine the width of all labels present.
(defun label-pass (statements)
  (let* ((current-origin 0))
    (mapcar (lambda (stm)
      ; Fill the label with a convincing dummy value.
      (cond 
        ((eq 'at-label (car stm)) (label-set (car (cdr stm)) #xeaea))
        ((eq 'at-origin (car stm)) (setq current-origin (car (cdr stm))))
      )
    )
    statements)
  )
)

; Spacing pass: eval statements to figure out where the labels should go
(defun spacing-pass (statements)
  (let* ((current-origin 0))
    (mapcar (lambda (stm)
      (cond
        ((eq 'at-label (car stm)) (label-set (car (cdr stm)) current-origin))
        ((eq 'at-origin (car stm)) (setq current-origin (car (cdr stm))))
        (t (setq current-origin (+ current-origin (length (eval stm)))))
      )
    )
    statements)
  )
)

(defvar *out-bin* (make-array 65536))

; Binary pass: eval statements to produce a binary.
(defun binary-pass (statements)
  (let* ((current-origin 0))
    (mapcar (lambda (stm)
      (cond
        ((eq 'at-label (car stm)) nil)
        ((eq 'at-origin (car stm)) (setq current-origin (car (cdr stm))))
        (t (mapcar (lambda (bins) 
            (progn
              (setf (aref *out-bin* current-origin) bins)
              (setq current-origin (+ current-origin 1))
            )
          ) (eval stm)))
      )
    )
    statements)
  )
)

; Load a file of sexps.
(defun read-source (filename)
  (with-open-file (stream filename) (loop for sexp = (read stream nil nil) while sexp collect sexp)))

; Put that binary in a file.
(defun write-binary (src-array filename)
  (with-open-file (stream filename :direction :output :element-type 'unsigned-byte :if-exists :supersede) (write-sequence src-array stream))
)

; I attempted to convert "labels" to use local variables here, but it caused more problems than it solved.
; Seems related to scoping within read-source, since it'd choke on labels defined in included files.
; Not a big deal to pollute the global namespace - we're either loading it into SBCL (so nothing happens
; by default), or running it as a script (which exits after a single pass).
; TODO: consider fixing
(defun assemble (filein fileout)
  (let* ((code (read-source filein))
         (dec-code (decompose code)))
    (progn
      (label-pass dec-code)
      (spacing-pass dec-code)
      (binary-pass dec-code)
      (write-binary *out-bin* fileout)
    )
  )
)



