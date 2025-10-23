
(defmacro do-addition (ta tb res) (append
  (move-to ta reg-indilo)
  (loop-for tb 
    (do-flow flow-indirect-up)
  )
  (move-to reg-indilo res)
))


(at-origin #x8000

  (do-addition 22 49 reg-add)

  (loop-forever (
    (literal-to #x4000 reg-indi)

    (loop-for (* 32 32)
      (store-indirect hw-random)
      (pulse-flow indirect-up)
    )

    (pulse-hw-flow wait-for-frame)

    (loop-break)
  ))
  
  (literal-to #x4000 reg-indi)

  (loop-forever (
    (store-indirect hw-random)
    (pulse-hw-flow wait-for-frame)
  ))
)

