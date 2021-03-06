open HolKernel Parse boolLib bossLib;
open preamble;
open lexer_funTheory lexer_implTheory;
open ml_translatorLib ml_translatorTheory;
open std_preludeTheory;

val _ = new_theory "lexerProg"

val _ = translation_extends "std_prelude";

val RW = REWRITE_RULE
val RW1 = ONCE_REWRITE_RULE
fun list_dest f tm =
  let val (x,y) = f tm in list_dest f x @ list_dest f y end
  handle HOL_ERR _ => [tm];
val dest_fun_type = dom_rng
val mk_fun_type = curry op -->;
fun list_mk_fun_type [ty] = ty
  | list_mk_fun_type (ty1::tys) =
      mk_fun_type ty1 (list_mk_fun_type tys)
  | list_mk_fun_type _ = fail()

val _ = add_preferred_thy "-";
val _ = add_preferred_thy "termination";

val NOT_NIL_AND_LEMMA = store_thm("NOT_NIL_AND_LEMMA",
  ``(b <> [] /\ x) = if b = [] then F else x``,
  Cases_on `b` THEN FULL_SIMP_TAC std_ss []);

val extra_preprocessing = ref [MEMBER_INTRO,MAP];

fun def_of_const tm = let
  val res = dest_thy_const tm handle HOL_ERR _ =>
              failwith ("Unable to translate: " ^ term_to_string tm)
  val name = (#Name res)
  fun def_from_thy thy name =
    DB.fetch thy (name ^ "_def") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_DEF") handle HOL_ERR _ =>
    DB.fetch thy name
  val def = def_from_thy "termination" name handle HOL_ERR _ =>
            def_from_thy (#Thy res) name handle HOL_ERR _ =>
            failwith ("Unable to find definition of " ^ name)
  val def = def |> RW (!extra_preprocessing)
                |> CONV_RULE (DEPTH_CONV BETA_CONV)
                |> SIMP_RULE bool_ss [IN_INSERT,NOT_IN_EMPTY]
                |> REWRITE_RULE [NOT_NIL_AND_LEMMA]
  in def end

val _ = (find_def_for_const := def_of_const);

val _ = translate get_token_eqn

val _ = translate (next_token_def |> SIMP_RULE std_ss [next_sym_eq])

val _ = translate lexer_fun_def

val l2n_side = prove(``
  ∀b a. a ≠ 0 ⇒ l2n_side a b``,
  Induct>>
  rw[Once (fetch"-""l2n_side_def")])

val num_from_dec_string_alt_side = prove(``
  ∀x. num_from_dec_string_alt_side x ⇔ T``,
  simp[Once (fetch"-""num_from_dec_string_alt_side_def")]>>
  strip_tac>>CONJ_TAC
  >-
    simp[Once (fetch"-""s2n_side_def"),l2n_side]
  >>
    simp[Once (fetch"-""unhex_alt_side_def"),Once (fetch"-""unhex_side_def"),isDigit_def]>>Cases>>
    strip_tac>>
    `48 ≤ n ∧ n ≤ 57` by
      fs[ORD_CHR]>>
    `n = 48 ∨ n = 49 ∨ n = 50 ∨
     n = 51 ∨ n = 52 ∨ n = 53 ∨
     n = 54 ∨ n = 55 ∨ n = 56 ∨ n = 57` by
       DECIDE_TAC>>
    fs[]);

val read_string_side = prove(``
  ∀x y.
  read_string_side x y ⇔ T``,
  ho_match_mp_tac read_string_ind>>
  rw[]>>
  simp[Once (fetch"-""read_string_side_def")]);

val next_sym_alt_side = prove(``
  ∀x. next_sym_alt_side x ⇔ T``,
  ho_match_mp_tac next_sym_alt_ind>>rw[]>>
  simp[Once (fetch"-""next_sym_alt_side_def"),num_from_dec_string_alt_side,read_string_side]>>
  rw[]>>metis_tac[]);

val lexer_fun_side = prove(``
  ∀x. lexer_fun_side x ⇔ T``,
  ho_match_mp_tac lexer_fun_ind>>rw[]>>
  simp[Once (fetch"-""lexer_fun_side_def"),
       Once (fetch"-""next_token_side_def"),next_sym_alt_side]) |> update_precondition

val () = Feedback.set_trace "TheoryPP.include_docs" 0

val _ = export_theory();
