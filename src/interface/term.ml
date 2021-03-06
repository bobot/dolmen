
(* This file is free software, part of dolmen. See file "LICENSE" for more information *)

(** Interfaces for Terms.
    This module defines Interfaces that implementation of terms must
    respect in order to be used to instantiated the corresponding
    language classes. *)

(** {2 Signature for Parsing Logic languages} *)

module type Logic = sig

  (** Signature used by the Logic class, which parses languages
      such as tptp, smtlib, etc...
      Mainly used to parse first-order terms, it is also used to
      parse tptp's THF language, which uses higher order terms, so
      some first-order constructs such as conjunction, equality, etc...
      also need to be represented by standalone terms. *)

  type t
  (** The type of terms. *)

  type id
  (** The type of identifiers used for constants. *)

  type location
  (** The type of locations attached to terms. *)

  (** {3 Predefined terms} *)

  val eq_t      : ?loc:location -> unit -> t
  val neq_t     : ?loc:location -> unit -> t
  (** The terms representing equality and disequality, respectively. *)

  val wildcard  : ?loc:location -> unit -> t
  (** The wildcard term, usually used in place of type arguments
      to explicit polymorphic functions to not explicit types that
      can be inferred by the type-checker. *)

  val tType     : ?loc:location -> unit -> t
  (** The type of types, defined as specific token by the Zipperposition format;
      in other languages, will be represented as a constant (the "$tType" constant
      in tptp for instance). Used to define new types, or quantify type variables
      in languages that support polymorphism. *)

  val prop      : ?loc:location -> unit -> t
  (** The type of propositions. Also defined as a lexical token by the Zipperposition
      format. Will be defined as a constant in most other languages (for instance,
      "$o" in tptp). *)

  val bool   : ?loc:location -> unit -> t
  (** The type of boolean, defined as a specific token by the Alt-ergo format;
      in other languages, it might be represented as a constant with a specific name. *)

  val ty_unit   : ?loc:location -> unit -> t
  (** The type unit, defined as a specific token by the Alt-ergo format;
      in other languages, it might be represented as a constant with a specific name. *)

  val ty_int    : ?loc:location -> unit -> t
  (** The type of integers, defined as a specific token by the Zipperposition and Alt-ergo
      formats;
      in other languages, it might be represented as a constant with a specific name
      (for isntance, tptp's "$int") .*)

  val ty_real   : ?loc:location -> unit -> t
  (** The type of integers, defined as a specific token by the Alt-ergo format;
      in other languages, it might be represented as a constant with a specific name
      (for isntance, tptp's "$int") .*)

  val ty_bitv   : ?loc:location -> int -> t
  (** The type of bitvectors of the given constant length, defined as a specifi token
      by the Alt-ergo format;
      in other languages, it might be represented as a constant with a specific name
      (for isntance, smtlib(s "bitv") .*)

  val void      : ?loc:location -> unit -> t
  (** The only value of type unit, defined as a specific token by the Alt-ergo format. *)

  val true_     : ?loc:location -> unit -> t
  val false_    : ?loc:location -> unit -> t
  (** The constants for the true and false propositional constants. Again defined
      as lexical token in the Zipperposition format, while treated as a constant
      in other languages ("$true" in tptp). *)

  val not_t     : ?loc:location -> unit -> t
  val or_t      : ?loc:location -> unit -> t
  val and_t     : ?loc:location -> unit -> t
  val xor_t     : ?loc:location -> unit -> t
  val nor_t     : ?loc:location -> unit -> t
  val nand_t    : ?loc:location -> unit -> t
  val equiv_t   : ?loc:location -> unit -> t
  val implied_t : ?loc:location -> unit -> t
  val implies_t : ?loc:location -> unit -> t
  (** Standard logical connectives viewed as terms. [implies_t] is usual
      right implication, i.e [apply implies_t \[p; q\] ] is "p implies q",
      while [apply implied_t \[p; q \]] means "p is implied by q" or
      "q implies p". *)

  val data_t    : ?loc:location -> unit -> t
  (** Term without semantic meaning, used for creating "data" terms.
      Used in tptp's annotations, and with similar meaning as smtlib's
      s-expressions (as used in the [sexpr] function defined later). *)


  (** {3 Terms leaf constructors} *)

  val var      : ?loc:location -> id -> t
  val const    : ?loc:location -> id -> t
  (** Variable and constant constructors. While in some languages
      they can distinguished at the lexical level (in tptp for instance),
      in most languages, it is an issue dependant on scoping rules,
      so terms parsed from an smtlib file will have all variables
      parsed as constants. *)

  val atom     : ?loc:location -> int -> t
  (** Atoms are used for dimacs cnf parsing. Positive integers denotes variables,
      and negative integers denote the negation of the variable corresponding to
      their absolute value. *)

  val distinct : ?loc:location -> id -> t
  (** Used in tptp to specify constants different from other constants, for instance the
      'distinct' "Apple" should be syntactically different from the "Apple"
      constant. Can be safely aliased to the [const] function as the
      [distinct] function is always given strings already enclosed with quotes,
      so in the example above, [const] would be called with ["Apple"] as
      string argument, while [distinct] would be called with the string ["\"Apple\""] *)

  val int      : ?loc:location -> string -> t
  val rat      : ?loc:location -> string -> t
  val real     : ?loc:location -> string -> t
  val hexa     : ?loc:location -> string -> t
  val binary   : ?loc:location -> string -> t
  (** Constructors for words defined as numeric formats by the languages
      specifications. These also can be safely aliased to [const]. *)

  val bitv     : ?loc:location -> string -> t
  (** Bitvetor litteral, defined as a specific token in Alt-ergo;
      Expects a decimal integer in the string to be extended as a bitvector. *)

  (** {3 Term constructors} *)

  val colon : ?loc:location -> t -> t -> t
  (** Represents juxtaposition of two terms, usually denoted "t : t'"
      in most languages, and mainly used to annotated terms with their
      supposed, or defined, type. *)

  val eq    : ?loc:location -> t -> t -> t
  val neq   : ?loc:location -> t list -> t
  (** Equality and dis-equality of terms. *)

  val not_  : ?loc:location -> t -> t
  val or_   : ?loc:location -> t list -> t
  val and_  : ?loc:location -> t list -> t
  val xor   : ?loc:location -> t -> t -> t
  val imply : ?loc:location -> t -> t -> t
  val equiv : ?loc:location -> t -> t -> t
  (** Proposition construction functions. The conjunction and disjunction
      are n-ary instead of binary mostly because they are in smtlib (and
      that is subsumes the binary case). *)

  val apply : ?loc:location -> t -> t list -> t
  (** Application constructor, seen as higher order application
      rather than first-order application for the following reasons:
      being able to parse tptp's THF, having location attached
      to function symbols. *)

  val ite   : ?loc:location -> t -> t -> t -> t
  (** Conditional constructor, both for first-order terms and propositions.
      Used in the following schema: [ite condition then_branch else_branch]. *)

  val match_ : ?loc:location -> t -> (t * t) list -> t
  (** Pattern matching. The first term is the term to match,
      and each tuple in the list is a match case, which is a pair
      of a pattern and a match branch. *)

  val pi     : ?loc:location -> t list -> t -> t
  val letin  : ?loc:location -> t list -> t -> t
  val forall : ?loc:location -> t list -> t -> t
  val exists : ?loc:location -> t list -> t -> t
  val lambda : ?loc:location -> t list -> t -> t
  val choice : ?loc:location -> t list -> t -> t
  val description : ?loc:location -> t list -> t -> t
  (** Binders for variables. Takes a list of terms as first argument
      for simplicity, the lists will almost always be a list of variables,
      optionally typed using the [colon] term constructor.
      - Pi is the polymorphic type quantification, for instance
        the polymorphic identity function has type: "Pi alpha. alpha -> alpha"
      - Letin is local binding, takes a list of equality of equivalences
        whose left hand-side is a variable.
      - Forall is universal quantification
      - Exists is existential quantification
      - Lambda is used for function construction
      - Choice is the choice operator, also called indefinite description, or
        also epsilon terms, i.e "Choice x. p(x)" is one "x" such that "p(x)"
        is true.
      - Description is the definite description, i.e "Description x. p(x)"
        is the {b only} "x" that satisfies p.
  *)

  (** {3 Type constructors} *)

  val arrow   : ?loc:location -> t -> t -> t
  (** Function type constructor, for curryfied functions. Functions
      that takes multiple arguments in first-order terms might take
      a product as only argument (see the following [product] function)
      in some languages (e.g. tptp), or be curryfied using this constructor
      in other languages (e.g. alt-ergo). *)

  val product : ?loc:location -> t -> t -> t
  (** Product type constructor, used for instance in the types of
      functions that takes multiple arguments in a non-curry way. *)

  val union   : ?loc:location -> t -> t -> t
  (** Union type constructor, currently used in tptp's THF format. *)

  val subtype : ?loc:location -> t -> t -> t
  (** Subtype relation for types. *)

  (** {3 Record constructors} *)

  val record : ?loc:location -> t list -> t
  (** Create a record expression. *)

  val record_with : ?loc:location -> t -> t list -> t
  (** Record "with" update (e.g. "{ r with ....}"). *)

  val record_access : ?loc:location -> t -> id -> t
  (** Field record access. *)

  (** {3 Algebraic datatypes} *)

  val adt_check : ?loc:location -> t -> id -> t
  (** Check whether some expression matches a given adt constructor
      (in head position). *)

  val adt_project : ?loc:location -> t -> id -> t
  (** Project a field of an adt constructor (usually unsafe except when
      guarded by an adt_check function). *)


  (** {3 Array constructors} *)

  val array_get : ?loc:location -> t -> t -> t
  (** Array getter. *)

  val array_set : ?loc:location -> t -> t -> t -> t
  (** Array setter. *)

  (** {3 Bitvector constructors} *)

  val bitv_extract : ?loc:location -> t -> int -> int -> t
  (** Bitvector extraction. *)

  val bitv_concat : ?loc:location -> t -> t -> t
  (** Bitvector concatenation. *)

  (** {3 Arithmetic constructors} *)

  val uminus : ?loc:location -> t -> t
  (** Arithmetic unary minus. *)

  val add    : ?loc:location -> t -> t -> t
  (** Arithmetic addition. *)

  val sub    : ?loc:location -> t -> t -> t
  (** Arithmetic substraction. *)

  val mult   : ?loc:location -> t -> t -> t
  (** Arithmetic multiplication. *)

  val div    : ?loc:location -> t -> t -> t
  (** Arithmetic division quotient. *)

  val mod_   : ?loc:location -> t -> t -> t
  (** Arithmetic modulo (aka division reminder). *)

  val int_pow : ?loc:location -> t -> t -> t
  (** Integer power. *)

  val real_pow : ?loc:location -> t -> t -> t
  (** Real power. *)

  val lt     : ?loc:location -> t -> t -> t
  (** Arithmetic "lesser than" comparison (strict). *)

  val leq    : ?loc:location -> t -> t -> t
  (** Arithmetic "lesser or equal" comparison. *)

  val gt     : ?loc:location -> t -> t -> t
  (** Arithmetic "greater than" comparison (strict). *)

  val geq    : ?loc:location -> t -> t -> t
  (** Arithmetic "greater or equal" comparison. *)

  (** {3 Triggers} *)

  val in_interval : ?loc:location -> t -> (t * bool) -> (t * bool) -> t
  (** Create a predicate for whether a term is within the given bounds
      (each bound is represented by a term which is tis value and a boolean
      which specifies whether it is strict or not). *)

  val maps_to : ?loc:location -> id -> t -> t
  (** Id mapping (see alt-ergo). *)

  val trigger : ?loc:location -> t list -> t
  (** Create a multi-trigger (i.e. all terms in the lsit must match to
      trigger). *)

  val triggers : ?loc:location -> t -> t list -> t
  (** [triggers ~loc f l] annotates formula/term [f] with a list of triggers. *)

  val filters : ?loc:location -> t -> t list -> t
  (** [filters ~loc f l] annotates formula/term [f] with a list of filters. *)


  (** {3 Special constructions} *)

  val tracked : ?loc:location -> id -> t -> t
  (** Name a term for tracking purposes. *)

  val quoted  : ?loc:location -> string -> t
  (** Create an attribute from a quoted string (in Zf). *)

  val sequent : ?loc:location -> t list -> t list -> t
  (** Sequents as terms *)

  val check   : ?loc:location -> t -> t
  (** Check a term (see alt-ergo). *)

  val cut     : ?loc:location -> t -> t
  (** Create a cut (see alt-ergo). *)

  val annot   : ?loc:location -> t -> t list -> t
  (** Attach a list of attributes (also called annotations) to a term. Attributes
      have no logical meaning (they can be safely ignored), but may serve to give
      hints or meta-information. *)

  val sexpr   : ?loc:location -> t list -> t
  (** S-expressions (for smtlib attributes), should probably be related
      to the [data_t] term. *)

end


(** {2 Signature for Typechecked terms} *)

module type Tff = sig
  (** Signature required by terms for typing first-order
      polymorphic terms. *)

  type t
  (** The type of terms and term variables. *)

  type ty
  type ty_var
  type ty_const
  (** The representation of term types, type variables, and type constants. *)

  type 'a tag
  (** The type of tags used to annotate arbitrary terms. *)

  val ty : t -> ty
  (** Returns the type of a term. *)

  (** A module for variables that occur in terms. *)
  module Var : sig

    type t
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

  end

  (** A module for constant symbols that occur in terms. *)
  module Const : sig

    type t
    (** The type of constant symbols that can occur in terms *)

    val hash : t -> int
    (** A hash function for term constants, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on term constants. Should be compatible with the hash function. *)

    val arity : t -> int * int
    (** Returns the arity of a term constant. *)

    val mk : string -> ty_var list -> ty list -> ty -> t
    (** Create a polymorphic constant symbol. *)

    val tag : t -> 'a tag -> 'a -> unit
    (** Tag a constant. *)

  end

  (** A module for Algebraic datatype constructors. *)
  module Cstr : sig

    type t
    (** An algebraic type constructor. Note that such constructors are used to
        build terms, and not types, e.g. consider the following:
        [type 'a list = Nil | Cons of 'a * 'a t], then [Nil] and [Cons] are the
        constructors, while [list] would be a type constant of arity 1 used to
        name the type. *)

    val hash : t -> int
    (** A hash function for adt constructors, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on adt constructors. Should be compatible with the hash function. *)

    val arity : t -> int * int
    (** Returns the arity of a constructor. *)

  end

  module Field : sig

    type t
    (** A field of a record. *)

    val hash : t -> int
    (** A hash function for adt constructors, should be suitable to create hashtables. *)

    val equal : t -> t -> bool
    (** An equality function on adt constructors. Should be compatible with the hash function. *)

  end

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

  val define_record :
    ty_const -> ty_var list -> (string * ty) list -> Field.t list
  (** Define a (previously abstract) type to be a record type, with the given fields. *)

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

  val ensure : t -> ty -> t
  (** Ensure that a given term has the given type. *)

  val of_var : Var.t -> t
  (** Create a term from a variable *)

  val apply : Const.t -> ty list -> t list -> t
  (** Polymorphic application. *)

  val apply_cstr : Cstr.t -> ty list -> t list -> t
  (** Polymorphic application of a constructor. *)

  val apply_field : Field.t -> t -> t
  (** Apply a field to a record. *)

  val record : (Field.t * t) list -> t
  (** Create a record. *)

  val record_with : t -> (Field.t * t) list -> t
  (** Create an updated record *)

  val _true : t
  val _false : t
  (** Some usual formulas. *)

  val eq : t -> t -> t
  (** Build the equality of two terms. *)

  val distinct : t list -> t
  (** Distinct constraints on terms. *)

  val neg : t -> t
  (** Negation. *)

  val _and : t list -> t
  (** Conjunction of formulas *)

  val _or : t list -> t
  (** Disjunction of formulas *)

  val nand : t -> t -> t
  (** Not-and *)

  val nor : t -> t -> t
  (** Not-or *)

  val imply : t -> t -> t
  (** Implication *)

  val equiv : t -> t -> t
  (** Equivalence *)

  val xor : t -> t -> t
  (** Exclusive disjunction. *)

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

  val fv : t -> ty_var list * Var.t list
  (** Returns the list of free variables in the formula. *)

end

(** Minimum required to type ae's tff *)
module type Ae_Base = sig

  type t
  (** The type of terms *)

  val void : t
  (** The only value of type unit. *)

end


(** Minimum required to type ae's arith *)
module type Ae_Arith = sig

  type t
  (** The type of terms *)

  type ty
  (** The type of types. *)

  val ty : t -> ty
  (** Type of a term. *)

end

(** Minimum required to type tptp's tff *)
module type Tptp_Base = sig

  type t
  (** The type of terms *)

  val _true : t
  (** The smybol for [true] *)

  val _false : t
  (** The symbol for [false] *)

end

(** Common signature for tptp arithmetics *)
module type Tptp_Arith_Common = sig

  type t
  (** The type of terms *)

  val minus : t -> t
  (** Arithmetic unary minus/negation. *)

  val add : t -> t -> t
  (** Arithmetic addition. *)

  val sub : t -> t -> t
  (** Arithmetic substraction *)

  val mul : t -> t -> t
  (** Arithmetic multiplication *)

  val div_e : t -> t -> t
  (** Euclidian division quotient *)

  val div_t : t -> t -> t
  (** Truncation of the rational/real division. *)

  val div_f : t -> t -> t
  (** Floor of the ration/real division. *)

  val rem_e : t -> t -> t
  (** Euclidian division remainder *)

  val rem_t : t -> t -> t
  (** Remainder for the truncation of the rational/real division. *)

  val rem_f : t -> t -> t
  (** Remaidner for the floor of the ration/real division. *)

  val lt : t -> t -> t
  (** Arithmetic "less than" comparison. *)

  val le : t -> t -> t
  (** Arithmetic "less or equal" comparison. *)

  val gt : t -> t -> t
  (** Arithmetic "greater than" comparison. *)

  val ge : t -> t -> t
  (** Arithmetic "greater or equal" comparison. *)

  val floor : t -> t
  (** Floor function. *)

  val ceiling : t -> t
  (** Ceiling *)

  val truncate : t -> t
  (** Truncation. *)

  val round : t -> t
  (** Rounding to the nearest integer. *)

  val is_int : t -> t
  (** Integer testing *)

  val is_rat : t -> t
  (** Rationality testing. *)

  val to_int : t -> t
  (** Convesion to an integer. *)

  val to_rat : t -> t
  (** Conversion to a rational. *)

  val to_real : t -> t
  (** Conversion to a real. *)

end

(** Signature required by terms for typing tptp arithmetic. *)
module type Tptp_Arith = sig

  type t
  (** The type of terms. *)

  type ty
  (** The type of types. *)

  val ty : t -> ty
  (** Get the type of a term. *)

  val int : string -> t
  (** Integer literals *)

  val rat : string -> t
  (** Rational literals *)

  val real : string -> t
  (** Real literals *)

  module Int : sig
    include Tptp_Arith_Common with type t := t
  end

  module Rat : sig
    include Tptp_Arith_Common with type t := t

    val div : t -> t -> t
    (** Exact division on rationals. *)
  end

  module Real : sig
    include Tptp_Arith_Common with type t := t

    val div : t -> t -> t
    (** Exact division on reals. *)
  end

end

(** Minimum required to type smtlib's core theory. *)
module type Smtlib_Base = sig

  type t
  (** The type of terms. *)

  val eqs : t list -> t
  (** Create a chain of equalities. *)

end

(** Common signature for first-order arithmetic *)
module type Smtlib_Arith_Common = sig

  type t
  (** The type of terms *)

  val minus : t -> t
  (** Arithmetic unary minus/negation. *)

  val add : t -> t -> t
  (** Arithmetic addition. *)

  val sub : t -> t -> t
  (** Arithmetic substraction *)

  val mul : t -> t -> t
  (** Arithmetic multiplication *)

  val div : t -> t -> t
  (** Division. See Smtlib theory for a full description. *)

  val lt : t -> t -> t
  (** Arithmetic "less than" comparison. *)

  val le : t -> t -> t
  (** Arithmetic "less or equal" comparison. *)

  val gt : t -> t -> t
  (** Arithmetic "greater than" comparison. *)

  val ge : t -> t -> t
  (** Arithmetic "greater or equal" comparison. *)

end



(** Signature required by terms for typing smtlib int arithmetic. *)
module type Smtlib_Int = sig

  include Smtlib_Arith_Common

  val int : string -> t
  (** Build an integer constant. The integer is passed
          as a string, and not an [int], to avoid overflow caused
          by the limited precision of native intgers. *)

  val rem : t -> t -> t
  (** Integer remainder See Smtlib theory for a full description. *)

  val abs : t -> t
  (** Arithmetic absolute value. *)

  val divisible : string -> t -> t
  (** Arithmetic divisibility predicate. Indexed over
      constant integers (represented as strings, see {!int}). *)

end

(** Signature required by terms for typing smtlib real arithmetic. *)
module type Smtlib_Real = sig

  include Smtlib_Arith_Common

  val real : string -> t
  (** Build a real constant. The string should respect
      smtlib's syntax for INTEGER or DECIMAL. *)

end

(** Signature required by terms for typing smtlib real_int arithmetic. *)
module type Smtlib_Real_Int = sig

  type t
  (** The type of terms. *)

  type ty
  (** The type of types. *)

  val ty : t -> ty
  (** Get the type of a term. *)

  module Int : sig

    include Smtlib_Int with type t := t

    val to_real : t -> t
    (** Conversion from an integer term to a real term. *)

  end

  module Real : sig

    include Smtlib_Real with type t := t

    val is_int : t -> t
    (** Arithmetic predicate, true on reals that are also integers. *)

    val to_int : t -> t
    (** Partial function from real to integers. Only has defined semantics
            when {!is_int} is true. *)

  end

end

module type Smtlib_Array = sig

  type t
  (** The type of terms *)

  val select : t -> t -> t
  (** [select arr idx] creates the get operation on functionnal
        array [arr] for index [idx]. *)

  val store : t -> t -> t -> t
  (** [store arr idx value] creates the set operation on
      functional array [arr] for value [value] at index [idx]. *)

end

module type Smtlib_Bitv = sig

  type t
  (** The type of terms *)

  val mk_bitv : string -> t
  (** Create a bitvector litteral from a string representation.
        The string should only contain characters '0' or '1'. *)

  val bitv_concat : t -> t -> t
  (** Bitvector concatenation. *)

  val bitv_extract : int -> int -> t -> t
  (** Bitvector extraction, using in that order,
      the end (exclusive) and then the start (inclusive)
      position of the bitvector to extract. *)

  val bitv_repeat : int -> t -> t
  (** Repetition of a bitvector. *)

  val zero_extend : int -> t -> t
  (** Extend the given bitvector with the given numer of 0. *)

  val sign_extend : int -> t -> t
  (** Extend the given bitvector with its most significant bit
      repeated the given number of times. *)

  val rotate_right : int -> t -> t
  (** [rotate_right i x] means rotate bits of x to the right i times. *)

  val rotate_left : int -> t -> t
  (** [rotate_left i x] means rotate bits of x to the left i times. *)

  val bvnot : t -> t
  (** Bitwise negation. *)

  val bvand : t -> t -> t
  (** Bitwise conjunction. *)

  val bvor : t -> t -> t
  (** Bitwise disjunction. *)

  val bvnand : t -> t -> t
  (** [bvnand s t] abbreviates [bvnot (bvand s t)]. *)

  val bvnor : t -> t -> t
  (** [bvnor s t] abbreviates [bvnot (bvor s t)]. *)

  val bvxor : t -> t -> t
  (** [bvxor s t] abbreviates [bvor (bvand s (bvnot t)) (bvand (bvnot s) t)]. *)

  val bvxnor : t -> t -> t
  (** [bvxnor s t] abbreviates [bvor (bvand s t) (bvand (bvnot s) (bvnot t))]. *)

  val bvcomp : t -> t -> t
  (** Bitwise comparison. [bvcomp s t] equald [#b1] iff [s] and [t]
      are bitwise equal. *)


  val bvneg : t -> t
  (** Arithmetic complement on bitvectors.
      Supposing an input bitvector of size [m] representing
      an integer [k], the resulting term should represent
      the integer [2^m - k]. *)

  val bvadd : t -> t -> t
  (** Arithmetic addition on bitvectors, modulo the size of
      the bitvectors (overflows wrap around [2^m] where [m]
      is the size of the two input bitvectors). *)

  val bvsub : t -> t -> t
  (** Arithmetic substraction on bitvectors, modulo the size
      of the bitvectors (2's complement subtraction modulo).
      [bvsub s t] should be equal to [bvadd s (bvneg t)]. *)

  val bvmul : t -> t -> t
  (** Arithmetic multiplication on bitvectors, modulo the size
      of the bitvectors (see {!bvadd}). *)

  val bvudiv : t -> t -> t
  (** Arithmetic euclidian integer division on bitvectors. *)

  val bvurem : t -> t -> t
  (** Arithmetic euclidian integer remainder on bitvectors. *)

  val bvsdiv : t -> t -> t
  (** Arithmetic 2's complement signed division.
      (see smtlib's specification for more information). *)

  val bvsrem : t -> t -> t
  (** Arithmetic 2's coplement signed remainder (sign follows dividend).
      (see smtlib's specification for more information). *)

  val bvsmod : t -> t -> t
  (** Arithmetic 2's coplement signed remainder (sign follows divisor).
      (see smtlib's specification for more information). *)

  val bvshl : t -> t -> t
  (** Logical shift left. [bvshl t k] return the result of
      shifting [t] to the left [k] times. In other words,
      this should return the bitvector representing
      [t * 2^k] (since bitvectors represent integers using
      the least significatn bit in cell 0). *)

  val bvlshr : t -> t -> t
  (** Logical shift right. [bvlshr t k] return the result of
      shifting [t] to the right [k] times. In other words,
      this should return the bitvector representing
      [t / (2^k)]. *)

  val bvashr : t -> t -> t
  (** Arithmetic shift right, like logical shift right except that the most
      significant bits of the result always copy the most significant
      bit of the first argument*)

  val bvult : t -> t -> t
  (** Boolean arithmetic comparison (less than).
      [bvult s t] should return the [true] term iff [s < t]. *)

  val bvule : t -> t -> t
  (** Boolean arithmetic comparison (less or equal than). *)

  val bvugt : t -> t -> t
  (** Boolean arithmetic comparison (greater than). *)

  val bvuge : t -> t -> t
  (** Boolean arithmetic comparison (greater or equal than). *)

  val bvslt : t -> t -> t
  (** Boolean signed arithmetic comparison (less than).
      (See smtlib's specification for more information) *)

  val bvsle : t -> t -> t
  (** Boolean signed arithmetic comparison (less or equal than). *)

  val bvsgt : t -> t -> t
  (** Boolean signed arithmetic comparison (greater than). *)

  val bvsge : t -> t -> t
  (** Boolean signed arithmetic comparison (greater or equal than). *)
end
