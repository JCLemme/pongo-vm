; Pongo pong v4
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; A helper function to hardcode coordinate pairs.
; FUCK needs runtime addition :(
(do-lisp (defun screen-xy (x y) (+ #x4000 (+ x (* y 32)))))

; Variables.
(at-origin #x0010)

(def-variable pong-ball-x)
(def-variable pong-ball-x-dir)
(def-variable pong-ball-x-timer)

(def-variable pong-ball-y)
(def-variable pong-ball-y-dir)
(def-variable pong-ball-y-timer)

(def-variable pong-ball-speed)
(def-variable pong-ball-angle)

(def-variable pong-left-pos)
(def-variable pong-left-score)

(def-variable pong-right-pos)
(def-variable pong-right-score)

; Constants.
; TODO: autoplacement for these - need to mind defconstant scope

; Crib tables for filling in score dots.
(at-origin #xF000)
;(constant-table coords-leftscore (list (screen-xy 1 1) (screen-xy 3 1) (screen-xy 5 1) (screen-xy 7 1) (screen-xy 9 1) (screen-xy 11 1)))
;(constant-table coords-rightscore (list (screen-xy 30 1) (screen-xy 28 1) (screen-xy 26 1) (screen-xy 24 1) (screen-xy 22 1) (screen-xy 20 1)))

; Regular constants for color values.
(do-lisp
  (defconstant color-white 15)
  (defconstant color-black 0)
  (defconstant color-left 107)
  (defconstant color-right 89)

  (defconstant left-top (screen-xy 1 3))
  (defconstant right-top (screen-xy 30 3))
)

; Static images. 
(read-source "splash.lisp")
(read-source "field.lisp")



; Game starts below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(at-origin #x8000)

; Display splash and wait for a click.
(memcpy emureg-vram (label "IMG_splash_data") 1024)
(wait-for-frame)
(call-routine (label "sub-wait"))

; Main game loop.
(loop-forever (
  
  ; Draw the field. 
  (memcpy emureg-vram (label "IMG_field_data") 1024)

  (move 5 (label "pong-left-score"))
  (move 2 (label "pong-right-score"))

  (move emureg-paddle-a (label "pong-left-pos"))
  ; A frankly pathetic (but faster) way of drawing the scores.
  ;(pause-emulation)
  (move #x00 reg-loophi)
  (move (as-type :ptr (label "pong-left-score")) reg-looplo)

  (if-else () ((move color-left (as-type :ptr (screen-xy 1 1))) (loop--)))
  (if-else () ((move color-left (as-type :ptr (screen-xy 3 1))) (loop--)))
  (if-else () ((move color-left (as-type :ptr (screen-xy 5 1))) (loop--)))
  (if-else () ((move color-left (as-type :ptr (screen-xy 7 1))) (loop--)))
  (if-else () ((move color-left (as-type :ptr (screen-xy 9 1))) (loop--)))
  (if-else () ((move color-left (as-type :ptr (screen-xy 11 1))) (loop--)))

  (move #x00 reg-loophi)
  (move (as-type :ptr (label "pong-right-score")) reg-looplo)

  (if-else () ((move color-right (as-type :ptr (screen-xy 30 1))) (loop--)))
  (if-else () ((move color-right (as-type :ptr (screen-xy 28 1))) (loop--)))
  (if-else () ((move color-right (as-type :ptr (screen-xy 26 1))) (loop--)))
  (if-else () ((move color-right (as-type :ptr (screen-xy 24 1))) (loop--)))
  (if-else () ((move color-right (as-type :ptr (screen-xy 22 1))) (loop--)))
  (if-else () ((move color-right (as-type :ptr (screen-xy 20 1))) (loop--)))

  ; Draw paddles.
  ;(pause-emulation)
  (move (ash left-top -8) reg-indihi)
  (move (logand left-top #xFF) reg-indilo)

  ; TODO: :( need auto-width for loop variables, auto-ptr for labels, proper for loop test order
  (move #x00 reg-loophi)
  (move (as-type :ptr (label "pong-left-pos")) reg-looplo)
  (jump-if (label "left-pushloop"))
  (jump-to (label "left-pushend"))
  (at-label "left-pushloop")
    (move reg-loop reg-tmpb)
    (loop-for 32 ( (indi++) ))
    (move reg-tmpb reg-loop)
    (loop--)
    (jump-if (label "left-pushloop"))
    (at-label "left-pushend")

  (loop-for 5 (
    (store-indirect color-white)
    (move reg-loop reg-tmpb)
    (loop-for 32 ( (indi++) ))
    (move reg-tmpb reg-loop)
  ))

  (wait-for-frame)
))




; Subroutine land below. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Waits for a button press.
(def-subroutine "sub-wait" ( 
  (loop-if (
    (move #x00 reg-loophi)
    (move emureg-buttons-a reg-looplo)
    (loop--)
  ))
))


