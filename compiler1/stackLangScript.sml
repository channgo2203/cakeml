open preamble wordLangTheory;

val _ = new_theory "stackLang";

val _ = Datatype `
  prog = Skip
       | Inst ('a inst)
       | Get num store_name
       | Set store_name num
       | Call ((stackLang$prog # num # num) option)
              (* return var, return-handler code, labels l1,l2*)
              (num + num) (* target of call *)
              ((stackLang$prog # num # num) option)
              (* handler: exception-handler code, labels l1,l2*)
       | Seq stackLang$prog stackLang$prog
       | If cmp num ('a reg_imm) stackLang$prog stackLang$prog
       | Alloc num
       | Raise num
       | Return num num
       | Tick
       (* new in stackLang, compared to wordLang, below *)
       | StackAlloc num
       | StackFree num
       | StackStore num num     (* offset, fast *)
       | StackStoreAny num num  (* reg contains offset, slow, used by GC *)
       | StackLoad num num      (* offset, fast *)
       | StackLoadAny num num   (* reg contains offset, slow, used by GC *)
       | StackGetSize           (* used when installing exc handler *)
       | StackSetSize           (* used by implementation of raise *)`;

val _ = export_theory();
