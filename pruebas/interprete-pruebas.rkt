#lang racket

;; Pruebas del tema 4. No modifique este archivo.
;;
;; Se corren con `raco test pruebas/` desde la raíz del repositorio, o desde
;; DrRacket abriendo este archivo y pulsando Ejecutar.

(require rackunit
         rackunit/text-ui
         "../src/ambiente.rkt"
         "../src/sintaxis.rkt"
         "../src/interprete.rkt")

;; Una llamada sin implementar falla con un mensaje legible en vez de tumbar
;; la corrida entera.
(define-syntax-rule (verificar nombre esperado expresion)
  (test-case nombre
    (check-equal? (with-handlers ([exn:fail? (lambda (e) (list 'sin-implementar))])
                    expresion)
                  esperado)))

;; Para los casos que deben fallar no basta con que salte un error: el cuerpo
;; sin implementar también lanza uno. Se exige que el error sea otro.
(define-syntax-rule (verificar-error nombre expresion)
  (test-case nombre
    (define resultado
      (with-handlers ([exn:fail? (lambda (e) (cons 'error (exn-message e)))])
        (list 'sin-error expresion)))
    (cond
      [(not (pair? resultado)) (fail "resultado inesperado")]
      [(eq? (car resultado) 'sin-error)
       (fail (format "se esperaba un error y devolvió ~s" (cadr resultado)))]
      [(regexp-match? #rx"sin-implementar" (cdr resultado))
       (fail "la operación todavía está sin implementar")]
      [else (check-true #t)])))

;; Evalúa un programa escrito con la sintaxis de listas en el ambiente inicial
;; de la sección 3.2, donde i = 1, v = 5, x = 10.
(define (evaluar programa)
  (value-of (parse programa) (init-env)))

;; ---------------------------------------------------------------------------

(define suite-entorno
  (test-suite
   "Entorno"

   (test-case "los tres módulos cargan y exportan lo que se espera"
     (check-true (and (procedure? expval->num)
                      (procedure? expval->bool)
                      (procedure? value-of)
                      (procedure? parse)
                      (procedure? init-env))))

   (test-case "el ambiente inicial tiene ligadas i, v, x"
     (check-equal? (list (apply-env (init-env) 'i)
                         (apply-env (init-env) 'v)
                         (apply-env (init-env) 'x))
                   '(1 5 10)))

   (test-case "parse arma las hojas del árbol"
     (check-equal? (list (parse 14) (parse 'y))
                   (list (const-exp 14) (var-exp 'y))))

   (test-case "parse arma una resta y una comparación con cero"
     (check-equal? (list (parse '(- x 3)) (parse '(zero? i)))
                   (list (diff-exp (var-exp 'x) (const-exp 3))
                         (zero?-exp (var-exp 'i)))))

   (test-case "parse arma el condicional y la ligadura"
     (check-equal? (list (parse '(if (zero? x) then 1 else 2))
                         (parse '(let y = 5 in (- y 3))))
                   (list (if-exp (zero?-exp (var-exp 'x))
                                 (const-exp 1)
                                 (const-exp 2))
                         (let-exp 'y
                                  (const-exp 5)
                                  (diff-exp (var-exp 'y) (const-exp 3))))))

   (test-case "parse rechaza lo que no está en la gramática"
     (check-exn exn:fail? (lambda () (parse '(mientras x 1))))
     (check-exn exn:fail? (lambda () (parse '(+ 1 2)))))

   (test-case "parse rechaza un let con el = o el in fuera de su sitio"
     (check-exn exn:fail? (lambda () (parse '(let x 5 in y))))
     (check-exn exn:fail? (lambda () (parse '(let x = 5 en y))))
     (check-exn exn:fail? (lambda () (parse '(let x = 5 in)))))

   (test-case "parse rechaza un if con el then o el else fuera de su sitio"
     (check-exn exn:fail? (lambda () (parse '(if (zero? x) 1 2))))
     (check-exn exn:fail? (lambda () (parse '(if (zero? x) then 1 2))))
     (check-exn exn:fail? (lambda () (parse '(if (zero? x) then 1 sino 2)))))))

;; ---------------------------------------------------------------------------

(define suite-punto-1
  (test-suite
   "Punto 1 — expval->num y expval->bool"

   (verificar "expval->num sobre un número"
              7 (expval->num 7))

   (verificar "expval->num sobre el cero"
              0 (expval->num 0))

   (verificar "expval->num sobre un negativo"
              -4 (expval->num -4))

   (verificar "expval->bool sobre verdadero"
              #t (expval->bool #t))

   (verificar "expval->bool sobre falso"
              #f (expval->bool #f))

   (verificar-error "expval->num sobre un booleano"
                    (expval->num #t))

   (verificar-error "expval->bool sobre un número"
                    (expval->bool 7))))

;; ---------------------------------------------------------------------------

(define suite-punto-2
  (test-suite
   "Punto 2 — const-exp y var-exp"

   (verificar "un literal se evalúa a sí mismo"
              42 (evaluar 42))

   (verificar "un literal negativo"
              -3 (evaluar -3))

   (verificar "una variable del ambiente inicial"
              10 (evaluar 'x))

   (verificar "otra variable del ambiente inicial"
              1 (evaluar 'i))

   (verificar-error "una variable que no está ligada"
                    (evaluar 'w))))

;; ---------------------------------------------------------------------------

(define suite-punto-3
  (test-suite
   "Punto 3 — diff-exp y zero?-exp"

   (verificar "una resta de literales"
              4 (evaluar '(- 7 3)))

   (verificar "la resta puede dar negativo"
              -4 (evaluar '(- 3 7)))

   (verificar "restas anidadas"
              5 (evaluar '(- (- 10 3) 2)))

   (verificar "la resta usa el ambiente"
              5 (evaluar '(- x v)))

   (verificar "el ejemplo de la sección 3.2"
              3 (evaluar '(- (- x 3) (- v i))))

   (verificar "zero? sobre el cero"
              #t (evaluar '(zero? 0)))

   (verificar "zero? sobre otro número"
              #f (evaluar '(zero? 3)))

   (verificar "zero? sobre una resta que da cero"
              #t (evaluar '(zero? (- v 5))))

   (verificar-error "restar un booleano no se deja pasar"
                    (evaluar '(- 1 (zero? 0))))

   (verificar-error "zero? sobre un booleano no se deja pasar"
                    (evaluar '(zero? (zero? 0))))))

;; ---------------------------------------------------------------------------

(define suite-punto-4
  (test-suite
   "Punto 4 — if-exp y let-exp"

   (verificar "el condicional toma la rama del consecuente"
              1 (evaluar '(if (zero? 0) then 1 else 2)))

   (verificar "el condicional toma la rama del alternante"
              2 (evaluar '(if (zero? 3) then 1 else 2)))

   (verificar "la rama que no se toma no se evalúa"
              5 (evaluar '(if (zero? 0) then 5 else (- 1 (zero? 0)))))

   (verificar "el condicional usa el ambiente"
              20 (evaluar '(if (zero? (- x 10)) then (- x -10) else 0)))

   (verificar "el ejemplo de la sección 3.2 con let"
              2 (evaluar '(let y = 5 in (- y 3))))

   (verificar "el cuerpo del let ve las variables de afuera"
              5 (evaluar '(let y = 5 in (- x y))))

   (verificar "la ligadura de adentro tapa a la de afuera"
              3 (evaluar '(let x = 5 in (let x = 3 in x))))

   (verificar "el let no altera el ambiente de afuera"
              -5 (evaluar '(- (let x = 5 in x) x)))

   (verificar "let y condicional combinados"
              14 (evaluar '(let y = 4 in (if (zero? y) then 0 else (- (- 10 y) -8)))))

   ;; Regla del curso: la prueba del condicional tiene que ser un booleano.
   (verificar-error "un número en la prueba del condicional es un error"
                    (evaluar '(if 5 then 1 else 2)))

   (verificar-error "una variable numérica en la prueba también lo es"
                    (evaluar '(if x then 1 else 2)))))

;; ---------------------------------------------------------------------------

(module+ test
  (run-tests suite-entorno)
  (run-tests suite-punto-1)
  (run-tests suite-punto-2)
  (run-tests suite-punto-3)
  (run-tests suite-punto-4))
