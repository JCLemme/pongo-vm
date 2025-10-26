
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

; We want label types to bind late.
; TODO: remove hack here, probably by making :lbl a type of its own
(defun number-or-call (val) (if (and (listp val) (eq (car val) 'label)) `(no-type ,val) (no-type val)))

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
(defun a*>d (addr) (build-raw-instructions opcode-a*>d (number-to-chunks addr)))
(defun a>d (val) (build-raw-instructions opcode-a>d (number-to-chunks val)))
(defun d>a* (addr) (build-raw-instructions opcode-d>a* (number-to-chunks addr)))
(defun push-a (val) (assemble-one-raw-instruction opcode-push val))

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
      (if (is-primitive substm) (list substm) (decompose (eval substm)))
    ) stm))
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
(defun do-flow (mask) `((a>d ,mask) (d>a* ,(no-type reg-flow)))) ; a small lol here concering type constants
(defun do-emuflow (mask) `((a>d ,mask) (d>a* ,(no-type emureg-flow)))) ; a small lol here concering type constants

; Semi-primitive move operation.
; It's a macro so that we can pass evaluatable statements down for it to use later.
; TODO: there might be some elegance in ignoring the quine, or rather making pointer types degrade as quines too
; like quoting the number?
; idk i can just feel it in bones
(defmacro do-move (flags left right)
  ; Might need to set flags.
  (let* ((cflags flags)
         (cflags (if (is-type :ind left) (logior cflags flow-load-indirect) cflags))
         (cflags (if (is-type :ind right) (logior cflags flow-store-indirect) cflags))
         (cflags (if (is-type :wid left) (logior cflags flow-sixteen-wide) cflags))
         (cflags (if (is-type :wid right) (logior cflags flow-sixteen-wide) cflags)))
    ; Anatomy of a move: set flags, move into D, then move out of D.
    `(,@(if (not (eq cflags 0)) (do-flow cflags))
      (,(if (or (is-type :ptr left) (is-type :wid left) (is-type :ind left)) 'a*>d 'a>d) ,(number-or-call left))
      (d>a* ,(number-or-call right))
      )
  )
)

; Basic "move number" instructions, conditional or not.
(defun move (left right) (macroexpand `(do-move 0 ,left ,right)))
(defun move-if (left right) (macroexpand `(do-move ,flow-inhibit-if-zero ,left ,right)))

; Jumping.
(defun jump-to (addr) (move addr (as-type :wid reg-ip)))
(defun jump-if (addr) (move-if addr (as-type :wid reg-ip)))

; Looping.
(defun loop-forever (body)
  (let* ((begl (unique-id "lfv-beg")) (endl (unique-id "lfv-end")))
    `( (at-label ,begl) ,@body (jump-to (label ,begl)) (at-label ,endl))
  )
)

(defun loop-for (len body)
  (let* ((begl (unique-id "lfr-beg")) (endl (unique-id "lfr-end")))
    `( (move ,len reg-loop) (at-label ,begl) ,@body (do-flow flow-loop-down) (jump-if (label ,begl)) (at-label ,endl))
  )
)

(defun loop-if (body)
  (let* ((begl (unique-id "lfv-beg")) (endl (unique-id "lfv-end")))
    `( (move #x0000 reg-loop) (at-label ,begl) ,@body (jump-if (label ,begl)) (at-label ,endl))
  )
)

; More convenient indirect addressing.
(defun store-indirect (left)
  (move left (as-type :ind reg-indilo)))

(defun load-indirect (right)
  (move (as-type :ind reg-indilo) right))

; More convenient register math.
; TODO: should be constants?
(defun indi++ () (do-flow flow-indirect-up))
(defun indi-- () (do-flow flow-indirect-down))
(defun loop-- () (do-flow flow-loop-down))

; Utility macros that use loops.
(defun memset (addr len val)
  `( (move ,addr reg-indi) 
     (loop-for ,len '(
       (store-indirect ,val) 
       (indi++)
     )) 
   )
)

(defun memcpy (src dest len)
  `( (move ,src (as-type :wid reg-tmpb))
     (move ,dest (as-type :wid reg-tmpd))
     (loop-for ,len '(
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


(defun do-add ()
  `((move reg-opa reg-indilo)
    (loop-for reg-opb '(
      (indi++)
    ))
    (move reg-indilo reg-add)
   )
)

(defun halt () (loop-forever '()))

; Emulator hardware functions.
(defun wait-for-frame () (do-emuflow emuflow-wait-frame))

; Assemblerland below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(defparameter *label-mapping* (make-hash-table :test 'equalp))  ; this test func is a case-insensitive string comparison

(defun label (key) `(label ,key))
;(defun label (key) (gethash key *label-mapping*))
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

(defun assemble (filein fileout)
  (let* ((code (read-source filein))
         (dec-code (decompose code)))
    (progn
      (label-pass dec-code)
      (defun label (key) (gethash key *label-mapping*)) 
      (spacing-pass dec-code)
      (binary-pass dec-code)
      (write-binary *out-bin* fileout)
    )
  )
)



(eval-when (:execute) (assemble (car (uiop:command-line-arguments)) (car (cdr (uiop:command-line-arguments)))))
