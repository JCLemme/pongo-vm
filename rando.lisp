; Source code...
(at-origin #x0010)
(at-label "Datums")
(raw-data '(11 22 33 44 55))

(do-lisp
  (print "hello") (print "world")
)

(at-origin #x8000)
(loop-forever '(
    (move 16384 reg-indi)

    (loop-for 1024 '(
        (store-indirect (as-type :ptr 17410))
        (move (as-type :ptr 17410) (as-type :ind reg-indilo))
        (indi++)
    ))

    (do-flow flow-unused)
))

(at-origin #x9000)
(at-label "ImageData")
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #xEC #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #xEC #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEC #x00 #x00))
(raw-data '(#x00 #x00 #xEC #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEC #x00 #x00))
(raw-data '(#x00 #x00 #xEC #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEC #x00 #x00))
(raw-data '(#x00 #x00 #xEC #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEC #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEC #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #x0F #x0F #xEB #x0F #x0F #x0F #xEB #x0F #xEB #x0F #xEB #x0F #x0F #x0F #xEB #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #xEB #x00 #xEB #xEB #xEB #x00 #xEB #x00 #xEB #x00 #xEB #xEB #xEB #x0F #xEB #xEB #xEB #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEB #xEB #xEB #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #xEB #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #x0F #x0F #xEB #x0F #x0F #x0F #xEB #x0F #xEB #x0F #xEB #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #xEB #x00 #xEB #xEB #xEB #x00 #xEB #x00 #xEB #x00 #xEB #xEB #xEB #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x0F #x0F #x0F #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #xEB #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xEB #xEB #xEB #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))
(raw-data '(#x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))


