Set Automatic Introduction.

Require CatStuff UniversalAlgebra Plus.
Require Import Structures RingOps BoringInstances Morphisms AbstractNaturals SemiRingAlgebra.
Import UniversalAlgebra.notations.

Close Scope nat_scope.

Instance f: NaturalsToSemiRing nat :=
  fun _ _ _ _ _ => fix f (n: nat) := match n with 0%nat => 0 | S n' => f n' + 1 end.

Module for_another_semiring.
Section contents.

  Context `{SemiRing R}.

  Add Ring R: (SemiRing_semi_ring_theory R).

  Instance f_proper: Proper (equiv ==> equiv) (naturals_to_semiring nat R).
  Proof. unfold equiv, nat_equiv. repeat intro. subst. reflexivity. Qed.

  Let f_preserves_0: naturals_to_semiring nat R 0 == 0.
   reflexivity.
  Qed.

  Let f_preserves_1: naturals_to_semiring nat R 1 == 1.
  Proof. unfold naturals_to_semiring. simpl. ring. Qed.

  Let f_preserves_plus a a': naturals_to_semiring nat R (a + a') == naturals_to_semiring nat R a + naturals_to_semiring nat R a'.
  Proof with try ring.
   induction a.
    change (naturals_to_semiring nat R (0 + a') == naturals_to_semiring nat R 0 + naturals_to_semiring nat R a').
    unfold naturals_to_semiring in *.
    rewrite plus_0_l.
    simpl.
    rewrite plus_0_l.
    reflexivity.
    (* this is awful, due to a Coq bug i've already reported on irc *)
   unfold naturals_to_semiring in *.
   simpl.
   rewrite IHa...
  Qed.

  Let f_preserves_mult a a': naturals_to_semiring nat R (a * a') == naturals_to_semiring nat R a * naturals_to_semiring nat R a'.
  Proof with try ring.
   unfold naturals_to_semiring.
   induction a. simpl...
   simpl.
   unfold ring_mult.
   simpl.
   rewrite f_preserves_plus.
   unfold naturals_to_semiring.
   change (f R mult0 plus0 one zero a' + f R mult0 plus0 one zero (a * a') ==
      (f R mult0 plus0 one zero a + 1) * (f R mult0 plus0 one zero a')).
   rewrite IHa...
  Qed.

  Instance f_mor: SemiRing_Morphism (naturals_to_semiring nat R).
   repeat (constructor; try apply _).
      apply f_preserves_plus.
     apply f_preserves_0.
    apply f_preserves_mult.
   apply f_preserves_1.
  Qed.

End contents.
End for_another_semiring.

Global Instance nat_Naturals: Naturals nat.
 apply (@Build_Naturals nat _ _ _ _ _ _ _ (@for_another_semiring.f_mor)).
 unfold CatStuff.proves_initial.
 destruct f'.
 simpl.
 intro.
 simpl.
 intro.
 destruct b.
 simpl in *.
 pose proof (semiring.from_object y).
 pose proof (@semiring.morphism_from_ua nat _ y _ semiring.impl_from_instance _ x _ _).
 pose proof (H0 H tt).
 induction a.
  unfold naturals_to_semiring.
  simpl.
  rewrite (@preserves_0 nat (y tt) _ _ _ _ _ _ _ _ _ _ (x tt) H1).
  reflexivity.
 unfold naturals_to_semiring.
 simpl.
 rewrite IHa.
 change (x tt a + 1 == x tt (1 + a)).
 rewrite (@preserves_plus nat (y tt) _ _ _ _ _ _ _ _ _ _ (x tt) H1).
 rewrite (@preserves_1 nat (y tt) _ _ _ _ _ _ _ _ _ _ (x tt) H1).
 rewrite commutativity.
 reflexivity.
Qed.

Lemma predefined_le_coincides (x y: nat): (x <= y)%nat -> x <= y.
 intros H.
 induction H.
  exists 0.
  apply plus_0_r.
 destruct IHle.
 exists (S x0).
 rewrite <- H0.
 change (x + (1 + x0) == 1 + (x + x0)).
 ring.
Qed.

Lemma predefined_le_coincides_rev (x y: nat): x <= y -> (x <= y)%nat.
 intros [z H].
 unfold equiv, nat_equiv in H.
 subst.
 auto with arith.
Qed.

Program Instance: forall x y: nat, Decision (x <= y) :=
  match Compare_dec.le_lt_dec x y with
  | left E => left (predefined_le_coincides _ _ E)
  | right E => right _
  end.

Next Obligation.
 apply (Lt.lt_not_le y x). assumption.
 apply predefined_le_coincides_rev. assumption.
Qed. 

Instance: TotalOrder natural_precedes.
Proof.
 intros x y. destruct (Compare_dec.le_lt_dec x y); [left | right];
  apply predefined_le_coincides; auto with arith.
Qed.

Instance naturals_total_order `{Naturals N}: TotalOrder natural_precedes.
Proof.
 intros x y. 
 destruct (total_order (naturals_to_semiring N nat x) (naturals_to_semiring N nat y)); [left | right];
  rewrite <- preserves_naturals_order in H1; try apply _; assumption. 
Qed.

Lemma Mult_mult_reg_l: forall n m p: nat, ~ p = 0 -> mult p n = mult p m -> n = m.
Proof. (* simple omission in the stdlib *)
 destruct p. intuition.
 intros. apply Le.le_antisym; apply Mult.mult_S_le_reg_l with p; rewrite H0; constructor.
Qed.

