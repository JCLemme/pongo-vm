; Source code...
(at-origin #x0030)
(raw-data '(33))

(at-origin #x8000)

; Display splash screen...
(memcpy emureg-vram (label "IMG_splash_data") 1024)
(wait-for-frame)

; ...and wait for button press.
(loop-if '(
  (move #x00 reg-loophi)
  (move emureg-buttons-a reg-looplo)
  (loop--)
))


(memset emureg-vram 1024 #xEE)
(wait-for-frame)

(do-emuflow #x80)
(halt)

(at-origin #x9000)
(read-source "splash.lisp")
