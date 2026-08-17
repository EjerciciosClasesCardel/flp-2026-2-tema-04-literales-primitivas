#lang eopl

;; Tema 4 — El TAD de ambientes
;; Fundamentos de Interpretación y Compilación de Lenguajes de Programación
;; Universidad del Valle, sede Tuluá
;;
;; Este archivo ya viene resuelto. No hay nada que escribir aquí.
;;
;; Es el mismo TAD del tema 2 con la representación de listas, más el ambiente
;; inicial que usa EOPL en la sección 3.2 para tener algunas variables ligadas
;; sin necesidad de escribir un `let` en cada ejemplo.

(provide empty-env extend-env apply-env init-env)

;; ---------------------------------------------------------------------------
;; La interfaz (EOPL, sección 2.2)
;;
;;   empty-env  : ()                  -> Env
;;   extend-env : Var × ExpVal × Env  -> Env
;;   apply-env  : Env × Var           -> ExpVal
;;
;; El ambiente liga variables a valores denotados. En este lenguaje el valor
;; denotado y el valor expresado son la misma cosa: un número o un booleano.
;; Eso deja de ser cierto en cuanto aparezcan los procedimientos y las
;; referencias, más adelante en el curso.

;; empty-env : () -> Env
(define empty-env
  (lambda ()
    '()))

;; extend-env : Var × ExpVal × Env -> Env
;; Construye un ambiente nuevo con la ligadura de `var` a `val` encima del
;; ambiente recibido, que no se modifica.
(define extend-env
  (lambda (var val env)
    (cons (list var val) env)))

;; apply-env : Env × Var -> ExpVal
;; Recorre la cadena de ligaduras de la más reciente a la más antigua y
;; devuelve el primer valor que encuentre para `var`.
(define apply-env
  (lambda (env var)
    (cond
      ((null? env)
       (eopl:error 'apply-env "variable no ligada: ~s" var))
      ((eqv? (car (car env)) var)
       (cadr (car env)))
      (else
       (apply-env (cdr env) var)))))

;; ---------------------------------------------------------------------------
;; init-env : () -> Env
;; El ambiente inicial de la sección 3.2, con i = 1, v = 5, x = 10. Las pruebas
;; evalúan todo contra este ambiente, así que en los ejemplos puede usar esas
;; tres variables sin ligarlas.
(define init-env
  (lambda ()
    (extend-env 'i 1
                (extend-env 'v 5
                            (extend-env 'x 10
                                        (empty-env))))))