Lemma Mult_nz_mult_nz (x y: nat): ~ y == 0 -> ~ x == 0 -> ~ y * x == 0.
Proof.
 intros A B C.
 destruct (Mult.mult_is_O y x C); intuition.
Qed.
 
Lemma Naturals_ordinary_ind `{Naturals N}
  (P: N -> Prop) `{!Proper (equiv ==> iff)%signature P}:
  P 0 -> (forall n, P n -> P (1 + n)) -> forall n, P n.
Proof with auto.
 intros.
 rewrite <- (iso_nats N nat n).
 pose proof (naturals_to_semiring_mor nat N).
 induction (naturals_to_semiring N nat n).
  change (P (naturals_to_semiring nat N (0:nat))).
  rewrite preserves_0...
 change (P (naturals_to_semiring nat N (1 + n0))).
 rewrite preserves_plus, preserves_1...
Qed.

Section borrowed_from_nat.

  Context `{Naturals A} (x y z: A).

  Let three_vars (_: unit) v := match v with 0%nat => x | 1%nat => y | _ => z end.
  Let two_vars (_: unit) v := match v with 0%nat => x | _ => y end.
  Let no_vars (_: unit) (v: nat) := 0.
  Let d := semiring.impl_from_instance.

  Lemma from_nat_stmt (s: UA.Statement semiring.sig) (w: UA.Vars semiring.sig _):
    (forall v : unit -> nat -> nat, @UniversalAlgebra.eval_stmt semiring.sig (fun _ => nat) (fun _ => equiv) semiring.impl_from_instance v s) ->
    (@UniversalAlgebra.eval_stmt semiring.sig (fun _ => A) (fun _ => equiv) semiring.impl_from_instance w s).
  Proof.
   pose proof (@naturals_initial A _ _ _ _ _ _ _).
   pose proof (@naturals_initial nat _ _ _ _ _ _ _).
   destruct (@CatStuff.initials_unique' semiring.Object semiring.Arrow _ _ _ _ _ (semiring.as_object A) (semiring.as_object nat) _ _ H1 H2).
   pose proof (H3 tt). simpl in H5.
   pose proof (H4 tt). simpl in H6.
   clear H1 H2.
   intros.
   apply (@UA.carry_stmt semiring.sig (fun _ => nat) (fun _ => A) (fun _ => equiv) (fun _ => equiv) _ _ semiring.impl_from_instance semiring.impl_from_instance) with (fun u => match u with tt => naturals_to_semiring nat A end) (fun u => match u with tt => naturals_to_semiring A nat end); auto.
      apply _.
     apply _.
    set (naturals_to_semiring_arrow nat (semiring.as_object A)).
    apply (proj2_sig a).
   set (naturals_to_semiring_arrow A (semiring.as_object nat)).
   apply (proj2_sig a).
  Qed.

  Local Notation x' := (UA.Var semiring.sig 0 tt).
  Local Notation y' := (UA.Var semiring.sig 1 tt).
  Local Notation z' := (UA.Var semiring.sig 2%nat tt).

  (* Some clever autoquoting tactic might make what follows even more automatic. *)
  (* The ugly [pose proof ... . apply that_thing.]'s are because of Coq bug 2185. *)

  Global Instance: forall x: A, Injective (ring_plus x).
  Proof.
   intros u v w.
   pose proof (from_nat_stmt (x' + y' === x' + z' -=> y' === z')
     (fun _ d => match d with 0%nat => u | 1%nat => v | _ => w end)) as P.
   apply P. intro. simpl. apply Plus.plus_reg_l.
  Qed.

  Global Instance naturals_mult_injective: forall x: A, ~ x == 0 -> Injective (ring_mult x).
  Proof.
   intros u E v w.
   pose proof (from_nat_stmt ((x' === 0 -=> UA.Ext _ False) -=> x' * y' === x' * z' -=> y' === z')
    (fun _ d => match d with 0%nat => u | 1%nat => v | _ => w end)) as P.
   apply P. intro. simpl. apply Mult_mult_reg_l. assumption.
  Qed.

  Global Instance: ZeroNeOne A.
  Proof.
   pose proof (from_nat_stmt (0 === 1 -=> UA.Ext _ False) no_vars).
   apply H1. discriminate.
  Qed.

  Lemma naturals_zero_sum: x + y == 0 -> x == 0 /\ y == 0.
  Proof.
   pose proof (from_nat_stmt (x' + y' === 0 -=> UA.Conj _ (x' === 0) (y' === 0)) two_vars).
   apply H1. intro. simpl. apply Plus.plus_is_O.
  Qed.

  Lemma naturals_nz_mult_nz: ~ y == 0 -> ~ x == 0 -> ~ y * x == 0.
  Proof.
   pose proof (from_nat_stmt ((y' === 0 -=> UA.Ext _ False) -=>
     (x' === 0 -=> UA.Ext _ False) -=> (y' * x' === 0 -=> UA.Ext _ False)) two_vars).
   unfold not. apply H1. intro. simpl. apply Mult_nz_mult_nz.
  Qed.

End borrowed_from_nat.

Program Instance: NatDistance nat := fun (x y: nat) =>
  if decide (natural_precedes x y) then minus y x else minus x y.

Next Obligation.
 destruct H.
 unfold equiv, nat_equiv.
 subst. 
 left. 
 rewrite <- H.
 rewrite Minus.minus_plus.
 reflexivity.
Qed.

Next Obligation.
 destruct (total_order x y).
  intuition.
 right.
 change ((y + (x - y))%nat == x).
 rewrite (Minus.le_plus_minus_r y x).
  reflexivity.
 apply predefined_le_coincides_rev.
 assumption.
Qed.