; Source code...
(at-origin #x0030)
(raw-data '(33))
(def-variable pongo-x)
(def-variable pongo-y 2)

(at-origin #x8000)

; Display splash screen...
(memcpy emureg-vram (label "IMG_splash_data") 1024)
(wait-for-frame)

; ...and wait for button press.
(call-routine (label "sub-wait"))

(memcpy emureg-vram (label "IMG_field_data") 1024)
(wait-for-frame)

;(do-emuflow #x80)
(halt)

(at-origin #x9000)

(def-subroutine "sub-wait" ( 
  (loop-if (
    (move #x00 reg-loophi)
    (move emureg-buttons-a reg-looplo)
    (loop--)
  ))
))

(at-origin #xA000)
(read-source "splash.lisp")
(read-source "field.lisp")
