#lang eopl

;; Tema 4 — Intérprete del lenguaje LET
;; Fundamentos de Interpretación y Compilación de Lenguajes de Programación
;; Universidad del Valle, sede Tuluá
;;
;; Aquí van los cuatro puntos. No modifique la carpeta pruebas/ ni los otros
;; dos archivos de src/, que ya vienen resueltos.

(require "ambiente.rkt"
         "sintaxis.rkt")

(provide expval->num expval->bool value-of)

;; ---------------------------------------------------------------------------
;; Valores expresados (EOPL, sección 3.2)
;;
;; El valor expresado es lo que devuelve la evaluación de una expresión. En
;; este lenguaje hay dos:
;;
;;   ExpVal = Int + Bool
;;
;; y se representan con los números y los booleanos de Scheme directamente.
;; Los extractores son la puerta por la que pasa cualquier operación que
;; necesite un valor de un tipo concreto: `diff-exp` necesita dos números,
;; `if-exp` necesita un booleano. Si el valor no es del tipo que se pidió, el
;; programa está mal y hay que decirlo con un error, no seguir calculando.

;; ---------------------------------------------------------------------------
;; Punto 1: los extractores

;; expval->num : ExpVal -> Int
;; El número que hay dentro del valor expresado. Si el valor no es un número,
;; se lanza un error con eopl:error diciendo qué se recibió.
(define expval->num
  (lambda (val)
    (eopl:error 'expval->num "sin-implementar")))

;; expval->bool : ExpVal -> Bool
;; El booleano que hay dentro del valor expresado, con la misma regla: si no es
;; un booleano, error con eopl:error.
(define expval->bool
  (lambda (val)
    (eopl:error 'expval->bool "sin-implementar")))

;; ---------------------------------------------------------------------------
;; Puntos 2, 3 y 4: la función de evaluación
;;
;; value-of : Expresion × Env -> ExpVal
;;
;; El esqueleto con `cases` ya está puesto y se deja así: la sintaxis abstracta
;; se analiza por variantes, nunca con car, cdr o cond sobre la estructura.
;; Cada rama corresponde a una regla de la sección 3.2 y lo único que falta es
;; su cuerpo.
;;
;;   Punto 2:  const-exp, var-exp
;;   Punto 3:  diff-exp, zero?-exp
;;   Punto 4:  if-exp, let-exp
;;
;; Las reglas, en el orden en que hay que resolverlas:
;;
;;   (value-of (const-exp n) ρ) = n
;;
;;   (value-of (var-exp var) ρ) = (apply-env ρ var)
;;
;;   (value-of (diff-exp e1 e2) ρ) = la resta de los números que hay en los
;;       valores de e1 y e2. Los números salen de expval->num, que es donde se
;;       cae si alguna de las dos subexpresiones devolvió un booleano.
;;
;;   (value-of (zero?-exp e1) ρ) = #t si el valor de e1 es cero, #f si no.
;;
;;   (value-of (if-exp e1 e2 e3) ρ) = (value-of e2 ρ) si e1 vale #t,
;;                                    (value-of e3 ρ) si e1 vale #f.
;;       Vea abajo la regla del curso sobre esta rama.
;;
;;   (value-of (let-exp var e1 body) ρ)
;;       = (value-of body (extend-env var (value-of e1 ρ) ρ))
;;
;; Regla del curso para if-exp, y las pruebas la revisan:
;;
;;   1. evalúe la expresión de prueba con value-of;
;;   2. compruebe con boolean? que el resultado es un booleano, sea llamando a
;;      boolean? o pasando el valor por expval->bool, que es esa misma
;;      comprobación;
;;   3. si no lo es, lance eopl:error con un mensaje que diga qué llegó;
;;   4. solo entonces ramifique.
;;
;; Nunca le entregue al `if` de Scheme el resultado de value-of sin haber
;; comprobado el tipo. Scheme trata como verdadero todo lo que no sea #f, así
;; que `if 5 then ... else ...` se evaluaría en silencio en vez de fallar, y el
;; error del programa quedaría escondido.

(define value-of
  (lambda (exp env)
    (cases expresion exp

      ;; Punto 2
      (const-exp (num)
                 (eopl:error 'value-of "sin-implementar"))

      (var-exp (var)
               (eopl:error 'value-of "sin-implementar"))

      ;; Punto 3
      (diff-exp (exp1 exp2)
                (eopl:error 'value-of "sin-implementar"))

      (zero?-exp (exp1)
                 (eopl:error 'value-of "sin-implementar"))

      ;; Punto 4
      (if-exp (exp1 exp2 exp3)
              (eopl:error 'value-of "sin-implementar"))

      (let-exp (var exp1 body)
               (eopl:error 'value-of "sin-implementar")))))
