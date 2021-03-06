
(* This file is free software, part of dolmen. See file "LICENSE" for more information *)

(** {2 Type definitions} *)
(*  ************************************************************************* *)


(** {3 Common definitions} *)

type hash = private int
type index = private int
type 'a tag = 'a Tag.t

type builtin = ..
(* Extensible variant type for builtin operations. Encodes in its type
   arguments the lengths of the expected ty and term arguments respectively. *)

type ttype = Type
(** The type of types. *)

type 'ty id = private {
  ty            : 'ty;
  name          : string;
  index         : index; (** unique *)
  builtin       : builtin;
  mutable tags  : Tag.map;
}
(** The type of identifiers. ['ty] is the type for representing the type of
    the id, ['ty] and ['t_n] are the lengths of arguments as described by
    the {builtin} type. *)

type ('ttype, 'ty) function_type = {
  fun_vars : 'ttype id list; (* prenex forall *)
  fun_args : 'ty list;
  fun_ret : 'ty;
}
(** The type for representing function types. *)


(** {3 Types} *)

type ty_var = ttype id
(** Abbreviation for type variables. *)

and ty_const = (unit, ttype) function_type id
(** Type symbols have the expected length of their argument encoded. *)

and ty_descr =
  | Var of ty_var             (** Type variables *)
  | App of ty_const * ty list (** Application *)
(** Type descriptions. *)

and ty = {
  descr : ty_descr;
  mutable hash : hash; (* lazy hash *)
  mutable tags : Tag.map;
}
(** Types, which wrap type description with a memoized hash and some tags. *)

(** {3 Terms and formulas} *)

type term_var = ty id
(** Term variables *)

and term_const = (ttype, ty) function_type id
(** Term symbols, which encode their expected type and term argument lists lengths. *)

and term_descr =
  | Var of term_var                                         (** Variables *)
  | App of term_const * ty list * term list                 (** Application *)
  | Binder of binder * term                                 (** Binders *)
(** Term descriptions. *)

and binder =
  | Exists of ty_var list * term_var list
  | Forall of ty_var list * term_var list
  | Letin  of (term_var * term) list (**)
(** Binders. *)

and term = {
  ty : ty;
  descr : term_descr;
  mutable hash : hash;
  mutable tags : Tag.map;
}
(** Term, which wrap term descriptions. *)

type formula = term
(** Alias for signature compatibility (with Dolmen_loop.Pipes.Make for instance). *)


(** {2 Exceptions} *)
(*  ************************************************************************* *)

exception Bad_ty_arity of ty_const * ty list
exception Bad_term_arity of term_const * ty list * term list
exception Type_already_defined of ty_const

exception Filter_failed_ty of string * ty
exception Filter_failed_term of string * term

(* {2 Builtins} *)
(* ************************************************************************* *)

(** This section presents the builtins that are defined by Dolmen.

    Users are encouraged to match builtins rather than specific symbols,
    as this basically allows to match on the semantics of an identifier
    rather than matching on the syntaxic value of an identifier. For
    instance, equality can take an arbitrary number of arguments, and thus
    in order to have well-typed terms, each arity of equality gives rise to
    a different symbol (because the symbol's type depends on the arity
    desired), but all these symbols have the [Equal] builtin.

    In the following we will use pseudo-code to describe the arity and
    actual type associated to symbols. These will follow ocaml's notation
    for types with an additional syntax using dots for arbitrary arity.
    Some examples:
    - [ttype] is a type constant
    - [ttype -> ttype] is a type constructor (e.g. [list])
    - [int] is a constant of type [int]
    - [float -> int] is a unary function
    - ['a. 'a -> 'a] is a polymorphic unary function
    - ['a. 'a -> ... -> Prop] describes a family of functions that take
      a type and then an arbitrary number of arguments of that type, and
      return a proposition (this is for instance the type of equality).

    Additionally, due to some languages having overloaded operators, and in
    order to not have too verbose names, some of these builtins may have
    ovreloaded signtures, such as comparisons on numbers which can operate
    on integers, rationals, or reals. Note that arbitrary arity operators
    (well family of operators) can be also be seen as overloaded operators.
    Overloaded types (particularly for numbers) are written:
    - [{a=(Int|Rational|Real)} a -> a -> Prop], which the notable difference
      form polymorphic function that this functions of this type does not
      take a type argument.

    Finally, remember that expressions are polymorphic and that type arguments
    are explicit.
*)

type builtin +=
  | Base
  (** The base builtin; it is the default builtin for identifiers. *)
  | Wildcard
  (** Wildcards, currently used internally to represent implicit type
      variables during type-checking. *)

type builtin +=
  | Prop
  (** [Prop: ttype]: the builtin type constant for the type of
      propositions / booleans. *)
  | Univ
  (** [Univ: ttype]: a builtin type constant used for languages
      with a default type for elements (such as tptp's `$i`). *)

type builtin +=
  | Coercion
  (** [Coercion: 'a 'b. 'a -> 'b]:
      Coercion/cast operator, i.e. allows to cast values of some type to
      another type. This is a polymorphic operator that takes two type
      arguments [a] and [b], a value of type [a], and returns a value of
      type [b].
      The interpretation/semantics of this cast can remain
      up to the user. This operator is currently mainly used to cast
      numeric types when this transormation is exact (i.e. an integer
      casted into a rational, which is always possible and exact,
      or the cast of a rational into an integer, as long as the cast is
      guarded by a clause verifying the rational is an integer). *)

type builtin +=
  | True      (** [True: Prop]: the [true] proposition. *)
  | False     (** [False: Prop]: the [false] proposition. *)
  | Equal     (** [Equal: 'a. 'a -> ... -> Prop]: equality beetween values. *)
  | Distinct  (** [Distinct: 'a. 'a -> ... -> Prop]: pairwise dis-equality beetween arguments. *)
  | Neg       (** [Neg: Prop -> Prop]: propositional negation. *)
  | And       (** [And: Prop -> Prop]: propositional conjunction. *)
  | Or        (** [Or: Prop -> ... -> Prop]: propositional disjunction. *)
  | Nand      (** [Nand: Prop -> Prop -> Prop]: propositional negated conjunction. *)
  | Nor       (** [Nor: Prop -> Prop -> Prop]: propositional negated disjunction. *)
  | Xor       (** [Xor: Prop -> Prop -> Prop]: ppropositional exclusive disjunction. *)
  | Imply     (** [Imply: Prop -> Prop -> Prop]: propositional implication. *)
  | Equiv     (** [Equiv: Prop -> Prop -> Prop]: propositional Equivalence. *)

type builtin +=
  | Ite
  (** [Ite: 'a. Prop -> 'a -> 'a -> 'a]: branching operator. *)

type builtin +=
  | Constructor of ty_const * int
  (** [Constructor (t, n)] is the n-th constructor of the algebraic datatype
      defined by [t]. *)
  | Destructor of ty_const * term_const * int * int
  (** [Destructor (t, c, n, k)] is the destructor retuning the k-th argument
      of the n-th constructor of type [t] which should be [c]. *)

type builtin +=
  | Int
  (** [Int: ttype] the type for signed integers of arbitrary precision. *)
  | Integer of string
  (** [Integer s: Int]: integer litteral. The string [s] should be the
      decimal representation of an integer with arbitrary precision (hence
      the use of strings rather than the limited precision [int]). *)
  | Rat
  (** [Rat: ttype] the type for signed rationals. *)
  | Rational of string
  (** [Rational s: Rational]: rational litteral. The string [s] should be
      the decimal representation of a rational (see the various languages
      spec for more information). *)
  | Real
  (** [Real: ttype] the type for signed reals. *)
  | Decimal of string
  (** [Decimal s: Real]: real litterals. The string [s] should be a
      floating point representatoin of a real. Not however that reals
      here means the mathematical abstract notion of real numbers, including
      irrational, non-algebric numbers, and is thus not restricted to
      floating point numbers, although these are the only litterals
      supported. *)
  | Lt
  (** [Lt: {a=(Int|Rational|Real)} a -> a -> Prop]:
      strict comparison (less than) on numbers
      (whether integers, rationals, or reals). *)
  | Leq
  (** [Leq:{a=(Int|Rational|Real)} a -> a -> Prop]:
      large comparison (less or equal than) on numbers
      (whether integers, rationals, or reals). *)
  | Gt
  (** [Gt:{a=(Int|Rational|Real)} a -> a -> Prop]:
      strict comparison (greater than) on numbers
      (whether integers, rationals, or reals). *)
  | Geq
  (** [Geq:{a=(Int|Rational|Real)} a -> a -> Prop]:
      large comparison (greater or equal than) on numbers
      (whether integers, rationals, or reals). *)
  | Minus
  (** [Minus:{a=(Int|Rational|Real)} a -> a]:
      arithmetic unary negation/minus on numbers
      (whether integers, rationals, or reals). *)
  | Add
  (** [Add:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic addition on numbers
      (whether integers, rationals, or reals). *)
  | Sub
  (** [Sub:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic substraction on numbers
      (whether integers, rationals, or reals). *)
  | Mul
  (** [Mul:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic multiplication on numbers
      (whether integers, rationals, or reals). *)
  | Div
  (** [Div:{a=(Rational|Real)} a -> a -> a]:
      arithmetic exact division on numbers
      (rationals, or reals, but **not** integers). *)
  | Div_e
  (** [Div_e:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer euclidian quotient
      (whether integers, rationals, or reals).
      If D is positive then [Div_e (N,D)] is the floor
      (in the type of N and D) of the real division [N/D],
      and if D is negative then [Div_e (N,D)] is the ceiling
      of [N/D]. *)
  | Div_t
  (** [Div_t:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer truncated quotient
      (whether integers, rationals, or reals).
      [Div_t (N,D)] is the truncation of the real
      division [N/D]. *)
  | Div_f
  (** [Div_f:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer floor quotient
      (whether integers, rationals, or reals).
      [Div_t (N,D)] is the floor of the real
      division [N/D]. *)
  | Modulo
  (** [Modulo:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer euclidian remainder
      (whether integers, rationals, or reals).
      It is defined by the following equation:
      [Div_e (N, D) * D + Modulo(N, D) = N]. *)
  | Modulo_t
  (** [Modulo_t:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer truncated remainder
      (whether integers, rationals, or reals).
      It is defined by the following equation:
      [Div_t (N, D) * D + Modulo_t(N, D) = N]. *)
  | Modulo_f
  (** [Modulo_f:{a=(Int|Rational|Real)} a -> a -> a]:
      arithmetic integer floor remainder
      (whether integers, rationals, or reals).
      It is defined by the following equation:
      [Div_f (N, D) * D + Modulo_f(N, D) = N]. *)
  | Abs
  (** [Abs: Int -> Int]:
      absolute value on integers. *)
  | Divisible
  (** [Divisible: Int -> Int -> Prop]:
      divisibility predicate on integers. Smtlib restricts
      applications of this predicate to have a litteral integer
      for the divisor/second argument. *)
  | Is_int
  (** [Is_int:{a=(Int|Rational|Real)} a -> Prop]:
      integer predicate for numbers: is the given number
      an integer. *)
  | Is_rat
  (** [Is_rat:{a=(Int|Rational|Real)} a -> Prop]:
      rational predicate for numbers: is the given number
      an rational. *)
  | Floor
  (** [Floor:{a=(Int|Rational|Real)} a -> a]:
      floor function on numbers, defined in tptp as
      the largest intger not greater than the argument. *)
  | Ceiling
  (** [Ceiling:{a=(Int|Rational|Real)} a -> a]:
      ceiling function on numbers, defined in tptp as
      the smallest intger not less than the argument. *)
  | Truncate
  (** [Truncate:{a=(Int|Rational|Real)} a -> a]:
      ceiling function on numbers, defined in tptp as
      the nearest integer value with magnitude not greater
      than the absolute value of the argument. *)
  | Round
  (** [Round:{a=(Int|Rational|Real)} a -> a]:
      rounding function on numbers, defined in tptp as
      the nearest intger to the argument; when the argument
      is halfway between two integers, the nearest even integer
      to the argument. *)

(* arrays *)
type builtin +=
  | Array
  (** [Array: ttype -> ttype -> ttype]: the type constructor for
      polymorphic functional arrays. An [(src, dst) Array] is an array
      from expressions of type [src] to expressions of type [dst].
      Typically, such arrays are immutables. *)
  | Store
  (** [Store: 'a 'b. ('a, 'b) Array -> 'a -> 'b -> ('a, 'b) Array]:
      store operation on arrays. Returns a new array with the key bound
      to the given value (shadowing the previous value associated to
      the key). *)
  | Select
  (** [Select: 'a 'b. ('a, 'b) Array -> 'a -> 'b]:
      select operation on arrays. Returns the value associated to the
      given key. Typically, functional arrays are complete, i.e. all
      keys are mapped to a value. *)

(* Bitvectors *)
type builtin +=
  | Bitv of int
  (** [Bitv n: ttype]: type constructor for bitvectors of length [n]. *)
  | Bitvec of string
  (** [Bitvec s: Bitv]: bitvector litteral. The sting [s] should
      be a binary representation of bitvectors using characters
      ['0'], and ['1'].
      NOTE: clarify order of bits (lsb first or last ?) *)
  | Bitv_concat
  (** [Bitv_concat: Bitv(n) -> Bitv(m) -> Bitv(n+m)]:
      concatenation opeartor on bitvectors. *)
  | Bitv_extract of int * int
  (** [Bitv_extract(i, j): Bitv(n) -> Bitv(i - j + 1)]:
      bitvector extraction, from index [j] up to [i] (both included). *)
  | Bitv_repeat
  (** [Bitv_repeat: Bitv(n) -> Bitv(n*k)]:
      bitvector repeatition. NOTE: inlcude [k] in the builtin ? *)
  | Bitv_zero_extend
  (** [Bitv_zero_extend: Bitv(n) -> Bitv(n + k)]:
      zero extension for bitvectors (produces a representation of the
      same unsigned integer). *)
  | Bitv_sign_extend
  (** [Bitv_sign_extend: Bitv(n) -> Bitv(n + k)]:
      sign extension for bitvectors ((produces a representation of the
      same signed integer). *)
  | Bitv_rotate_right of int
  (** [Bitv_rotate_right(i): Bitv(n) -> Bitv(n)]:
      logical rotate right for bitvectors by [i]. *)
  | Bitv_rotate_left of int
  (** [Bitv_rotate_left(i): Bitv(n) -> Bitv(n)]:
      logical rotate left for bitvectors by [i]. *)
  | Bitv_not
  (** [Bitv_not: Bitv(n) -> Bitv(n)]:
      bitwise negation for bitvectors. *)
  | Bitv_and
  (** [Bitv_and: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise conjunction for bitvectors. *)
  | Bitv_or
  (** [bitv_or: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise disjunction for bitvectors. *)
  | Bitv_nand
  (** [Bitv_nand: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise negated conjunction for bitvectors.
      [Bitv_nand s t] abbreviates [Bitv_not (Bitv_and s t))]. *)
  | Bitv_nor
  (** [Bitv_nor: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise negated disjunction for bitvectors.
      [Bitv_nor s t] abbreviates [Bitv_not (Bitv_or s t))]. *)
  | Bitv_xor
  (** [Bitv_xor: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise exclusive disjunction for bitvectors.
      [Bitv_xor s t] abbreviates
      [Bitv_or (Bitv_and s (Bitv_not t))
               (Bitv_and (Bitv_not s) t) ]. *)
  | Bitv_xnor
  (** [Bitv_xnor: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      bitwise negated exclusive disjunction for bitvectors.
      [Bitv_xnor s t] abbreviates
      [Bitv_or (Bitv_and s t)
               (Bitv_and (Bitv_not s) (Bitv_not t))]. *)
  | Bitv_comp
  (** [Bitv_comp: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      TODO: is there a short legible definition of this operator ?
      see SMTLIB's 2.7 spec *)
  | Bitv_neg
  (** [Bitv_neg: Bitv(n) -> Bitv(n)]:
      2's complement unary minus. *)
  | Bitv_add
  (** [Bitv_add: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      addition modulo 2^n. *)
  | Bitv_sub
  (** [Bitv_sub: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      2's complement subtraction modulo 2^n. *)
  | Bitv_mul
  (** [Bitv_mul: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      multiplication modulo 2^n. *)
  | Bitv_udiv
  (** [Bitv_udiv: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      unsigned division, truncating towards 0. *)
  | Bitv_urem
  (** [Bitv_urem: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      unsigned remainder from truncating division. *)
  | Bitv_sdiv
  (** [Bitv_sdiv: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      2's complement signed division. *)
  | Bitv_srem
  (** [Bitv_srem: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      2's complement signed remainder (sign follows dividend). *)
  | Bitv_smod
  (** [Bitv_smod: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      2's complement signed remainder (sign follows divisor). *)
  | Bitv_shl
  (** [Bitv_shl: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      shift left (equivalent to multiplication by 2^x where x
      is the value of the second argument). *)
  | Bitv_lshr
  (** [Bitv_lshr: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      logical shift right (equivalent to unsigned division by 2^x,
      where x is the value of the second argument). *)
  | Bitv_ashr
  (** [Bitv_ashr: Bitv(n) -> Bitv(n) -> Bitv(n)]:
      Arithmetic shift right, like logical shift right except that
      the most significant bits of the result always copy the most
      significant bit of the first argument. *)
  | Bitv_ult
  (** [Bitv_ult: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for unsigned less-than. *)
  | Bitv_ule
  (** [Bitv_ule: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for unsigned less than or equal. *)
  | Bitv_ugt
  (** [Bitv_ugt: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for unsigned greater-than. *)
  | Bitv_uge
  (** [Bitv_uge: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for unsigned greater than or equal. *)
  | Bitv_slt
  (** [Bitv_slt: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for signed less-than. *)
  | Bitv_sle
  (** [Bitv_sle: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for signed less than or equal. *)
  | Bitv_sgt
  (** [Bitv_sgt: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for signed greater-than. *)
  | Bitv_sge
  (** [Bitv_sge: Bitv(n) -> Bitv(n) -> Prop]:
      binary predicate for signed greater than or equal. *)


(** {2 Native Tags} *)
(*  ************************************************************************* *)

module Tags : sig

  type 'a t = 'a tag
  (** Polymorphic tags *)

  include Dolmen_intf.Tag.Smtlib_Base with type 'a t := 'a t
  (** Satsify the Smtlib interface. *)

  include Dolmen_intf.Tag.Zf_Base with type 'a t := 'a t
  (** Satsify the Zf interface. *)

end

(** {2 Filters} *)
(*  ************************************************************************* *)

module Filter : sig

  val reset : unit -> unit
  (** Reset all filters. *)

  module Linear : sig

    val active : bool ref
    (** If [true], only linear terms may be created.
        Trying to create a non-linear term will raise
        a [Filter_failed_ty] or [Filter_failed_term]
        exception. *)

    val name : string
    (** Name of the filter for linear expressions. *)

  end

  module Quantifier : sig

    val allow : bool ref
    (** If [false], trying to build a quantified term
        (i.e. contianing a forall or exists), will raise
        a [Filter_failed_term] exception. *)

    val name : string
    (** Name of the filter for qunatifier-free expressions. *)

  end

end

(** {2 Printing} *)
(*  ************************************************************************* *)

module Print : sig

  type 'a t = Format.formatter -> 'a -> unit
  (** Alias for the type printing functions. *)

  val print_index : bool ref
  (** Determines whether to print the unique index of each identifier or not. *)

  val name : Pretty.name Tag.t
  (** The name tag is used for the printing of identifiers.
      When an identifier has an name tag, its value is used instead of the
      identifier intrinsic name. *)

  val pos : Pretty.pos Tag.t
  (** Positioning for pretty printing. If this tag is set, the printing functions
      will ignore type arguments (for readability).
      [Pretty.Infix] uses the identifier as a separator when printing th argument list
      [Pretty.Prefix] just ignore type arguments. *)


  val id : _ id t
  (** Printer for ids *)

  val ttype : ttype t
  (** Printer for ttype. *)

  val ty_var : ty_var t
  (** Printer to print type variables along with their types. *)

  val term_var : term_var t
  (** Printer to print term variables along with their types. *)

  val ty_const : ty_const t
  (** Printer to print type constants along with their types. *)

  val term_const : term_const t
  (** Printer to print term constants along with their types. *)

  val ty : ty t
  (** Printer for types. *)

  val term : term t
  (** Printer for terms. *)

end

(** {2 Substitutions} *)
(*  ************************************************************************* *)

module Subst : sig
  (** Module to handle substitutions *)

  type ('a, 'b) t
  (** The type of substitutions from values of type ['a] to values of type ['b]. *)

  val empty : ('a, 'b) t
  (** The empty substitution *)

  val is_empty : ('a, 'b) t -> bool
  (** Test wether a substitution is empty *)

  val iter : ('a -> 'b -> unit) -> ('a, 'b) t -> unit
  (** Iterates over the bindings of the substitution. *)

  val map : ('b -> 'c) -> ('a, 'b) t -> ('a, 'c) t
  (** Maps the given function over bound values *)

  val fold : ('a -> 'b -> 'c -> 'c) -> ('a, 'b) t -> 'c -> 'c
  (** Fold over the elements *)

  val merge :
    ('a -> 'b option -> 'c option -> 'd option) ->
    ('a, 'b) t -> ('a, 'c) t -> ('a, 'd) t
  (** Merge two substitutions *)

  val filter : ('a -> 'b -> bool) -> ('a, 'b) t -> ('a, 'b) t
  (** Filter bindings base on a predicate. *)

  val bindings : ('a, 'b) t -> ('a * 'b) list
  (** Returns the list of bindings ofa substitution. *)

  val exists : ('a -> 'b -> bool) -> ('a, 'b) t -> bool
  (** Tests wether the predicate holds for at least one binding. *)

  val for_all : ('a -> 'b -> bool) -> ('a, 'b) t -> bool
  (** Tests wether the predicate holds for all bindings. *)

  val hash : ('b -> int) -> ('a, 'b) t -> int
  val compare : ('b -> 'b -> int) -> ('a, 'b) t -> ('a, 'b) t -> int
  val equal : ('b -> 'b -> bool) -> ('a, 'b) t -> ('a, 'b) t -> bool
  (** Comparison and hash functions, with a comparison/hash function on values as parameter *)

  val print :
    (Format.formatter -> 'a -> unit) ->
    (Format.formatter -> 'b -> unit) ->
    Format.formatter -> ('a, 'b) t -> unit
  (** Prints the substitution, using the given functions to print keys and values. *)

  val debug :
    (Format.formatter -> 'a -> unit) ->
    (Format.formatter -> 'b -> unit) ->
    Format.formatter -> ('a, 'b) t -> unit
  (** Prints the substitution, using the given functions to print keys and values,
      includign some debug info. *)

  val choose : ('a, 'b) t -> 'a * 'b
  (** Return one binding of the given substitution, or raise Not_found if the substitution is empty.*)

  (** {5 Concrete subtitutions } *)
  module type S = sig

    type 'a key
    (** Polymorphic type of keys for the a subtitution *)

    val get : 'a key -> ('a key, 'b) t -> 'b
    (** [get v subst] returns the value associated with [v] in [subst], if it exists.
        @raise Not_found if there is no binding for [v]. *)

    val mem : 'a key -> ('a key, 'b) t -> bool
    (** [get v subst] returns wether there is a value associated with [v] in [subst]. *)

    val bind : ('a key, 'b) t -> 'a key -> 'b -> ('a key, 'b) t
    (** [bind v t subst] returns the same substitution as [subst] with the additional binding from [v] to [t].
        Erases the previous binding of [v] if it exists. *)

    val remove : 'a key -> ('a key, 'b) t -> ('a key, 'b) t
    (** [remove v subst] returns the same substitution as [subst] except for [v] which is unbound in the returned substitution. *)

  end

  module Var : S with type 'a key = 'a id
end

(** {2 Types} *)
(*  ************************************************************************* *)

module Ty : sig

  (** {4 Usual definitions} *)

  type t = ty
  (** The type of types. *)

  type subst = (ty_var, ty) Subst.t
  (** The type of substitutions over types. *)

  type 'a tag = 'a Tag.t
  (** A type for tags to attach to arbitrary types. *)

  val hash : t -> int
  (** A hash function for types, should be suitable to create hashtables. *)

  val equal : t -> t -> bool
  (** An equality function on types. Should be compatible with the hash function. *)

  val compare : t -> t -> int
  (** Comparison function over types. Should be compativle with the equality function. *)

  val print : Format.formatter -> t -> unit
  (** Printing function. *)


  (** {4 Type structure definition} *)

  type adt_case = {
    cstr : term_const;
    dstrs : term_const option array;
  }
  (** One case of an algebraic datatype definition. *)

  type def =
    | Abstract
    | Adt of {
        ty : ty_const;
        record : bool;
        cstrs : adt_case list;
      } (** *)
  (** The various ways to define a type inside the solver. *)

  val define : ty_const -> def -> unit
  (** Register a type definition. *)

  val definition : ty_const -> def option
  (** Return the definition of a type (if it exists). *)


  (** {4 Variables and constants} *)

  (** A module for variables that occur in types. *)
  module Var : sig

    type t = ty_var
    (** The type of variables the can occur in types *)

    val hash : t -> int
    (** A hash function for type variables, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on type variables. Should be compatible with the hash function. *)

    val compare : t -> t -> int
    (** Comparison function on variables. *)

    val mk : string -> t
    (** Create a new type variable with the given name. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a variable. *)

    val get_tag : t -> 'a tag -> 'a option
    (** Return the value associated to the tag (if any). *)

  end

  (** A module for constant symbols the occur in types. *)
  module Const : sig

    type t = ty_const
    (** The type of constant symbols the can occur in types *)

    val hash : t -> int
    (** A hash function for type constants, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on type constants. Should be compatible with the hash function. *)

    val compare : t -> t -> int
    (** Comparison function on variables. *)

    val arity : t -> int
    (** Return the arity of the given symbol. *)

    val mk : string -> int -> t
    (** Create a type constant with the given arity. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a variable. *)

    val get_tag : t -> 'a tag -> 'a option
    (** Return the value associated to the tag (if any). *)

    val int : t
    (** The type constant for integers *)

    val rat : t
    (** The type constant for rationals *)

    val real : t
    (** The type constant for reals. *)

    val prop : t
    (** The type constant for propositions *)

    val base : t
    (** An arbitrary type constant. *)

    val array : t
    (** The type constant for arrays *)

    val bitv : int -> t
    (** Bitvectors of the given length. *)

  end

  val prop : t
  (** The type of propositions *)

  val base : t
  (** An arbitrary type. *)

  val int : t
  (** The type of integers *)

  val rat : t
  (** The type of rationals *)

  val real : t
  (** The type of reals. *)

  val wildcard : unit -> t
  (** Type wildcard *)

  val of_var : Var.t -> t
  (** Create a type from a variable. *)

  val apply : Const.t -> t list -> t
  (** Application for types. *)

  val array : t -> t -> t
  (** Build an array type from source to destination types. *)

  val bitv : int -> t
  (** Bitvectors of a given length. *)

  val tag : t -> 'a tag -> 'a -> unit
  (** Annotate the given type with the given tag and value. *)

  val get_tag : t -> 'a tag -> 'a option
  (** Return the value associated to the tag (if any). *)

  val subst : ?fix:bool -> subst -> t -> t
  (** Substitution on types. *)

end

(** {2 Terms} *)
(*  ************************************************************************* *)

module Term : sig

  (** Signature required by terms for typing first-order
      polymorphic terms. *)

  type t = term
  (** The type of terms and term variables. *)

  type ty = Ty.t
  type ty_var = Ty.Var.t
  type ty_const = Ty.Const.t
  (** The representation of term types, type variables, and type constants. *)

  type subst = (term_var, term) Subst.t
  (** The type of substitutions over terms. *)

  type 'a tag = 'a Tag.t
  (** The type of tags used to annotate arbitrary terms. *)

  val hash : t -> int
  (** Hash function. *)

  val equal : t -> t -> bool
  (** Equality function. *)

  val compare : t -> t -> int
  (** Comparison function. *)

  val print : Format.formatter -> t -> unit
  (** Printing function. *)

  val ty : t -> ty
  (** Returns the type of a term. *)

  (** A module for variables that occur in terms. *)
  module Var : sig

    type t = term_var
    (** The type of variables the can occur in terms *)

    val hash : t -> int
    (** A hash function for term variables, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on term variables. Should be compatible with the hash function. *)

    val compare : t -> t -> int
    (** Comparison function on variables. *)

    val mk : string -> ty -> t
    (** Create a new typed variable. *)

    val ty : t -> ty
    (** Return the type of the variable. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a variable. *)

    val get_tag : t -> 'a tag -> 'a option
    (** Return the value associated to the tag (if any). *)

  end

  (** A module for constant symbols that occur in terms. *)
  module Const : sig

    type t = term_const
    (** The type of constant symbols that can occur in terms *)

    val hash : t -> int
    (** A hash function for term constants, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on term constants. Should be compatible with the hash function. *)

    val compare : t -> t -> int
    (** Comparison function on variables. *)

    val arity : t -> int * int
    (** Returns the arity of a term constant. *)

    val mk : string -> ty_var list -> ty list -> ty -> t
    (** Create a polymorphic constant symbol. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a constant. *)

    val get_tag : t -> 'a tag -> 'a option
    (** Return the value associated to the tag (if any). *)

  end

  (** A module for Algebraic datatype constructors. *)
  module Cstr : sig

    type t = term_const
    (** An algebraic type constructor. Note that such constructors are used to
        build terms, and not types, e.g. consider the following:
        [type 'a list = Nil | Cons of 'a * 'a t], then [Nil] and [Cons] are the
        constructors, while [list] would be a type constant of arity 1 used to
        name the type. *)

    val hash : t -> int
    (** A hash function for adt constructors, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on adt constructors. Should be compatible with the hash function. *)

    val compare : t -> t -> int
    (** Comparison function on variables. *)

    val arity : t -> int * int
    (** Returns the arity of a constructor. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a constant. *)

    val get_tag : t -> 'a tag -> 'a option
    (** Return the value associated to the tag (if any). *)

  end

  (** A module for Record fields. *)
  module Field : sig

    type t = term_const
    (** A record field. *)

    val hash : t -> int
    (** A hash function for adt constructors, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on adt constructors. Should be compatible with the hash function. *)

  end

  val define_record :
    ty_const -> ty_var list -> (string * ty) list -> Field.t list
  (** Define a new record type. *)

  val define_adt :
    ty_const -> ty_var list ->
    (string * (ty * string option) list) list ->
    (Cstr.t * (ty * Const.t option) list) list
  (** [define_aft t vars cstrs] defines the type constant [t], parametrised over
      the type variables [ty_vars] as defining an algebraic datatypes with constructors
      [cstrs]. [cstrs] is a list where each elements of the form [(name, l)] defines
      a new constructor for the algebraic datatype, with the given name. The list [l]
      defines the arguments to said constructor, each element of the list giving the
      type [ty] of the argument expected by the constructor (which may contain any of the type
      variables in [vars]), as well as an optional destructor name. If the construcotr name
      is [Some s], then the ADT definition also defines a function that acts as destructor
      for that particular field. This polymorphic function is expected to takes as arguments
      as many types as there are variables in [vars], an element of the algebraic datatype
      being defined, and returns a value for the given field.
      For instance, consider the following definition for polymorphic lists:
      [define_adt list \[ty_var_a\] \[
        "nil", \[\];
        "const", \[
          (Ty.of_var ty_var_a , Some "hd");
          (ty_list_a          , Some "tl");
          \];
       \]
      ]
      This definition defines the usual type of polymorphic linked lists, as well as two
      destructors "hd" and "tl". "hd" would have type [forall alpha. alpha list -> a], and
      be the partial function returning the head of the list.
      *)

  exception Wrong_type of t * ty
  (** Exception raised in case of typing error during term construction.
      [Wrong_type (t, ty)] should be raised by term constructor functions when some term [t]
      is expected to have type [ty], but does not have that type. *)

  exception Wrong_record_type of Field.t * ty_const
  (** Exception raised in case of typing error during term construction.
      This should be raised when the returned field was expected to be a field
      for the returned record type constant, but it was of another record type. *)

  exception Field_repeated of Field.t
  (** Field repeated in a record expression. *)

  exception Field_missing of Field.t
  (** Field missing in a record expression. *)

  exception Field_expected of term_const
  (** A field was expected but the returned term constant is not a record field. *)

  val ensure : t -> ty -> t
  (** Ensure a term has the given type. *)

  val of_var : Var.t -> t
  (** Create a term from a variable *)

  val apply : Const.t -> ty list -> t list -> t
  (** Polymorphic application. *)

  val apply_cstr : Cstr.t -> ty list -> t list -> t
  (** Polymorphic application of a constructor. *)

  val apply_field : Field.t -> t -> t
  (** Field access for a record. *)

  val _true : t
  val _false : t
  (** Some usual formulas. *)

  val int : string -> t
  (* Integer literals *)

  val rat : string -> t
  (* Rational literals *)

  val real : string -> t
  (** Real literals *)

  val record : (Field.t * t) list -> t
  (** Create a record *)

  val record_with : t -> (Field.t * t) list -> t
  (** Record udpate *)

  val eq : t -> t -> t
  (** Build the equality of two terms. *)

  val eqs : t list -> t
  (** Build equalities with arbitrary arities. *)

  val distinct : t list -> t
  (** Distinct constraints on terms. *)

  val neg : t -> t
  (** Negation. *)

  val _and : t list -> t
  (** Conjunction of formulas *)

  val _or : t list -> t
  (** Disjunction of formulas *)

  val nand : t -> t -> t
  (** Negated conjunction. *)

  val nor : t -> t -> t
  (** Negated disjunction. *)

  val xor : t -> t -> t
  (** Exclusive disjunction. *)

  val imply : t -> t -> t
  (** Implication *)

  val equiv : t -> t -> t
  (** Equivalence *)

  val select : t -> t -> t
  (** Array selection. *)

  val store : t -> t -> t -> t
  (** Array store *)

  val all :
    ty_var list * Var.t list ->
    ty_var list * Var.t list ->
    t -> t
  (** Universally quantify the given formula over the type and terms variables.
      The first pair of arguments are the variables that are free in the resulting
      quantified formula, and the second pair are the variables bound. *)

  val ex :
    ty_var list * Var.t list ->
    ty_var list * Var.t list ->
    t -> t
  (** Existencially quantify the given formula over the type and terms variables.
      The first pair of arguments are the variables that are free in the resulting
      quantified formula, and the second pair are the variables bound. *)

  val letin : (Var.t * t) list -> t -> t
  (** Let-binding. Variabels can be bound to either terms or formulas. *)

  val ite : t -> t -> t -> t
  (** [ite condition then_t else_t] creates a conditional branch. *)

  val tag : t -> 'a tag -> 'a -> unit
  (** Annotate the given formula wiht the tag and value. *)

  val get_tag : t -> 'a tag -> 'a option
  (** Return the value associated to the tag (if any). *)

  val fv : t -> ty_var list * Var.t list
  (** Returns the list of free variables in the formula. *)

  val subst : ?fix:bool -> Ty.subst -> subst -> t -> t
  (** Substitution over terms. *)

  include Dolmen_intf.Term.Smtlib_Bitv with type t := t
  (** Satisfy the required interface for typing smtlib bitvectors. *)

  (** Integer operations. *)
  module Int : sig
    include Dolmen_intf.Term.Smtlib_Int with type t := t
    include Dolmen_intf.Term.Tptp_Arith_Common with type t := t

    val div : t -> t -> t
    (** Euclidian division quotient *)

    val div_t : t -> t -> t
    (** Truncation of the rational/real division. *)

    val div_f : t -> t -> t
    (** Floor of the ration/real division. *)

    val rem : t -> t -> t
    (** Euclidian division remainder *)

    val rem_t : t -> t -> t
    (** Remainder for the truncation of the rational/real division. *)

    val rem_f : t -> t -> t
    (** Remaidner for the floor of the ration/real division. *)

  end

  (** Rational operations *)
  module Rat : sig
    include Dolmen_intf.Term.Tptp_Arith_Common with type t := t

    val div : t -> t -> t
    (** Exact division on rationals. *)
  end

  (** Real operations *)
  module Real : sig
    include Dolmen_intf.Term.Smtlib_Real with type t := t
    include Dolmen_intf.Term.Tptp_Arith_Common with type t := t
  end

end

