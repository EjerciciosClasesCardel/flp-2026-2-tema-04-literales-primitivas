#lang eopl

;; Tema 4 — Sintaxis abstracta y analizador sintáctico
;; Fundamentos de Interpretación y Compilación de Lenguajes de Programación
;; Universidad del Valle, sede Tuluá
;;
;; Este archivo ya viene resuelto. No hay nada que escribir aquí.
;;
;; Es el mismo lenguaje del tema 3: la gramática de LET de la sección 3.1 de
;; EOPL recortada a seis producciones.

(provide expresion
         const-exp var-exp diff-exp zero?-exp if-exp let-exp
         parse)

;; ---------------------------------------------------------------------------
;; Gramática (EOPL, sección 3.1)
;;
;;   Expression ::= Number                        const-exp  (num)
;;              ::= Identifier                    var-exp    (var)
;;              ::= -(Exp , Exp)                  diff-exp   (exp1 exp2)
;;              ::= zero?(Exp)                    zero?-exp  (exp1)
;;              ::= if Exp then Exp else Exp      if-exp     (exp1 exp2 exp3)
;;              ::= let Id = Exp in Exp           let-exp    (var exp1 body)
;;
;; La sintaxis concreta del libro se escribe como texto y se analiza con un
;; lexer y un parser generados. Aquí el programa llega ya como una lista de
;; Scheme y `parse` solo lo traduce a sintaxis abstracta:
;;
;;   sección 3.1                 como lista            variante
;;   ---------------------------------------------------------------
;;   14                          14                    const-exp
;;   x                           x                     var-exp
;;   -(e1, e2)                   (- e1 e2)             diff-exp
;;   zero?(e1)                   (zero? e1)            zero?-exp
;;   if e1 then e2 else e3       (if e1 e2 e3)         if-exp
;;   let x = e1 in e2            (let (x e1) e2)       let-exp
;;
;; Un ejemplo completo, el de la figura 3.4 escrito con listas:
;;
;;   (let (x 5) (- x 3))   =>   #(struct:let-exp x
;;                                 #(struct:const-exp 5)
;;                                 #(struct:diff-exp #(struct:var-exp x)
;;                                                   #(struct:const-exp 3)))

;; ---------------------------------------------------------------------------
;; Sintaxis abstracta

(define-datatype expresion expresion?
  (const-exp
   (num number?))
  (var-exp
   (var symbol?))
  (diff-exp
   (exp1 expresion?)
   (exp2 expresion?))
  (zero?-exp
   (exp1 expresion?))
  (if-exp
   (exp1 expresion?)
   (exp2 expresion?)
   (exp3 expresion?))
  (let-exp
   (var symbol?)
   (exp1 expresion?)
   (body expresion?)))

;; ---------------------------------------------------------------------------
;; parse : SchemeVal -> Expresion

(define parse
  (lambda (dato)
    (cond
      ((number? dato)
       (const-exp dato))
      ((symbol? dato)
       (var-exp dato))
      ((forma? dato '- 3)
       (diff-exp (parse (cadr dato)) (parse (caddr dato))))
      ((forma? dato 'zero? 2)
       (zero?-exp (parse (cadr dato))))
      ((forma? dato 'if 4)
       (if-exp (parse (cadr dato)) (parse (caddr dato)) (parse (cadddr dato))))
      ((and (forma? dato 'let 3)
            (pair? (cadr dato))
            (= (length (cadr dato)) 2)
            (symbol? (car (cadr dato))))
       (let-exp (car (cadr dato))
                (parse (cadr (cadr dato)))
                (parse (caddr dato))))
      (else
       (eopl:error 'parse "no es una expresión del lenguaje: ~s" dato)))))

;; forma? : SchemeVal × Symbol × Int -> Bool
;; Reconoce una lista de `largo` elementos que empieza por la palabra clave.
(define forma?
  (lambda (dato clave largo)
    (and (list? dato)
         (= (length dato) largo)
         (eqv? (car dato) clave))))
