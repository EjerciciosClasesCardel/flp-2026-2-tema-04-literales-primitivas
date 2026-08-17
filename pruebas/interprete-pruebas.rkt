#lang racket

;; Pruebas del tema 4. No modifique este archivo.
;;
;; Se corren con `raco test pruebas/` desde la raíz del repositorio, o desde
;; DrRacket abriendo este archivo y pulsando Ejecutar.

(require rackunit
         rackunit/text-ui
         "../src/ambiente.rkt"
         "../src/gramatica.rkt"
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

;; La categoría y el dato de cada token, sin el número de línea.
(define (tokens texto)
  (map (lambda (tok) (list (car tok) (cadr tok)))
       (escanear texto)))

;; El árbol de un programa, o 'rechazado si el analizador no lo acepta.
(define (analizar texto)
  (with-handlers ([exn:fail? (lambda (e) 'rechazado)])
    (scan&parse texto)))

;; Evalúa un programa en el ambiente inicial de la sección 3.2, donde i = 1,
;; v = 5, x = 10. Si el programa no pasa por el analizador, el que falta por
;; escribir es el punto 2 y la prueba lo dice así.
(define (evaluar texto)
  (define arbol (analizar texto))
  (when (eq? arbol 'rechazado)
    (error 'evaluar
           "la gramática está sin-implementar: el analizador no acepta ~s"
           texto))
  (value-of arbol (init-env)))

;; ---------------------------------------------------------------------------

(define suite-entorno
  (test-suite
   "Entorno"

   (test-case "los módulos cargan y exportan lo que se espera"
     (check-true (and (procedure? escanear)
                      (procedure? scan&parse)
                      (procedure? expval->num)
                      (procedure? expval->bool)
                      (procedure? value-of)
                      (procedure? init-env))))

   (test-case "el ambiente inicial tiene ligadas i, v, x"
     (check-equal? (list (apply-env (init-env) 'i)
                         (apply-env (init-env) 'v)
                         (apply-env (init-env) 'x))
                   '(1 5 10)))

   (test-case "la gramática genera las seis variantes del datatype"
     (check-true (and (expresion? (const-exp 14))
                      (expresion? (var-exp 'y))
                      (expresion? (diff-exp (const-exp 1) (const-exp 2)))
                      (expresion? (zero?-exp (const-exp 0)))
                      (expresion? (if-exp (const-exp 1)
                                          (const-exp 2)
                                          (const-exp 3)))
                      (expresion? (let-exp 'y
                                           (const-exp 5)
                                           (var-exp 'y))))))))

;; ---------------------------------------------------------------------------

(define suite-punto-1
  (test-suite
   "Punto 1 — la especificación léxica"

   (verificar "una variable es un identificador"
              '((identificador x))
              (tokens "x"))

   (verificar "un identificador lleva letras, dígitos y ?"
              '((identificador esCero?) (identificador v1))
              (tokens "esCero? v1"))

   (verificar "un entero es un número"
              '((numero 42))
              (tokens "42"))

   (verificar "el cero y los enteros de varios dígitos"
              '((numero 0) (numero 123))
              (tokens "0 123"))

   (verificar "un entero negativo también es un número"
              '((numero -7))
              (tokens "-7"))

   (verificar "los espacios y los comentarios se descartan"
              '((identificador x) (numero 42))
              (tokens "  x  % esto es un comentario\n  42"))))

;; ---------------------------------------------------------------------------

(define suite-punto-2
  (test-suite
   "Punto 2 — la especificación gramatical"

   (verificar "un literal y una variable"
              (list (const-exp 14) (var-exp 'y))
              (list (analizar "14") (analizar "y")))

   (verificar "un literal negativo"
              (const-exp -4)
              (analizar "-4"))

   (verificar "la resta"
              (diff-exp (var-exp 'x) (const-exp 3))
              (analizar "-(x, 3)"))

   (verificar "la comparación con cero"
              (zero?-exp (var-exp 'i))
              (analizar "zero?(i)"))

   (verificar "el condicional"
              (if-exp (zero?-exp (var-exp 'x)) (const-exp 1) (const-exp 2))
              (analizar "if zero?(x) then 1 else 2"))

   (verificar "la ligadura"
              (let-exp 'y (const-exp 5) (diff-exp (var-exp 'y) (const-exp 3)))
              (analizar "let y = 5 in -(y, 3)"))

   (verificar "las expresiones se anidan"
              (diff-exp (diff-exp (var-exp 'x) (const-exp 3))
                        (diff-exp (var-exp 'v) (var-exp 'i)))
              (analizar "-(-(x, 3), -(v, i))"))

   (verificar "el then y el else son parte del condicional"
              (list (if-exp (zero?-exp (var-exp 'x)) (const-exp 1) (const-exp 2))
                    'rechazado
                    'rechazado)
              (list (analizar "if zero?(x) then 1 else 2")
                    (analizar "if zero?(x) 1 2")
                    (analizar "if zero?(x) then 1 sino 2")))

   (verificar "el = y el in son parte de la ligadura"
              (list (let-exp 'y (const-exp 5) (var-exp 'y))
                    'rechazado
                    'rechazado)
              (list (analizar "let y = 5 in y")
                    (analizar "let y 5 in y")
                    (analizar "let y = 5 en y")))

   (verificar "la coma separa los dos argumentos de la resta"
              (list (diff-exp (var-exp 'x) (const-exp 3)) 'rechazado)
              (list (analizar "-(x, 3)") (analizar "-(x 3)")))

   (verificar "lo que no está en la gramática se rechaza"
              (list (const-exp 5) 'rechazado 'rechazado)
              (list (analizar "5") (analizar "+(1, 2)") (analizar "5 5")))))

;; ---------------------------------------------------------------------------

(define suite-punto-3
  (test-suite
   "Punto 3 — expval->num y expval->bool"

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

(define suite-punto-4
  (test-suite
   "Punto 4 — const-exp y var-exp"

   (verificar "un literal se evalúa a sí mismo"
              42 (evaluar "42"))

   (verificar "un literal negativo"
              -3 (evaluar "-3"))

   (verificar "una variable del ambiente inicial"
              10 (evaluar "x"))

   (verificar "otra variable del ambiente inicial"
              1 (evaluar "i"))

   (verificar-error "una variable que no está ligada"
                    (evaluar "w"))))

;; ---------------------------------------------------------------------------

(define suite-punto-5
  (test-suite
   "Punto 5 — diff-exp y zero?-exp"

   (verificar "una resta de literales"
              4 (evaluar "-(7, 3)"))

   (verificar "la resta puede dar negativo"
              -4 (evaluar "-(3, 7)"))

   (verificar "restas anidadas"
              5 (evaluar "-(-(10, 3), 2)"))

   (verificar "la resta usa el ambiente"
              5 (evaluar "-(x, v)"))

   (verificar "el ejemplo de la sección 3.2"
              3 (evaluar "-(-(x, 3), -(v, i))"))

   (verificar "zero? sobre el cero"
              #t (evaluar "zero?(0)"))

   (verificar "zero? sobre otro número"
              #f (evaluar "zero?(3)"))

   (verificar "zero? sobre una resta que da cero"
              #t (evaluar "zero?(-(v, 5))"))

   (verificar-error "restar un booleano no se deja pasar"
                    (evaluar "-(1, zero?(0))"))

   (verificar-error "zero? sobre un booleano no se deja pasar"
                    (evaluar "zero?(zero?(0))"))))

;; ---------------------------------------------------------------------------

(define suite-punto-6
  (test-suite
   "Punto 6 — if-exp y let-exp"

   (verificar "el condicional toma la rama del consecuente"
              1 (evaluar "if zero?(0) then 1 else 2"))

   (verificar "el condicional toma la rama del alternante"
              2 (evaluar "if zero?(3) then 1 else 2"))

   (verificar "la rama que no se toma no se evalúa"
              5 (evaluar "if zero?(0) then 5 else -(1, zero?(0))"))

   (verificar "el condicional usa el ambiente"
              20 (evaluar "if zero?(-(x, 10)) then -(x, -10) else 0"))

   (verificar "el ejemplo de la sección 3.2 con let"
              2 (evaluar "let y = 5 in -(y, 3)"))

   (verificar "el cuerpo del let ve las variables de afuera"
              5 (evaluar "let y = 5 in -(x, y)"))

   (verificar "la ligadura de adentro tapa a la de afuera"
              3 (evaluar "let x = 5 in let x = 3 in x"))

   (verificar "el let no altera el ambiente de afuera"
              -5 (evaluar "-(let x = 5 in x, x)"))

   (verificar "let y condicional combinados"
              14 (evaluar "let y = 4 in if zero?(y) then 0 else -(-(10, y), -8)"))

   ;; Regla del curso: la prueba del condicional tiene que ser un booleano.
   (verificar-error "un número en la prueba del condicional es un error"
                    (evaluar "if 5 then 1 else 2"))

   (verificar-error "una variable numérica en la prueba también lo es"
                    (evaluar "if x then 1 else 2"))))

;; ---------------------------------------------------------------------------

(module+ test
  (run-tests suite-entorno)
  (run-tests suite-punto-1)
  (run-tests suite-punto-2)
  (run-tests suite-punto-3)
  (run-tests suite-punto-4)
  (run-tests suite-punto-5)
  (run-tests suite-punto-6))
