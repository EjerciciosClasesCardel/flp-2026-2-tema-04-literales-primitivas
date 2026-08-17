#lang racket

;; Revisa las reglas del curso que las pruebas no pueden revisar por sí solas.
;; No mira el resultado de las funciones, mira cómo están escritas.
;;
;; Lee el código como datos, no como texto, así que los comentarios y las
;; cadenas no disparan falsos positivos: `;; nada de set!` no cuenta como uso
;; de `set!`.
;;
;; La configuración de cada ejercicio vive en verificar/config.rktd. Este
;; archivo es igual en todos.
;;
;;     racket verificar/reglas.rkt

(define config
  (with-input-from-file "verificar/config.rktd" read))

(define (campo clave [defecto '()])
  (cond [(assq clave config) => cdr]
        [else defecto]))

;; Todos los símbolos que aparecen en una estructura de datos, sin importar
;; a qué profundidad.
(define (simbolos dato)
  (let recorrer ([d dato] [acc '()])
    (cond
      [(symbol? d) (cons d acc)]
      [(pair? d) (recorrer (car d) (recorrer (cdr d) acc))]
      [(vector? d) (for/fold ([a acc]) ([x (in-vector d)]) (recorrer x a))]
      [else acc])))

;; Las formas de nivel superior de un archivo. El `#lang` de la primera línea
;; no es un dato legible con `read`, así que se salta.
(define (formas ruta)
  (with-input-from-file ruta
    (lambda ()
      (read-line)
      (let recolectar ([acc '()])
        (define f (read))
        (if (eof-object? f) (reverse acc) (recolectar (cons f acc)))))))

;; El cuerpo de (define nombre ...), en cualquiera de sus dos escrituras.
(define (cuerpo-de forma nombre)
  (match forma
    [(list 'define (== nombre) cuerpo ...) cuerpo]
    [(list 'define (list-rest (== nombre) _) cuerpo ...) cuerpo]
    [_ #f]))

(define fallas '())
(define (falla! texto) (set! fallas (cons texto fallas)))

;; ---------------------------------------------------------------------------
;; Regla 1: construcciones que el ejercicio no admite
;;
;; Un nombre prohibido que el propio archivo define no cuenta: el ejercicio
;; del tema 1 pide escribir `flatten`, y lo que se veta es la de la
;; biblioteca, no la suya. El `provide` tampoco cuenta, porque ahí los
;; nombres se nombran, no se usan.

(define prohibidos (campo 'prohibidos))

(define (definidos-en ruta)
  (filter symbol?
          (for/list ([forma (in-list (formas ruta))])
            (match forma
              [(list 'define (? symbol? n) _ ...) n]
              [(list 'define (list-rest (? symbol? n) _) _ ...) n]
              [_ #f]))))

(for ([ruta (in-list (campo 'archivos))])
  (define propios (definidos-en ruta))
  (define usados
    (remove-duplicates
     (for*/list ([forma (in-list (formas ruta))]
                 #:unless (and (pair? forma) (eq? (car forma) 'provide))
                 [s (in-list (simbolos forma))]
                 #:when (and (memq s prohibidos) (not (memq s propios))))
       s)))
  (unless (null? usados)
    (falla! (format "~a: aparece ~a, que este ejercicio no admite"
                    ruta (string-join (map symbol->string usados) ", ")))))

;; ---------------------------------------------------------------------------
;; Regla 2: las funciones que reciben un árbol lo analizan con `cases`
;;
;; Descomponer una variante a mano con car y cdr funciona, pero se salta la
;; comprobación de variantes que hace `cases` y deja de avisar cuando el
;; datatype cambia.

(define (revisar-cases nombre)
  (define encontrada
    (for*/first ([ruta (in-list (campo 'archivos))]
                 [forma (in-list (formas ruta))]
                 [cuerpo (in-value (cuerpo-de forma nombre))]
                 #:when cuerpo)
      (cons ruta cuerpo)))
  (cond
    [(not encontrada)
     (falla! (format "no se encontró la definición de ~a" nombre))]
    [(not (memq 'cases (simbolos (cdr encontrada))))
     (falla! (format "~a: ~a debe analizar el árbol con cases"
                     (car encontrada) nombre))]
    [else (void)]))

(for-each revisar-cases (campo 'exigen-cases))

;; ---------------------------------------------------------------------------
;; Regla 3: no quedan cuerpos sin implementar
;;
;; Se revisa aparte de las pruebas para que el informe diga qué falta por
;; escribir en vez de solo cuántas pruebas fallan.

(define sin-hacer #rx"sin[ -]implementar")

(for ([ruta (in-list (campo 'archivos))])
  (define pendientes
    (for*/list ([forma (in-list (formas ruta))]
                #:when (for/or ([d (in-list (flatten forma))])
                         (and (string? d) (regexp-match? sin-hacer d)))
                [n (in-value (match forma
                               [(list 'define (? symbol? n) _ ...) n]
                               [(list 'define (list-rest (? symbol? n) _) _ ...) n]
                               [_ 'una-forma]))])
      n))
  (unless (null? pendientes)
    (falla! (format "~a: falta escribir ~a" ruta
                    (string-join (map symbol->string
                                      (remove-duplicates pendientes)) ", ")))))

;; ---------------------------------------------------------------------------

(cond
  [(null? fallas)
   (printf "reglas del curso: en orden\n")]
  [else
   (printf "reglas del curso: ~a incumplimiento(s)\n" (length fallas))
   (for ([f (in-list (reverse fallas))]) (printf "  - ~a\n" f))
   (exit 1)])
