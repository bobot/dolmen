(set-logic QF_UF)
(declare-sort foo 0)
(declare-fun p (foo) Bool)
(assert (forall ((x foo)) (p x)))
(check-sat)
