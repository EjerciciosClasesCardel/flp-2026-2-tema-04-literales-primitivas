# Tema 4 — Interpretación y compilación: literales y primitivas

Fundamentos de Interpretación y Compilación de Lenguajes de Programación
Escuela de Ingeniería de Sistemas y Computación, Universidad del Valle
Carlos Andrés Delgado Saavedra

Ejercicio de autoseguimiento del tema 4. No se califica y no hay que
entregarlo: las pruebas le dicen solas si va bien.

Este es el primer intérprete de verdad del curso. Hasta el tema 3 el trabajo
fue armar el árbol de sintaxis abstracta; aquí ese árbol por fin se evalúa.
Todo lo que viene después —procedimientos, recursión, asignación, tipos— se
construye agregándole ramas a la función `value-of` que va a escribir en este
ejercicio.

## De qué se trata

El lenguaje es LET, recortado a seis producciones (EOPL, sección 3.1):

```
Expression ::= Number                        const-exp  (num)
           ::= Identifier                    var-exp    (var)
           ::= -(Exp , Exp)                  diff-exp   (exp1 exp2)
           ::= zero?(Exp)                    zero?-exp  (exp1)
           ::= if Exp then Exp else Exp      if-exp     (exp1 exp2 exp3)
           ::= let Id = Exp in Exp           let-exp    (var exp1 body)
```

Los programas se escriben como listas de Scheme y `parse` los traduce a
sintaxis abstracta:

| sección 3.1             | como lista                | variante    |
|-------------------------|---------------------------|-------------|
| `14`                    | `14`                      | `const-exp` |
| `x`                     | `x`                       | `var-exp`   |
| `-(e1, e2)`             | `(- e1 e2)`               | `diff-exp`  |
| `zero?(e1)`             | `(zero? e1)`              | `zero?-exp` |
| `if e1 then e2 else e3` | `(if e1 then e2 else e3)` | `if-exp`    |
| `let x = e1 in e2`      | `(let x = e1 in e2)`      | `let-exp`   |

Es la sintaxis que usan los demás temas del curso. El `then`, el `else`, el `=`
y el `in` son palabras de la gramática y van en su posición: `(if x 1 2)`,
`(let x 5 in y)` y `(let x = 5 en y)` no son programas del lenguaje y `parse`
los rechaza.

El valor expresado es lo que devuelve la evaluación de una expresión (EOPL,
sección 3.2). Aquí hay dos, `ExpVal = Int + Bool`, representados con los
números y los booleanos de Scheme.

## Cómo está organizado

```
src/ambiente.rkt                el TAD de ambientes, ya resuelto
src/sintaxis.rkt                el define-datatype y parse, ya resueltos
src/interprete.rkt              los cuatro puntos
pruebas/interprete-pruebas.rkt  las pruebas, que no se modifican
```

Los dos primeros archivos vienen resueltos y no hay que tocarlos. El ambiente
es el del tema 2 con la representación de listas, más `init-env`, el ambiente
inicial de la sección 3.2 donde `i` vale 1, `v` vale 5 y `x` vale 10. Las
pruebas evalúan todo contra ese ambiente, así que puede usar esas tres
variables en sus ejemplos sin ligarlas.

## Cómo empezar

1. **Haga fork.** Botón *Fork* arriba a la derecha. El fork queda en su cuenta
   y usted trabaja ahí.

2. **Active las Actions.** Al hacer fork, GitHub deja los workflows apagados.
   Entre a la pestaña *Actions* de **su** fork y pulse el botón verde
   *I understand my workflows, go ahead and enable them*. Sin esto puede hacer
   todos los push que quiera y nunca se va a correr nada.

3. **Clone su fork:**

   ```bash
   git clone https://github.com/SU-USUARIO/flp-2026-2-tema-04-literales-primitivas.git
   cd flp-2026-2-tema-04-literales-primitivas
   ```

4. **Resuelva** los cuatro puntos en `src/interprete.rkt`.

5. **Haga push.** Cada push dispara las pruebas.

## Cómo se ejecutan las pruebas

```bash
raco test pruebas/
```

O desde DrRacket, abriendo `pruebas/interprete-pruebas.rkt` y pulsando
*Ejecutar*. Si necesita instalar Racket, use la distribución completa de
[racket-lang.org](https://racket-lang.org): la mínima no trae `#lang eopl`.

## El punto de partida

Al clonar hay 41 pruebas: 8 en verde y 33 en rojo. Las verdes comprueban que
los tres módulos cargan, que el ambiente inicial está donde debe y que `parse`
arma el árbol que se espera y rechaza lo que no pertenece al lenguaje; que
pasen significa que Racket y `eopl` quedaron bien instalados y que la parte ya
resuelta funciona.

## Los cuatro puntos

### 1. `expval->num` y `expval->bool`

Los extractores del valor expresado (EOPL, sección 3.2). Cada uno devuelve el
valor cuando es del tipo que se pidió y lanza un error con `eopl:error` cuando
no lo es. Como los valores expresados son números y booleanos de Scheme, el
cuerpo es corto: la comprobación es lo único que hay.

Por ahí pasa después todo lo que necesita un tipo concreto. `diff-exp` pide dos
números, `if-exp` pide un booleano, y si el programa entrega otra cosa el error
sale de aquí, no de una operación de Scheme fallando tres marcos más abajo.

### 2. `value-of` para `const-exp` y `var-exp`

Las dos hojas del árbol. El literal se evalúa a sí mismo y la variable se
resuelve contra el ambiente con `apply-env`.

### 3. `value-of` para `diff-exp` y `zero?-exp`

Las dos primitivas. `diff-exp` evalúa las dos subexpresiones, saca los números
con `expval->num` y resta. `zero?-exp` evalúa la suya y devuelve un booleano:
esta es la única producción del lenguaje que fabrica booleanos, y por eso
existe.

### 4. `value-of` para `if-exp` y `let-exp`

`let-exp` evalúa la expresión ligada, extiende el ambiente y evalúa el cuerpo
en el ambiente extendido. `if-exp` tiene su propia regla, la de aquí abajo.

## La regla del `if-exp`

Es la convención del curso y aplica a todos los intérpretes de aquí en
adelante. Al evaluar `if-exp`:

1. evalúe la expresión de prueba con `value-of`;
2. compruebe con `boolean?` que el resultado es un booleano, sea llamando a
   `boolean?` o pasando el valor por `expval->bool`, que es esa misma
   comprobación;
3. si no lo es, lance `eopl:error` con un mensaje que diga qué llegó;
4. solo entonces ramifique.

Lo que no se hace es entregarle al `if` de Scheme el resultado de `value-of`
sin mirar el tipo. Scheme trata como verdadero todo lo que no sea `#f`, así que
`(if 5 then 1 else 2)` devolvería 1 tan tranquilo y el lenguaje que usted implementó
habría aceptado un programa que no tiene sentido. Hay dos pruebas que exigen
justamente ese error.

## Dos cosas que las pruebas revisan y suelen olvidarse

- **La rama que no se toma no se evalúa.** Evalúe la prueba, decida, y solo
  entonces llame a `value-of` sobre la rama que corresponde. Si evalúa las dos
  y después escoge, `(if (zero? 0) then 5 else (- 1 (zero? 0)))` revienta en vez
  de dar 5.
- **El `let` no altera el ambiente de afuera.** `extend-env` devuelve un
  ambiente nuevo; el que recibió sigue igual. Después de
  `(- (let x = 5 in x) x)` con el ambiente inicial, la `x` de la derecha vale
  10 y el resultado es -5.
