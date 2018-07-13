
(* This file is free software, part of dolmen. See file "LICENSE" for more information *)

(** External Typechecker interface

    This module defines the external typechcker interface, that is,
    the interface of an instantiated typechecker. *)

(** Typechecker interface *)
module type S = sig

  (** {2 Module aliases} *)
  module Tag: Dolmen_intf.Tag.S
  module Ty: Dolmen_intf.Type.Tff
    with type 'a tag := 'a Tag.t
  module T: Dolmen_intf.Term.Tff
    with type ty := Ty.t
     and type ty_var := Ty.Var.t
     and type 'a tag := 'a Tag.t

  (** {2 Type definitions} *)

  type env
  (** The type of environments for typechecking. *)

  type expect =
    | Nothing
    | Type
    | Typed of Ty.t
    (** The type of expected result when typing an expression, used to infer
        non-declared symbols. *)

  type tag = Any : 'a Tag.t * 'a -> tag
  (** Existencial wrapper around tags *)

  type res =
    | Ttype   : res
    | Ty      : Ty.t -> res
    | Term    : T.t -> res
    | Tags    : tag list -> res (**)
  (** The results of parsing an untyped term.  *)

  type inferred =
    | Ty_fun of Ty.Const.t
    | Term_fun of T.Const.t
    (** The type for inferred symbols. *)

  type err = ..

  type err +=
    | Infer_type_variable
    | Expected of string * res option
    | Bad_op_arity of string * int * int
    | Bad_id_arity of Dolmen.Id.t * int
    | Bad_ty_arity of Ty.Const.t * int
    | Bad_term_arity of T.Const.t * int * int
    | Var_application of T.Var.t
    | Ty_var_application of Ty.Var.t
    | Type_mismatch of T.t * Ty.t
    | Quantified_var_inference
    | Unhandled_builtin of Dolmen.Term.builtin
    | Cannot_tag_tag
    | Cannot_tag_ttype
    | Cannot_find of Dolmen.Id.t
    | Type_var_in_type_constructor
    | Unhandled_ast (**)
  (** The list of potential errors that can arise during typechecking. *)

  exception Typing_error of err * env * Dolmen.Term.t
  (** Exception raised when a typing error is encountered. *)

  type 'a typer = env -> Dolmen.Term.t -> 'a
  (** A general type for typers. Takes a local environment and the current untyped term,
      and return a value. The typer may need additional information for parsing,
      in which case the return value will be a function.
      @raise Typing_error *)

  type symbol =
    | Id of Dolmen.Id.t
    | Builtin of Dolmen.Term.builtin
    (** Wrapper around potential function symbols from the Dolmen AST. *)

  type builtin_symbols = (symbol -> Dolmen.Term.t list -> res option) typer
  (** The type of a typer for builtin symbols. Takes the name of the symbol and the arguments
      applied to it, and can return a typechecking result.
      Can be useful for extensions to define overloaded operators such as addition in arithmetic,
      since the exact function symbol returned can depend on the arguments (or even be different
      between two calls with the same arguments). *)

  (** {2 Environments} *)

  val empty_env :
    ?expect:expect ->
    ?infer_hook:(env -> inferred -> unit) ->
    ?infer_base:Ty.t ->
    builtin_symbols -> env
  (** Create a new environment. *)

  val expect : ?force:bool -> env -> expect -> env
  (** Returns the same environment but with the given expectation,
      except if the environnement already except [Nothing]. *)

  val find_var :
    env -> Dolmen.Id.t ->
    [ `Not_found
    | `Ty of Ty.Var.t
    | `Term of T.Var.t ]
  (** Lookup a variable in an environment. *)

  (** {2 Parsing helpers} *)

  val ty_apply :
    (Ty.Const.t -> Ty.t list -> Ty.t) typer
  val term_apply :
    (T.Const.t -> Ty.t list -> T.t list -> T.t) typer
  (** Wrappers for making applications, so that it raises the right exceptions. *)

  (** {2 Parsing functions} *)

  val parse_expr : res typer
  (** Main parsing function. *)

  val parse_ty : Ty.t typer
  val parse_term : T.t typer
  (** Wrappers around {parse_expr} to unwrap an expected result. *)

  val parse_app_ty : (Ty.Const.t -> Dolmen.Term.t list -> res) typer
  val parse_app_term : (T.Const.t -> Dolmen.Term.t list -> res) typer
  (** Function used for parsing applications. The first dolmen term given
      is the application term being parsed (used for reporting errors). *)

  (** {2 High-level functions} *)

  val new_decl :
    (?attr:Dolmen.Term.t -> Dolmen.Id.t ->
     [ `Type_decl of Ty.Const.t
     | `Term_decl of T.Const.t
     ]) typer
  (** Parse a declaration. *)

  val new_def :
    (?attr:Dolmen.Term.t -> Dolmen.Id.t ->
     [ `Type_def of Dolmen.Id.t * tag list * Ty.Var.t list * Ty.t
     | `Term_def of Dolmen.Id.t * tag list * Ty.Var.t list * T.Var.t list * T.t
     ]) typer
  (** Parse a definition *)

  val parse : T.t typer
  (** Parse a formula *)

end

