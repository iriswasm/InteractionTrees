Set Implicit Arguments.
Set Contextual Implicit.


From Coq Require Import
     String List.
Import ListNotations.

From ExtLib.Structures Require Import
     Monoid.

From ITree Require Import
     ITree.


(* An event that spawns a unit-producing thread with effects in E.   *)
Inductive spawnE E : Type -> Type :=
| Spawn : forall (t: itree E unit), spawnE E unit.


(* A simple round-robin scheduler:

   This scheduler runs a queue of threads that contain Spawn events.  Each such
   spawned child threads cannot themselves Spwan events (at least not ones
   handled by this scheduler).  Each thread may terminate by returning [tt].  If
   all children threads _and_ the parent thread return, then execution
   terminates, yielding [tt].  If any of the threads diverge, the whole
   scheduled pool diverges.

   With this implementation, the threads could communicate via a shared memory
   via their effects [E], but there are no real synchronization primitives that
   could be used to prevent races.  *)
Definition rr_match {E} (rr : list (itree ((spawnE E) +' E) unit) -> itree E unit)
           (q:list (itree ((spawnE E) +' E) unit)) : itree E unit
  :=
    match q with
    | [] => Ret tt
    | t::ts =>
      match t.(observe) with
      | RetF _ => Tau (rr ts)
      | TauF u => Tau (rr (ts ++ [u]))
      | @VisF _ _ _ X o k =>
        match o with
        | inl1 s =>
          match s in spawnE _ Y return X = Y -> itree E unit with
          | (Spawn u) => fun pf => Tau (rr (ts
                                    ++ [translate (@inr1 (spawnE E) E) _ u]
                                    ++ [k (eq_rect_r (fun T => T) tt pf)]))
          end eq_refl
        | inr1 o => Vis o (fun x => rr (ts ++ [k x]))
        end
      end
    end.

CoFixpoint round_robin {E} (q:list (itree ((spawnE E) +' E) unit)) : itree E unit :=
  rr_match round_robin q.

Definition run_spawn {E} (t : itree ((spawnE E) +' E) unit) : itree E unit :=
  round_robin [t].
