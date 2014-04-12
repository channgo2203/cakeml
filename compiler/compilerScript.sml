(*Generated by Lem from compiler.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory semanticPrimitivesTheory astTheory compilerLibTheory intLangTheory toIntLangTheory toBytecodeTheory bytecodeTheory modLangTheory conLangTheory decLangTheory exhLangTheory patLangTheory;

val _ = numLib.prefer_num();



val _ = new_theory "compiler"

(*open import Pervasives*)
(*open import SemanticPrimitives*)
(*open import Ast*)
(*open import CompilerLib*)
(*open import IntLang*)
(*open import ToIntLang*)
(*open import ToBytecode*)
(*open import Bytecode*)
(*open String_extra*)
(*open import ModLang*)
(*open import ConLang*)
(*open import DecLang*)
(*open import ExhLang*)
(*open import PatLang*)

val _ = Hol_datatype `
 compiler_state =
  <| next_global : num
   ; globals_env : (modN, ( (varN, num)fmap)) fmap # (varN, num) fmap
   ; contags_env : num # tag_env # (num, (conN # tid_or_exn)) fmap
   ; rnext_label : num
   |>`;


val _ = Define `
 (init_compiler_state =  
(<| next_global :=( 0)
   ; globals_env := (FEMPTY, FEMPTY)
   ; contags_env := init_tagenv_state
   ; rnext_label :=( 0)
   |>))`;


val _ = Define `
 (compile_Cexp env rsz cs Ce =  
(let (Ce,nl) = (label_closures (LENGTH env) cs.next_label Ce) in
  let cs = (compile_code_env ( cs with<| next_label := nl |>) Ce) in
  compile env TCNonTail rsz cs Ce))`;


val _ = Define `
 (tystr types v =  
((case FLOOKUP types v of
      SOME t => t
    | NONE => "<unknown>"
  )))`;


 val compile_print_vals_defn = Hol_defn "compile_print_vals" `

(compile_print_vals _ _ [] s = s)
/\
(compile_print_vals types n (v::vs) s =  
(let s = (emit s (MAP PrintC (EXPLODE (CONCAT ["val ";v;":"; tystr types v;" = "])))) in
  let s = (emit s [Stack(Load n); Print]) in
  let s = (emit s (MAP PrintC (EXPLODE "\n"))) in
    compile_print_vals types (n+ 1) vs s))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn compile_print_vals_defn;

 val _ = Define `

(compile_print_ctors [] s = s)
/\
(compile_print_ctors ((c,_)::cs) s =  
(compile_print_ctors cs
    (emit s (MAP PrintC (EXPLODE (CONCAT [c;" = <constructor>\n"]))))))`;


 val _ = Define `

(compile_print_types [] s = s)
/\
(compile_print_types ((_,_,cs)::ts) s =  
(compile_print_types ts (compile_print_ctors cs s)))`;


 val _ = Define `

(compile_print_dec _ (Dtype ts) s = (compile_print_types ts s))
/\
(compile_print_dec _ (Dexn c xs) s = (compile_print_types [(([]: tvarN list),"exn",[(c,xs)])] s))
/\
(compile_print_dec types (Dlet p _) s =  
(compile_print_vals types( 0) (pat_bindings p []) s))
/\
(compile_print_dec types (Dletrec defs) s =  
(compile_print_vals types( 0) (MAP (\p .  
  (case (p ) of ( (n,_,_) ) => n )) defs) s))`;


 val _ = Define `

(compile_print_top _ (Tmod mn _ _) cs =  
(let str = (CONCAT["structure ";mn;" = <structure>\n"]) in
  emit cs (MAP PrintC (EXPLODE str))))
/\
(compile_print_top types (Tdec dec) cs =  
(compile_print_dec types dec cs))`;


val _ = Define `
 (compile_top types cs top =  
(let (m1,m2) = (cs.globals_env) in
  let (n,m1,m2,p) = (top_to_i1 cs.next_global m1 m2 top) in
  let (c,p) = (prompt_to_i2 cs.contags_env p) in
  let (n,e) = (prompt_to_i3 (none_tag, SOME (TypeId (Short "option"))) (some_tag, SOME (TypeId (Short "option"))) n p) in
  let e = (exp_to_exh (* TODO: fix: *) FEMPTY e) in
  let e = (exp_to_pat [] e) in
  let e = (exp_to_Cexp e) in
  let r = (compile_Cexp []( 0) <| out := []; next_label := cs.rnext_label |> e) in
  let r = (compile_print_top types top r) in
  let cs = (<| next_global := n
            ; globals_env := (m1,m2)
            ; contags_env := c
            ; rnext_label := r.next_label
            |>) in
  (cs, r.out)))`;

val _ = export_theory()

