#lang eopl

;; Tema 4 — Especificación léxica y gramatical
;; Fundamentos de Interpretación y Compilación de Lenguajes de Programación
;; Universidad del Valle, sede Tuluá
;;
;; Aquí van los puntos 1 y 2: las dos especificaciones con las que SLLGEN
;; construye el escáner y el analizador sintáctico del lenguaje.

(provide especificacion-lexica
         especificacion-gramatical
         expresion expresion?
         const-exp var-exp diff-exp zero?-exp if-exp let-exp
         escanear scan&parse datatypes-generados)

;; ---------------------------------------------------------------------------
;; Del texto al árbol
;;
;;   texto -> escáner -> tokens -> parser -> árbol de sintaxis abstracta
;;
;; El escáner parte el texto en tokens y descarta lo que no significa nada:
;; espacios y comentarios. El parser recibe los tokens y arma el árbol. SLLGEN
;; genera los dos a partir de dos listas, la especificación léxica y la
;; especificación gramatical (EOPL, apéndice B).
;;
;; Hasta el tema 3 los programas se escribían como listas de Scheme y una
;; función `parse` hecha a mano las traducía a sintaxis abstracta. Era un
;; andamio para trabajar el árbol sin depender todavía de un analizador. Desde
;; este tema la sintaxis concreta es texto y el analizador lo genera SLLGEN:
;;
;;   (scan&parse "let x = 5 in -(x, 3)")

;; ---------------------------------------------------------------------------
;; Punto 1: la especificación léxica
;;
;; Cada regla tiene tres partes:
;;
;;   (nombre (patrón) acción)
;;
;;   nombre   la categoría del token; la gramática la nombra por ese nombre
;;   patrón   expresión regular armada con letter, digit, whitespace,
;;            (arbno ...), (or ...), (not ...) y cadenas literales
;;   acción   skip descarta el token; symbol y number convierten el texto
;;            reconocido en un símbolo o un número de Scheme
;;
;; El lenguaje tiene dos categorías que llevan contenido:
;;
;;   identificador   una letra seguida de cero o más letras, dígitos, ? o $
;;                   x, v, i, esCero?, contador1
;;
;;   numero          un entero, con un signo menos opcional adelante
;;                   0, 42, -7
;;
;; Los espacios en blanco se descartan y un comentario va desde % hasta el fin
;; de línea; esas dos reglas ya están escritas. Las palabras del lenguaje
;; (let, in, if, then, else, zero?) y los signos (- ( ) , =) no se declaran
;; aquí: SLLGEN los saca de las cadenas literales de la gramática.

(define especificacion-lexica
  '((espacio-blanco (whitespace) skip)
    (comentario ("%" (arbno (not #\newline))) skip)

    ;; Las dos categorías que faltan. El patrón que hay puesto reconoce una
    ;; sola palabra literal, así que por ahora el escáner no acepta ni una
    ;; variable ni un número: cámbielo por la expresión regular que
    ;; corresponde. Los nombres de las categorías se dejan como están, porque
    ;; la gramática de abajo los nombra.
    (identificador ("sin-implementar-identificador") symbol)
    (numero ("sin-implementar-numero") number)))

;; ---------------------------------------------------------------------------
;; Punto 2: la especificación gramatical
;;
;; Cada producción tiene tres partes:
;;
;;   (no-terminal (sintaxis concreta) nombre-de-la-variante)
;;
;; La sintaxis concreta es una lista con cadenas literales, nombres de
;; categorías léxicas y nombres de no terminales. Las cadenas literales son
;; los signos y las palabras que el programador escribe; las categorías y los
;; no terminales son los campos de la variante.
;;
;; La gramática del lenguaje LET recortado a seis producciones (EOPL,
;; sección 3.1):
;;
;;   Expression ::= Number                        const-exp  (num)
;;              ::= Identifier                    var-exp    (var)
;;              ::= -(Exp , Exp)                  diff-exp   (exp1 exp2)
;;              ::= zero?(Exp)                    zero?-exp  (exp1)
;;              ::= if Exp then Exp else Exp      if-exp     (exp1 exp2 exp3)
;;              ::= let Id = Exp in Exp           let-exp    (var exp1 body)
;;
;; Así se ven los programas de la sección 3.1 en esta sintaxis:
;;
;;   14
;;   x
;;   -(x, 3)
;;   zero?(i)
;;   if zero?(x) then 1 else 2
;;   let x = 5 in -(x, 3)
;;   -(-(x, 3), -(v, i))
;;
;; Los nombres de las variantes y el número y el tipo de sus campos se dejan
;; como están: `value-of`, en src/interprete.rkt, analiza el árbol con esos
;; seis nombres y con esos campos. Lo que hay que escribir es la parte del
;; medio, la sintaxis concreta, que de momento es una palabra clave
;; provisional puesta ahí para que el resto del ejercicio compile.

(define especificacion-gramatical
  '((expresion ("sin-implementar-const" numero) const-exp)
    (expresion ("sin-implementar-var" identificador) var-exp)
    (expresion ("sin-implementar-resta" expresion expresion) diff-exp)
    (expresion ("sin-implementar-cero" expresion) zero?-exp)
    (expresion ("sin-implementar-si" expresion expresion expresion) if-exp)
    (expresion ("sin-implementar-liga" identificador expresion expresion) let-exp)))

;; ---------------------------------------------------------------------------
;; De las dos especificaciones salen el datatype, el escáner y el parser.
;; Esta parte ya está escrita.

;; Genera el define-datatype de la sintaxis abstracta a partir de la gramática:
;; un datatype `expresion` con una variante por producción, y los campos con el
;; predicado que les toca: number? para las categorías con acción number,
;; symbol? para las de acción symbol y expresion? para los no terminales.
(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; datatypes-generados : () -> ListOf(SchemeVal)
;; El define-datatype que genera la gramática, escrito como dato. Llámela desde
;; el REPL, (datatypes-generados), para ver el árbol que va a recibir value-of.
(define datatypes-generados
  (lambda ()
    (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; escanear : String -> ListOf(Token)
;; El escáner suelto, para mirar en qué tokens queda partido un texto. Cada
;; token es una lista (categoría dato línea).
(define escanear
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; scan&parse : String -> Expresion
;; El escáner y el parser encadenados: recibe el programa como texto y devuelve
;; su árbol de sintaxis abstracta.
(define scan&parse
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))
